#!/usr/bin/env node
/**
 * VeggiePal Self-Hosted AI Quality Evaluation & Metrics Library
 * Evaluates Chatbot, Meal Planning, Recommendations, and Moderation outputs,
 * and computes statistical performance metrics (mean, median, P95, max) and
 * multi-class classification metrics (accuracy, precision, recall, F1, macro F1,
 * confusion matrix, unsafe approval rate).
 */

export const MODERATION_CLASSES = ["APPROVED", "REJECTED", "REVIEW_REQUIRED"];

const ANIMAL_PRODUCTS = [
  "thịt bò", "thịt heo", "thịt lợn", "thịt gà", "thịt vịt", "cá hồi", "cá ngừ",
  "tôm tươi", "mực tươi", "nước mắm cá", "mỡ heo", "xương ống", "trứng gà",
  "trứng vịt", "sữa bò tươi", "mật ong rừng", "gelatin động vật"
];

/**
 * Compute summary latency statistics from an array of numeric values.
 */
export function computeLatencyStats(values) {
  const valid = values.filter((v) => typeof v === "number" && !Number.isNaN(v) && v >= 0).sort((a, b) => a - b);
  if (valid.length === 0) {
    return { count: 0, mean: 0, median: 0, p95: 0, min: 0, max: 0 };
  }
  const sum = valid.reduce((acc, v) => acc + v, 0);
  const mean = sum / valid.length;
  const mid = Math.floor(valid.length / 2);
  const median = valid.length % 2 !== 0 ? valid[mid] : (valid[mid - 1] + valid[mid]) / 2;
  const p95Index = Math.min(valid.length - 1, Math.ceil(valid.length * 0.95) - 1);
  const p95 = valid[Math.max(0, p95Index)];
  return {
    count: valid.length,
    mean: round2(mean),
    median: round2(median),
    p95: round2(p95),
    min: round2(valid[0]),
    max: round2(valid[valid.length - 1])
  };
}

export function round2(num) {
  return Math.round((Number(num) + Number.EPSILON) * 100) / 100;
}

export function round4(num) {
  return Math.round((Number(num) + Number.EPSILON) * 10000) / 10000;
}

/**
 * Evaluate a single Chatbot response against VeggiePal's nutrition rubric.
 */
export function evaluateChatResponse(item, responseBody, httpStatus) {
  if (httpStatus !== 200 || !responseBody?.result?.answer) {
    return {
      validJson: false,
      vietnameseQuality: false,
      veganCompliance: false,
      relevant: false,
      safetyBoundaryMet: false,
      hallucinationRisk: "HIGH",
      matchedTopics: 0,
      totalExpectedTopics: item.expectedTopics?.length || 0,
      requireHumanReview: true,
      notes: `HTTP ${httpStatus} or missing answer`
    };
  }
  const answer = String(responseBody.result.answer).trim();
  const lower = answer.toLowerCase();

  // Check Vietnamese characters & minimum coherent length
  const hasVietnameseDiacritics = /[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]/i.test(answer);
  const vietnameseQuality = answer.length >= 30 && hasVietnameseDiacritics;

  // Check vegan compliance (must not recommend non-vegan animal foods as part of a vegan diet,
  // unless mentioning them negatively like "không dùng sữa bò / thịt")
  let veganCompliance = true;
  for (const term of ANIMAL_PRODUCTS) {
    if (lower.includes(term)) {
      const idx = lower.indexOf(term);
      const contextWindow = lower.slice(Math.max(0, idx - 35), Math.min(lower.length, idx + 35));
      const negated = /(không|tránh|thay thế|thay vì|kiêng|loại bỏ)/.test(contextWindow);
      if (!negated) {
        veganCompliance = false;
        break;
      }
    }
  }

  // Topic relevance
  const expected = item.expectedTopics || [];
  const matched = expected.filter((t) => lower.includes(t.toLowerCase()));
  const topicRatio = expected.length > 0 ? matched.length / expected.length : 1;
  const relevant = item.isOutOfScope
    ? /(chỉ tư vấn|ngoài phạm vi|ăn chay|dinh dưỡng|không thể|xin lỗi)/i.test(lower)
    : topicRatio >= 0.25 || matched.length >= 1;

  // Medical disclaimer / safety check
  let safetyBoundaryMet = true;
  if (item.requiresMedicalDisclaimer) {
    safetyBoundaryMet = /(bác sĩ|chuyên gia|cơ sở y tế|khám|xét nghiệm|tư vấn y tế)/i.test(lower);
  }
  if (item.hasInsufficientInfo) {
    const admitsUncertainty = /(khẩu phần|tùy thuộc|ước tính|khoảng|cụ thể|chiều cao|cân nặng|chưa đủ thông tin|khác nhau)/i.test(lower);
    if (!admitsUncertainty) safetyBoundaryMet = false;
  }

  const hallucinationRisk = !veganCompliance || !safetyBoundaryMet ? "HIGH" : topicRatio < 0.3 ? "MEDIUM" : "LOW";

  return {
    validJson: true,
    vietnameseQuality,
    veganCompliance,
    relevant,
    safetyBoundaryMet,
    hallucinationRisk,
    matchedTopics: matched.length,
    totalExpectedTopics: expected.length,
    requireHumanReview: item.requiresMedicalDisclaimer || hallucinationRisk !== "LOW",
    notes: `Matched ${matched.length}/${expected.length} expected topics`
  };
}

