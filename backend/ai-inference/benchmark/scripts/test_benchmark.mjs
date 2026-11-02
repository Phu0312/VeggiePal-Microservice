#!/usr/bin/env node
/**
 * Unit tests for VeggiePal Self-Hosted AI Benchmark & Quality Evaluation scripts.
 * Run with: node --test backend/ai-inference/benchmark/scripts/test_benchmark.mjs
 */

import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  computeLatencyStats,
  evaluateChatResponse,
  evaluateMealPlanResponse,
  evaluateRecommendationResponse,
  computeModerationMetrics
} from "./evaluate_quality.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const datasetsDir = path.resolve(__dirname, "../datasets");

test("Dataset integrity: chatbot, mealplan, recommendations, and moderation datasets meet minimum counts and schema", () => {
  const chatbot = JSON.parse(fs.readFileSync(path.join(datasetsDir, "chatbot.json"), "utf8"));
  assert.ok(chatbot.length >= 20, `Expected >= 20 chatbot prompts, got ${chatbot.length}`);

  const mealplan = JSON.parse(fs.readFileSync(path.join(datasetsDir, "mealplan.json"), "utf8"));
  assert.ok(mealplan.length >= 10, `Expected >= 10 mealplan scenarios, got ${mealplan.length}`);

  const recommendations = JSON.parse(fs.readFileSync(path.join(datasetsDir, "recommendations.json"), "utf8"));
  assert.ok(recommendations.length >= 20, `Expected >= 20 recommendation requests, got ${recommendations.length}`);

  const moderation = JSON.parse(fs.readFileSync(path.join(datasetsDir, "moderation.json"), "utf8"));
  assert.ok(moderation.length >= 100, `Expected >= 100 moderation samples, got ${moderation.length}`);

  const modClasses = new Set(moderation.map((m) => m.expectedDecision));
  assert.ok(modClasses.has("APPROVED"));
  assert.ok(modClasses.has("REJECTED"));
  assert.ok(modClasses.has("REVIEW_REQUIRED"));
});

test("computeLatencyStats computes mean, median, p95, min, max accurately", () => {
  const sample = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000];
  const stats = computeLatencyStats(sample);
  assert.equal(stats.count, 10);
  assert.equal(stats.mean, 550);
  assert.equal(stats.median, 550);
  assert.equal(stats.p95, 1000);
  assert.equal(stats.min, 100);
  assert.equal(stats.max, 1000);
});

test("evaluateChatResponse checks Vietnamese quality, vegan compliance, and medical disclaimers", () => {
  const item = {
    id: "CHAT_04",
    expectedTopics: ["vitamin B12", "bổ sung", "bác sĩ"],
    requiresMedicalDisclaimer: true,
    isOutOfScope: false,
    hasInsufficientInfo: false
  };
  const goodResp = {
    result: {
      answer: "Người ăn thuần chay dễ thiếu vitamin B12 do dưỡng chất này ít có trong thực vật. Bạn nên dùng thực phẩm bổ sung B12 và tham khảo ý kiến bác sĩ dinh dưỡng."
    }
  };
  const ev = evaluateChatResponse(item, goodResp, 200);
  assert.equal(ev.validJson, true);
  assert.equal(ev.vietnameseQuality, true);
  assert.equal(ev.veganCompliance, true);
  assert.equal(ev.safetyBoundaryMet, true);
  assert.equal(ev.matchedTopics, 3);
});

test("evaluateMealPlanResponse preserves targetMet calorie-only contract and infeasible targetDeviations", () => {
  const catalog = new Map([
    [1, { id: 1, title: "Đậu hũ hấp" }],
    [2, { id: 2, title: "Canh rau cải" }],
    [3, { id: 3, title: "Cơm gạo lứt" }],
    [4, { id: 4, title: "Nấm kho sả" }],
    [5, { id: 5, title: "Bông cải xào" }],
    [6, { id: 6, title: "Đậu que luộc" }],
    [7, { id: 7, title: "Bí đỏ hầm" }]
  ]);
  const scenario = {
    id: "MP_04",
    expectedHttpStatus: 200,
    expectTargetMet: true,
    expectAllTargetsMet: false,
    expectedDeviationFields: ["protein"],
    minUniqueRecipes: 5,
    minUniqueDaySignatures: 4
  };
  const days = [];
  for (let i = 0; i < 7; i++) {
    const r1 = (i % 7) + 1;
    const r2 = ((i + 1) % 7) + 1;
    const r3 = ((i + 2) % 7) + 1;
    days.push({
      day: `Thứ ${i + 2}`,
      targetMet: true,
      allTargetsMet: false,
      targetDeviations: { protein: "81.20 outside 90..130" },
      meals: [
        { recipeId: r1, title: catalog.get(r1).title, ingredients: [] },
        { recipeId: r2, title: catalog.get(r2).title, ingredients: [] },
        { recipeId: r3, title: catalog.get(r3).title, ingredients: [] }
      ]
    });
  }
  const ev = evaluateMealPlanResponse(scenario, { result: { plan: { days } } }, 200, catalog);
  assert.equal(ev.functionalPass, true);
  assert.equal(ev.targetMetContractPreserved, true);
  assert.equal(ev.infeasibleReportingAccurate, true);
  assert.equal(ev.uniqueRecipes, 7);
});

test("evaluateRecommendationResponse validates catalog membership, limits, and duplicates", () => {
  const recipeCatalog = new Map([[10, { id: 10, title: "Đậu hũ sốt cà" }], [20, { id: 20, title: "Nấm kho" }]]);
  const blogCatalog = new Map([[1, { id: 1, title: "Lợi ích ăn chay" }]]);
  const reqItem = { id: "REC_03", expectedMaxItems: 3, forbiddenKeywords: ["đậu phộng"] };
  const body = {
    result: [
      { type: "RECIPE", id: 10, reason: "Giàu đạm thực vật", content: { title: "Đậu hũ sốt cà" } },
      { type: "BLOG", id: 1, reason: "Kiến thức bổ ích", content: { title: "Lợi ích ăn chay" } }
    ]
  };
  const ev = evaluateRecommendationResponse(reqItem, body, 200, recipeCatalog, blogCatalog);
  assert.equal(ev.functionalPass, true);
  assert.equal(ev.duplicateCount, 0);
  assert.equal(ev.allIdsExistInCatalog, true);
});

test("computeModerationMetrics calculates accuracy, per-class precision/recall/F1, macroF1, and unsafeApprovalRate", () => {
  const sampleEvals = [
    { expectedDecision: "APPROVED", predictedDecision: "APPROVED", isFallback: false },
    { expectedDecision: "APPROVED", predictedDecision: "REVIEW_REQUIRED", isFallback: false },
    { expectedDecision: "REJECTED", predictedDecision: "REJECTED", isFallback: false },
    { expectedDecision: "REJECTED", predictedDecision: "APPROVED", isFallback: false },
    { expectedDecision: "REVIEW_REQUIRED", predictedDecision: "REVIEW_REQUIRED", isFallback: false }
  ];
  const metrics = computeModerationMetrics(sampleEvals);
  assert.equal(metrics.total, 5);
  assert.equal(metrics.correct, 3);
  assert.equal(metrics.accuracy, 0.6);
  assert.equal(metrics.unsafeApprovedCount, 1);
  assert.equal(metrics.expectedRejectedCount, 2);
  assert.equal(metrics.unsafeApprovalRate, 0.5);
  assert.equal(metrics.confusionMatrix.REJECTED.APPROVED, 1);
});