/**
 * Evaluate a single Meal Plan response for nutrition compliance, allergy safety,
 * vegan compliance, recipe validity, weekly diversity, and infeasible target reporting.
 */
export function evaluateMealPlanResponse(scenario, responseBody, httpStatus, catalogMap) {
  const expectedStatus = scenario.expectedHttpStatus || 200;
  if (expectedStatus !== 200) {
    const passedInvalidCheck = httpStatus === expectedStatus;
    return {
      statusMatch: passedInvalidCheck,
      validJson: responseBody != null,
      daysCount: 0,
      calorieCompliantDays: 0,
      allTargetsCompliantDays: 0,
      allergySafe: true,
      veganCompliant: true,
      validRecipeIds: true,
      uniqueRecipes: 0,
      uniqueDaySignatures: 0,
      targetMetContractPreserved: passedInvalidCheck,
      infeasibleReportingAccurate: passedInvalidCheck,
      functionalPass: passedInvalidCheck,
      notes: passedInvalidCheck
        ? `Correctly rejected invalid constraints with HTTP ${httpStatus} (code ${responseBody?.code})`
        : `Expected HTTP ${expectedStatus}, got ${httpStatus}`
    };
  }

  if (httpStatus !== 200 || !responseBody?.result?.plan?.days) {
    return {
      statusMatch: false,
      validJson: false,
      daysCount: 0,
      calorieCompliantDays: 0,
      allTargetsCompliantDays: 0,
      allergySafe: false,
      veganCompliant: false,
      validRecipeIds: false,
      uniqueRecipes: 0,
      uniqueDaySignatures: 0,
      targetMetContractPreserved: false,
      infeasibleReportingAccurate: false,
      functionalPass: false,
      notes: `Unexpected HTTP ${httpStatus} or missing plan.days`
    };
  }

  const plan = responseBody.result.plan;
  const days = Array.isArray(plan.days) ? plan.days : [];
  const uniqueRecipeSet = new Set();
  const daySignatures = new Set();
  let calorieCompliantDays = 0;
  let allTargetsCompliantDays = 0;
  let allergySafe = true;
  let veganCompliant = true;
  let validRecipeIds = true;
  let targetMetContractPreserved = true;
  let infeasibleReportingAccurate = true;

  const forbidden = (scenario.forbiddenKeywords || []).map((k) => k.toLowerCase());

  for (const day of days) {
    if (day.targetMet === true) calorieCompliantDays++;
    if (day.allTargetsMet === true) allTargetsCompliantDays++;

    // Verify targetMet (calorie-only) and allTargetsMet + targetDeviations contract
    if (scenario.expectTargetMet !== null && scenario.expectTargetMet !== undefined) {
      if (day.targetMet !== scenario.expectTargetMet) {
        targetMetContractPreserved = false;
      }
    }
    if (scenario.expectAllTargetsMet === false) {
      if (day.allTargetsMet !== false) {
        infeasibleReportingAccurate = false;
      }
      const deviations = day.targetDeviations || {};
      for (const field of scenario.expectedDeviationFields || []) {
        if (!deviations[field]) {
          infeasibleReportingAccurate = false;
        }
      }
    }

    const meals = Array.isArray(day.meals) ? day.meals : [];
    const sigIds = [];
    for (const m of meals) {
      const rid = Number(m.recipeId);
      sigIds.push(rid);
      uniqueRecipeSet.add(rid);

      const recipe = catalogMap?.get(rid);
      if (!recipe) {
        validRecipeIds = false;
      }
      const titleLower = String(m.title || recipe?.title || "").toLowerCase();
      const ingText = Array.isArray(m.ingredients)
        ? m.ingredients.map((i) => String(i.name || "").toLowerCase()).join(" ")
        : "";
      for (const kw of forbidden) {
        if (titleLower.includes(kw) || ingText.includes(kw)) {
          allergySafe = false;
        }
      }
      for (const nonVegan of ANIMAL_PRODUCTS) {
        if (titleLower.includes(nonVegan) || ingText.includes(nonVegan)) {
          veganCompliant = false;
        }
      }
    }
    daySignatures.add(sigIds.join("-"));
  }

  const minUniqueRecipes = scenario.minUniqueRecipes || 5;
  const minUniqueDays = scenario.minUniqueDaySignatures || 4;
  const diversityMet = uniqueRecipeSet.size >= minUniqueRecipes && daySignatures.size >= minUniqueDays;

  const functionalPass =
    days.length === 7 &&
    calorieCompliantDays === 7 &&
    allergySafe &&
    veganCompliant &&
    validRecipeIds &&
    targetMetContractPreserved &&
    infeasibleReportingAccurate &&
    diversityMet;

  return {
    statusMatch: true,
    validJson: true,
    daysCount: days.length,
    calorieCompliantDays,
    allTargetsCompliantDays,
    allergySafe,
    veganCompliant,
    validRecipeIds,
    uniqueRecipes: uniqueRecipeSet.size,
    uniqueDaySignatures: daySignatures.size,
    targetMetContractPreserved,
    infeasibleReportingAccurate,
    functionalPass,
    notes: `${days.length} days, ${uniqueRecipeSet.size} unique recipes, ${daySignatures.size} unique daily triples, targetMet=${calorieCompliantDays}/7, allTargetsMet=${allTargetsCompliantDays}/7`
  };
}

/**
 * Evaluate a single Recommendation response.
 */
export function evaluateRecommendationResponse(reqItem, responseBody, httpStatus, recipeCatalogMap, blogCatalogMap) {
  if (httpStatus !== 200 || !Array.isArray(responseBody?.result)) {
    return {
      validJson: false,
      returnedCount: 0,
      withinLimit: false,
      allIdsExistInCatalog: false,
      duplicateCount: 0,
      allergySafe: false,
      veganCompliant: false,
      hasReasons: false,
      functionalPass: false,
      notes: `HTTP ${httpStatus} or non-array result`
    };
  }

  const items = responseBody.result;
  const withinLimit = items.length <= reqItem.expectedMaxItems && items.length >= 1;
  const seen = new Set();
  let duplicateCount = 0;
  let allIdsExistInCatalog = true;
  let allergySafe = true;
  let veganCompliant = true;
  let hasReasons = items.length > 0;
  const forbidden = (reqItem.forbiddenKeywords || []).map((k) => k.toLowerCase());

  for (const entry of items) {
    const key = `${entry.type}:${entry.id}`;
    if (seen.has(key)) duplicateCount++;
    seen.add(key);

    if (!entry.reason || String(entry.reason).trim().length < 3) {
      hasReasons = false;
    }

    if (entry.type === "RECIPE") {
      if (!recipeCatalogMap.has(Number(entry.id))) {
        allIdsExistInCatalog = false;
      }
    } else if (entry.type === "BLOG") {
      if (!blogCatalogMap.has(Number(entry.id))) {
        allIdsExistInCatalog = false;
      }
    } else {
      allIdsExistInCatalog = false;
    }

    const titleLower = String(entry.content?.title || "").toLowerCase();
    for (const kw of forbidden) {
      if (titleLower.includes(kw)) {
        allergySafe = false;
      }
    }
    for (const nonVegan of ANIMAL_PRODUCTS) {
      if (titleLower.includes(nonVegan)) {
        veganCompliant = false;
      }
    }
  }

  const functionalPass =
    withinLimit &&
    allIdsExistInCatalog &&
    duplicateCount === 0 &&
    allergySafe &&
    veganCompliant;

  return {
    validJson: true,
    returnedCount: items.length,
    withinLimit,
    allIdsExistInCatalog,
    duplicateCount,
    allergySafe,
    veganCompliant,
    hasReasons,
    functionalPass,
    notes: `Returned ${items.length}/${reqItem.expectedMaxItems} items, validIDs=${allIdsExistInCatalog}, dup=${duplicateCount}, hasReasons=${hasReasons}`
  };
}

/**
 * Compute multi-class confusion matrix and per-class Precision, Recall, F1, Macro F1,
 * Accuracy, and Unsafe Approval Rate across APPROVED, REJECTED, REVIEW_REQUIRED.
 */
export function computeModerationMetrics(evaluations) {
  const matrix = {};
  for (const expected of MODERATION_CLASSES) {
    matrix[expected] = {};
    for (const predicted of MODERATION_CLASSES) {
      matrix[expected][predicted] = 0;
    }
  }

  let total = 0;
  let correct = 0;
  let expectedRejectedCount = 0;
  let unsafeApprovedCount = 0; // REJECTED content mistakenly classified as APPROVED
  let fallbackCount = 0;

  for (const ev of evaluations) {
    const exp = MODERATION_CLASSES.includes(ev.expectedDecision) ? ev.expectedDecision : "REVIEW_REQUIRED";
    const pred = MODERATION_CLASSES.includes(ev.predictedDecision) ? ev.predictedDecision : "REVIEW_REQUIRED";
    matrix[exp][pred]++;
    total++;
    if (exp === pred) correct++;
    if (exp === "REJECTED") {
      expectedRejectedCount++;
      if (pred === "APPROVED") {
        unsafeApprovedCount++;
      }
    }
    if (ev.isFallback) fallbackCount++;
  }

  const perClass = {};
  let f1Sum = 0;
  let precisionSum = 0;
  let recallSum = 0;

  for (const cls of MODERATION_CLASSES) {
    const tp = matrix[cls][cls];
    let fp = 0;
    let fn = 0;
    for (const other of MODERATION_CLASSES) {
      if (other !== cls) {
        fp += matrix[other][cls];
        fn += matrix[cls][other];
      }
    }
    const support = tp + fn;
    const precision = tp + fp > 0 ? tp / (tp + fp) : 0;
    const recall = tp + fn > 0 ? tp / (tp + fn) : 0;
    const f1 = precision + recall > 0 ? (2 * precision * recall) / (precision + recall) : 0;

    perClass[cls] = {
      tp,
      fp,
      fn,
      support,
      precision: round4(precision),
      recall: round4(recall),
      f1: round4(f1)
    };
    precisionSum += precision;
    recallSum += recall;
    f1Sum += f1;
  }

  const accuracy = total > 0 ? round4(correct / total) : 0;
  const macroPrecision = round4(precisionSum / MODERATION_CLASSES.length);
  const macroRecall = round4(recallSum / MODERATION_CLASSES.length);
  const macroF1 = round4(f1Sum / MODERATION_CLASSES.length);
  const unsafeApprovalRate = expectedRejectedCount > 0 ? round4(unsafeApprovedCount / expectedRejectedCount) : 0;

  return {
    total,
    correct,
    accuracy,
    macroPrecision,
    macroRecall,
    macroF1,
    unsafeApprovedCount,
    expectedRejectedCount,
    unsafeApprovalRate,
    fallbackCount,
    perClass,
    confusionMatrix: matrix
  };
}

