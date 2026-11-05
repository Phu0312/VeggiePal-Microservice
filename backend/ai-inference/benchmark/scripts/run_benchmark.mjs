#!/usr/bin/env node
/**
 * VeggiePal Self-Hosted AI Benchmark & Quality Evaluation Runner
 *
 * Authenticates via supported Gateway login endpoints using environment variables
 * (never hardcoding JWTs or printing secrets), executes warm-up and measured
 * requests across Chatbot, Meal Planning, Recommendations, and Moderation,
 * executes direct llama.cpp timing probes to capture prompt eval ms and token
 * generation speed (tokens/s), samples Docker and NVIDIA GPU hardware metrics,
 * cleans up temporary benchmark records, and writes CSV and JSON results.
 *
 * Usage:
 *   node backend/ai-inference/benchmark/scripts/run_benchmark.mjs [--mode full|smoke]
 */

import fs from "node:fs";
import path from "node:path";
import { execSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import {
  computeLatencyStats,
  evaluateChatResponse,
  evaluateMealPlanResponse,
  evaluateRecommendationResponse,
  computeModerationMetrics,
  round2
} from "./evaluate_quality.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const benchmarkRoot = path.resolve(__dirname, "..");
const datasetsDir = path.join(benchmarkRoot, "datasets");
const resultsDir = path.join(benchmarkRoot, "results");

const GATEWAY_URL = process.env.BENCHMARK_GATEWAY_URL || "http://localhost:9080";
const LLAMA_URL = process.env.BENCHMARK_LLAMA_URL || "http://127.0.0.1:8088";
const LLAMA_MODEL = process.env.BENCHMARK_LLAMA_MODEL || "qwen2.5-1.5b-instruct";

// Test accounts configured via environment variables with safe local seed defaults
const USER_EMAIL = process.env.BENCHMARK_USER_EMAIL || "phudepzai@gmail.com";
const USER2_EMAIL = process.env.BENCHMARK_USER2_EMAIL || "hoangphulk2005@gmail.com";
const ADMIN_EMAIL = process.env.BENCHMARK_ADMIN_EMAIL || "huy@gmail.com";
const TEST_PASSWORD = process.env.BENCHMARK_PASSWORD || "password";

const args = process.argv.slice(2);
const modeIdx = args.indexOf("--mode");
const MODE = modeIdx >= 0 && args[modeIdx + 1] ? args[modeIdx + 1] : "full";

function parseMemToMiB(memStr) {
  if (!memStr) return 0;
  const usagePart = String(memStr).split("/")[0].trim();
  const match = usagePart.match(/^([\d.]+)\s*([KMGTP]i?B)$/i);
  if (!match) return 0;
  const val = parseFloat(match[1]);
  const unit = match[2].toUpperCase();
  if (unit.startsWith("G")) return round2(val * 1024);
  if (unit.startsWith("M")) return round2(val);
  if (unit.startsWith("K")) return round2(val / 1024);
  return round2(val);
}

function sampleHardware(phase, feature, requestId) {
  const timestamp = new Date().toISOString();
  let llamaCpuPct = null;
  let llamaMemMiB = null;
  let llamaMemLimitMiB = null;
  let aiServiceCpuPct = null;
  let aiServiceMemMiB = null;
  let aiServiceMemLimitMiB = null;

  try {
    const dockerOut = execSync(
      'docker stats --no-stream --format "{{.Name}},{{.CPUPerc}},{{.MemUsage}}" veggiepal-local-ai-llama-1 veggiepal-prm-ai-service',
      { encoding: "utf8", timeout: 8000, stdio: ["ignore", "pipe", "ignore"] }
    ).trim();
    for (const line of dockerOut.split(/\r?\n/)) {
      const [name, cpuStr, memStr] = line.split(",");
      if (!name) continue;
      const cpu = parseFloat(String(cpuStr || "0").replace("%", "")) || 0;
      const parts = String(memStr || "").split("/");
      const usedMiB = parseMemToMiB(parts[0]);
      const limitMiB = parseMemToMiB(parts[1]);
      if (name.includes("llama")) {
        llamaCpuPct = round2(cpu);
        llamaMemMiB = usedMiB;
        llamaMemLimitMiB = limitMiB;
      } else if (name.includes("ai-service")) {
        aiServiceCpuPct = round2(cpu);
        aiServiceMemMiB = usedMiB;
        aiServiceMemLimitMiB = limitMiB;
      }
    }
  } catch {
    // Docker stats unavailable
  }

  let gpuName = "unavailable";
  let gpuUtilPct = null;
  let gpuMemUsedMiB = null;
  let gpuMemTotalMiB = null;
  let gpuTempC = null;
  let gpuPowerW = null;

  try {
    const smiOut = execSync(
      "nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw --format=csv,noheader,nounits",
      { encoding: "utf8", timeout: 5000, stdio: ["ignore", "pipe", "ignore"] }
    ).trim();
    const firstLine = smiOut.split(/\r?\n/)[0];
    if (firstLine) {
      const cols = firstLine.split(",").map((s) => s.trim());
      gpuName = cols[0] || "NVIDIA GPU";
      gpuUtilPct = Number.isNaN(parseFloat(cols[1])) ? null : round2(parseFloat(cols[1]));
      gpuMemUsedMiB = Number.isNaN(parseFloat(cols[2])) ? null : round2(parseFloat(cols[2]));
      gpuMemTotalMiB = Number.isNaN(parseFloat(cols[3])) ? null : round2(parseFloat(cols[3]));
      gpuTempC = Number.isNaN(parseFloat(cols[4])) ? null : round2(parseFloat(cols[4]));
      gpuPowerW = Number.isNaN(parseFloat(cols[5])) ? null : round2(parseFloat(cols[5]));
    }
  } catch {
    // nvidia-smi unavailable
  }

  return {
    timestamp,
    phase,
    feature,
    requestId,
    llamaCpuPct,
    llamaMemMiB,
    llamaMemLimitMiB,
    aiServiceCpuPct,
    aiServiceMemMiB,
    aiServiceMemLimitMiB,
    gpuName,
    gpuUtilPct,
    gpuMemUsedMiB,
    gpuMemTotalMiB,
    gpuTempC,
    gpuPowerW
  };
}

async function httpJson(url, options = {}) {
  const maxRetries = options.retries ?? 2;
  let lastError = null;
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      const start = performance.now();
      const headers = { "Content-Type": "application/json", Connection: "close", ...(options.headers || {}) };
      const res = await fetch(url, {
        method: options.method || "GET",
        headers,
        body: options.body ? JSON.stringify(options.body) : undefined
      });
      const elapsedMs = round2(performance.now() - start);
      const text = await res.text();
      let json = null;
      try {
        json = JSON.parse(text);
      } catch {
        json = null;
      }
      return { status: res.status, elapsedMs, json, rawText: text };
    } catch (err) {
      lastError = err;
      if (attempt < maxRetries) {
        await new Promise((r) => setTimeout(r, 400));
      }
    }
  }
  throw lastError;
}

async function loginAccount(email, password) {
  const res = await httpJson(`${GATEWAY_URL}/api/auth/login`, {
    method: "POST",
    body: { email, password }
  });
  if (res.status !== 200 || !res.json?.result?.accessToken) {
    throw new Error(`Authentication failed for ${email}: HTTP ${res.status}`);
  }
  return {
    email,
    userId: res.json.result.userId,
    role: res.json.result.role,
    token: res.json.result.accessToken
  };
}

async function ensureUserProfileAndHealth(token) {
  await httpJson(`${GATEWAY_URL}/api/users/me`, {
    method: "PATCH",
    headers: { Authorization: `Bearer ${token}` },
    body: {
      dateOfBirth: "1996-05-15",
      gender: "FEMALE",
      activityLevel: "MODERATE"
    }
  });
  const h = await httpJson(`${GATEWAY_URL}/api/nutrition/me/health-records/latest`, {
    headers: { Authorization: `Bearer ${token}` }
  });
  if (h.status !== 200 || !h.json?.result?.heightCm) {
    await httpJson(`${GATEWAY_URL}/api/nutrition/me/health-records`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}` },
      body: { heightCm: 165.0, weightKg: 58.0 }
    });
  }
}

async function setAllergies(token, allergenIds) {
  await httpJson(`${GATEWAY_URL}/api/nutrition/me/allergies`, {
    method: "PUT",
    headers: { Authorization: `Bearer ${token}` },
    body: { allergenIds }
  });
}

async function fetchLatestUsageLog(adminToken, userId, feature) {
  const res = await httpJson(
    `${GATEWAY_URL}/api/ai/admin/monitoring/logs/search?userId=${userId}&feature=${feature}&page=0&size=1`,
    { headers: { Authorization: `Bearer ${adminToken}` } }
  );
  return res.json?.result?.items?.[0] || null;
}

/**
 * Direct llama.cpp `/v1/chat/completions` timing probe to measure exact
 * prompt evaluation time (prompt_ms), generation time (predicted_ms),
 * prompt tokens/s, and token generation speed (predicted_per_second).
 */
async function probeDirectLlamaTimings(messages, temperature, maxTokens) {
  const res = await httpJson(`${LLAMA_URL}/v1/chat/completions`, {
    method: "POST",
    body: {
      model: LLAMA_MODEL,
      messages,
      temperature,
      max_tokens: maxTokens
    }
  });
  const timings = res.json?.timings || {};
  const usage = res.json?.usage || {};
  return {
    status: res.status,
    wallMs: res.elapsedMs,
    promptTokens: usage.prompt_tokens ?? timings.prompt_n ?? 0,
    completionTokens: usage.completion_tokens ?? timings.predicted_n ?? 0,
    promptEvalMs: round2(timings.prompt_ms ?? 0),
    promptPerSec: round2(timings.prompt_per_second ?? 0),
    generationMs: round2(timings.predicted_ms ?? 0),
    tokensPerSec: round2(timings.predicted_per_second ?? 0)
  };
}

function toCsvRow(values) {
  return values
    .map((v) => {
      if (v === null || v === undefined) return "";
      const str = String(v);
      if (str.includes(",") || str.includes('"') || str.includes("\n") || str.includes("\r")) {
        return `"${str.replace(/"/g, '""')}"`;
      }
      return str;
    })
    .join(",");
}

async function main() {
  fs.mkdirSync(resultsDir, { recursive: true });
  console.log(`[Benchmark] Starting VeggiePal Self-Hosted AI Benchmark (mode=${MODE})...`);

  // 1. Authenticate accounts (tokens kept in memory only, never logged)
  const adminAuth = await loginAccount(ADMIN_EMAIL, TEST_PASSWORD);
  const user1Auth = await loginAccount(USER_EMAIL, TEST_PASSWORD);
  const user2Auth = await loginAccount(USER2_EMAIL, TEST_PASSWORD);
  console.log(`[Benchmark] Authenticated test accounts: admin(id=${adminAuth.userId}), user1(id=${user1Auth.userId}), user2(id=${user2Auth.userId})`);

  await ensureUserProfileAndHealth(user1Auth.token);
  await ensureUserProfileAndHealth(user2Auth.token);
  await setAllergies(user1Auth.token, []);
  await setAllergies(user2Auth.token, []);

  // 2. Load catalogs for validation
  const recipesRes = await httpJson(`${GATEWAY_URL}/api/recipes?size=250`);
  const blogsRes = await httpJson(`${GATEWAY_URL}/api/blogs?size=250`);
  const recipeCatalog = new Map();
  for (const r of recipesRes.json?.result?.content || []) {
    recipeCatalog.set(Number(r.id), r);
  }
  const blogCatalog = new Map();
  for (const b of blogsRes.json?.result?.items || []) {
    blogCatalog.set(Number(b.id), b);
  }
  console.log(`[Benchmark] Loaded catalog: ${recipeCatalog.size} recipes, ${blogCatalog.size} blogs.`);

  // 3. Load datasets
  let chatbotDataset = JSON.parse(fs.readFileSync(path.join(datasetsDir, "chatbot.json"), "utf8"));
  let mealplanDataset = JSON.parse(fs.readFileSync(path.join(datasetsDir, "mealplan.json"), "utf8"));
  let recommendationDataset = JSON.parse(fs.readFileSync(path.join(datasetsDir, "recommendations.json"), "utf8"));
  let moderationDataset = JSON.parse(fs.readFileSync(path.join(datasetsDir, "moderation.json"), "utf8"));

  if (MODE === "smoke") {
    chatbotDataset = chatbotDataset.slice(0, 3);
    mealplanDataset = mealplanDataset.slice(0, 3);
    recommendationDataset = recommendationDataset.slice(0, 3);
    moderationDataset = moderationDataset.slice(0, 9);
  }

  const hardwareSamples = [];
  const requestRecords = [];
  const createdConversationIds = [];
  const createdModerationCases = [];

  // 4. Sample Idle Hardware Baseline (3 samples before inference)
  console.log("[Benchmark] Sampling idle hardware baseline...");
  for (let i = 1; i <= 3; i++) {
    hardwareSamples.push(sampleHardware("IDLE_BASELINE", "NONE", `IDLE_${i}`));
  }

  // 5. Cold-Start / Warm-Up Requests (1 per feature)
  console.log("[Benchmark] Executing cold-start / warm-up requests across all 4 features...");

  // 5a. Warm-up Chat
  {
    const probe = await probeDirectLlamaTimings(
      [
        { role: "system", content: "Bạn là trợ lý dinh dưỡng chay của VeggiePal. Trả lời bằng ngôn ngữ người dùng, thực tế và ngắn gọn." },
        { role: "user", content: "Đậu hũ có bao nhiêu protein trong 100g?" }
      ],
      0.4,
      250
    );
    const res = await httpJson(`${GATEWAY_URL}/api/ai/chat`, {
      method: "POST",
      headers: { Authorization: `Bearer ${user1Auth.token}` },
      body: { conversationId: null, message: "Đậu hũ có bao nhiêu protein trong 100g?" }
    });
    hardwareSamples.push(sampleHardware("WARMUP", "CHAT", "WARMUP_CHAT"));
    if (res.json?.result?.conversationId) {
      createdConversationIds.push({ token: user1Auth.token, id: res.json.result.conversationId });
    }
    const ulog = await fetchLatestUsageLog(adminAuth.token, user1Auth.userId, "CHAT");
    requestRecords.push({
      requestId: "WARMUP_CHAT",
      feature: "CHAT",
      phase: "COLD_WARMUP",
      scenarioCategory: "warmup",
      httpStatus: res.status,
      apiLatencyMs: res.elapsedMs,
      modelInferenceMs: ulog?.latencyMs ?? probe.wallMs,
      promptEvalMs: probe.promptEvalMs,
      generationMs: probe.generationMs,
      promptTokens: res.json?.result?.promptTokens ?? ulog?.promptTokens ?? probe.promptTokens,
      completionTokens: res.json?.result?.completionTokens ?? ulog?.completionTokens ?? probe.completionTokens,
      tokensPerSec: probe.tokensPerSec,
      success: res.status === 200,
      validJson: res.json?.code === 1000,
      functionalPass: res.status === 200,
      errorCategory: res.status === 200 ? "NONE" : `HTTP_${res.status}`,
      notes: "Warm-up request"
    });
  }

  // 5b. Warm-up Recommendation
  {
    const res = await httpJson(`${GATEWAY_URL}/api/ai/recommendations?interest=nam&limit=2`, {
      headers: { Authorization: `Bearer ${user1Auth.token}` }
    });
    hardwareSamples.push(sampleHardware("WARMUP", "RECOMMENDATION", "WARMUP_REC"));
    const ulog = await fetchLatestUsageLog(adminAuth.token, user1Auth.userId, "RECOMMENDATION");
    const estTokPerSec =
      ulog && ulog.latencyMs > 0 && ulog.completionTokens > 0
        ? round2((ulog.completionTokens / ulog.latencyMs) * 1000)
        : 0;
    requestRecords.push({
      requestId: "WARMUP_REC",
      feature: "RECOMMENDATION",
      phase: "COLD_WARMUP",
      scenarioCategory: "warmup",
      httpStatus: res.status,
      apiLatencyMs: res.elapsedMs,
      modelInferenceMs: ulog?.latencyMs ?? res.elapsedMs,
      promptEvalMs: null,
      generationMs: null,
      promptTokens: ulog?.promptTokens ?? 0,
      completionTokens: ulog?.completionTokens ?? 0,
      tokensPerSec: estTokPerSec,
      success: res.status === 200,
      validJson: res.json?.code === 1000,
      functionalPass: res.status === 200,
      errorCategory: res.status === 200 ? "NONE" : `HTTP_${res.status}`,
      notes: "Warm-up recommendation"
    });
  }

  // 5c. Warm-up Moderation
  {
    const res = await httpJson(`${GATEWAY_URL}/api/ai/moderation/check`, {
      method: "POST",
      headers: { Authorization: `Bearer ${adminAuth.token}` },
      body: {
        contentType: "COMMENT",
        externalContentId: 990000,
        authorId: 990000,
        text: "Món canh rau ngót nấu nấm rơm chay rất ngọt mát."
      }
    });
    hardwareSamples.push(sampleHardware("WARMUP", "MODERATION", "WARMUP_MOD"));
    if (res.json?.result?.caseId && res.json?.result?.decision === "REVIEW_REQUIRED") {
      createdModerationCases.push(res.json.result.caseId);
    }
    const ulog = await fetchLatestUsageLog(adminAuth.token, adminAuth.userId, "MODERATION");
    const estTokPerSec =
      ulog && ulog.latencyMs > 0 && ulog.completionTokens > 0
        ? round2((ulog.completionTokens / ulog.latencyMs) * 1000)
        : 0;
    requestRecords.push({
      requestId: "WARMUP_MOD",
      feature: "MODERATION",
      phase: "COLD_WARMUP",
      scenarioCategory: "warmup",
      httpStatus: res.status,
      apiLatencyMs: res.elapsedMs,
      modelInferenceMs: ulog?.latencyMs ?? res.elapsedMs,
      promptEvalMs: null,
      generationMs: null,
      promptTokens: ulog?.promptTokens ?? 0,
      completionTokens: ulog?.completionTokens ?? 0,
      tokensPerSec: estTokPerSec,
      success: res.status === 200,
      validJson: res.json?.code === 1000,
      functionalPass: res.status === 200,
      errorCategory: res.status === 200 ? "NONE" : `HTTP_${res.status}`,
      notes: "Warm-up moderation"
    });
  }

  // 5d. Warm-up Meal Plan
  {
    const res = await httpJson(`${GATEWAY_URL}/api/ai/meal-plans`, {
      method: "POST",
      headers: { Authorization: `Bearer ${user1Auth.token}` },
      body: mealplanDataset[0].request
    });
    hardwareSamples.push(sampleHardware("WARMUP", "MEAL_PLAN", "WARMUP_MP"));
    const ulog = await fetchLatestUsageLog(adminAuth.token, user1Auth.userId, "MEAL_PLAN");
    const estTokPerSec =
      ulog && ulog.latencyMs > 0 && ulog.completionTokens > 0
        ? round2((ulog.completionTokens / ulog.latencyMs) * 1000)
        : 0;
    requestRecords.push({
      requestId: "WARMUP_MP",
      feature: "MEAL_PLAN",
      phase: "COLD_WARMUP",
      scenarioCategory: "warmup",
      httpStatus: res.status,
      apiLatencyMs: res.elapsedMs,
      modelInferenceMs: ulog?.latencyMs ?? res.elapsedMs,
      promptEvalMs: null,
      generationMs: null,
      promptTokens: ulog?.promptTokens ?? 0,
      completionTokens: ulog?.completionTokens ?? 0,
      tokensPerSec: estTokPerSec,
      success: res.status === 200,
      validJson: res.json?.code === 1000,
      functionalPass: res.status === 200,
      errorCategory: res.status === 200 ? "NONE" : `HTTP_${res.status}`,
      notes: "Warm-up meal plan"
    });
  }

  // 6. Measured Chatbot Evaluation (20 prompts)
  console.log(`[Benchmark] Running ${chatbotDataset.length} Chatbot prompts...`);
  const chatEvaluations = [];
  for (let i = 0; i < chatbotDataset.length; i++) {
    const item = chatbotDataset[i];
    const auth = i % 2 === 0 ? user1Auth : user2Auth;
    const res = await httpJson(`${GATEWAY_URL}/api/ai/chat`, {
      method: "POST",
      headers: { Authorization: `Bearer ${auth.token}` },
      body: { conversationId: null, message: item.prompt }
    });
    if (i % 4 === 0) {
      hardwareSamples.push(sampleHardware("ACTIVE_INFERENCE", "CHAT", item.id));
    }
    if (res.json?.result?.conversationId) {
      createdConversationIds.push({ token: auth.token, id: res.json.result.conversationId });
    }
    const ulog = await fetchLatestUsageLog(adminAuth.token, auth.userId, "CHAT");
    const pTok = res.json?.result?.promptTokens ?? ulog?.promptTokens ?? 0;
    const cTok = res.json?.result?.completionTokens ?? ulog?.completionTokens ?? 0;
    const infMs = ulog?.latencyMs ?? res.elapsedMs;
    const tokSec = infMs > 0 && cTok > 0 ? round2((cTok / infMs) * 1000) : 0;

    const quality = evaluateChatResponse(item, res.json, res.status);
    chatEvaluations.push({
      ...item,
      httpStatus: res.status,
      apiLatencyMs: res.elapsedMs,
      modelInferenceMs: infMs,
      promptTokens: pTok,
      completionTokens: cTok,
      tokensPerSec: tokSec,
      answer: res.json?.result?.answer || "",
      quality
    });

    requestRecords.push({
      requestId: item.id,
      feature: "CHAT",
      phase: "MEASURED",
      scenarioCategory: item.category,
      httpStatus: res.status,
      apiLatencyMs: res.elapsedMs,
      modelInferenceMs: infMs,
      promptEvalMs: null,
      generationMs: null,
      promptTokens: pTok,
      completionTokens: cTok,
      tokensPerSec: tokSec,
      success: res.status === 200,
      validJson: quality.validJson,
      functionalPass: quality.vietnameseQuality && quality.veganCompliance && quality.relevant && quality.safetyBoundaryMet,
      errorCategory: res.status === 200 ? "NONE" : `HTTP_${res.status}`,
      notes: quality.notes
    });
    console.log(`  [CHAT] ${item.id} (${item.category}): ${res.elapsedMs} ms, tok=${pTok}/${cTok} (${tokSec} tok/s)`);
  }

  // 7. Measured Meal Planning Evaluation (10 scenarios)
  console.log(`[Benchmark] Running ${mealplanDataset.length} Meal Planning scenarios...`);
  const mealplanEvaluations = [];
  for (let i = 0; i < mealplanDataset.length; i++) {
    const scenario = mealplanDataset[i];
    const auth = i % 2 === 0 ? user1Auth : user2Auth;
    await setAllergies(auth.token, scenario.allergenIds || []);

    const res = await httpJson(`${GATEWAY_URL}/api/ai/meal-plans`, {
      method: "POST",
      headers: { Authorization: `Bearer ${auth.token}` },
      body: scenario.request
    });
    hardwareSamples.push(sampleHardware("ACTIVE_INFERENCE", "MEAL_PLAN", scenario.id));

    const expectedStatus = scenario.expectedHttpStatus || 200;
    const ulog = expectedStatus === 200 ? await fetchLatestUsageLog(adminAuth.token, auth.userId, "MEAL_PLAN") : null;
    const pTok = ulog?.promptTokens ?? 0;
    const cTok = ulog?.completionTokens ?? 0;
    const infMs = expectedStatus === 200 ? (ulog?.latencyMs ?? res.elapsedMs) : 0;
    const tokSec = infMs > 0 && cTok > 0 ? round2((cTok / infMs) * 1000) : 0;

    const quality = evaluateMealPlanResponse(scenario, res.json, res.status, recipeCatalog);
    mealplanEvaluations.push({
      id: scenario.id,
      scenario: scenario.scenario,
      description: scenario.description,
      httpStatus: res.status,
      apiLatencyMs: res.elapsedMs,
      modelInferenceMs: infMs,
      promptTokens: pTok,
      completionTokens: cTok,
      tokensPerSec: tokSec,
      quality
    });

    requestRecords.push({
      requestId: scenario.id,
      feature: "MEAL_PLAN",
      phase: "MEASURED",
      scenarioCategory: scenario.scenario,
      httpStatus: res.status,
      apiLatencyMs: res.elapsedMs,
      modelInferenceMs: infMs,
      promptEvalMs: null,
      generationMs: null,
      promptTokens: pTok,
      completionTokens: cTok,
      tokensPerSec: tokSec,
      success: res.status === expectedStatus,
      validJson: quality.validJson,
      functionalPass: quality.functionalPass,
      errorCategory: res.status === expectedStatus ? "NONE" : `HTTP_${res.status}`,
      notes: quality.notes
    });
    console.log(`  [MEAL_PLAN] ${scenario.id} (${scenario.scenario}): ${res.elapsedMs} ms, status=${res.status}, pass=${quality.functionalPass}`);
  }
  await setAllergies(user1Auth.token, []);
  await setAllergies(user2Auth.token, []);

  // 8. Measured Recommendations Evaluation (20 requests)
  console.log(`[Benchmark] Running ${recommendationDataset.length} Recommendation requests...`);
  const recommendationEvaluations = [];
  for (let i = 0; i < recommendationDataset.length; i++) {
    const reqItem = recommendationDataset[i];
    const auth = i % 2 === 0 ? user1Auth : user2Auth;
    await setAllergies(auth.token, reqItem.allergenIds || []);

    const q = encodeURIComponent(reqItem.interest || "");
    const res = await httpJson(
      `${GATEWAY_URL}/api/ai/recommendations?interest=${q}&limit=${reqItem.limit}`,
      { headers: { Authorization: `Bearer ${auth.token}` } }
    );
    if (i % 4 === 0) {
      hardwareSamples.push(sampleHardware("ACTIVE_INFERENCE", "RECOMMENDATION", reqItem.id));
    }

    const ulog = await fetchLatestUsageLog(adminAuth.token, auth.userId, "RECOMMENDATION");
    const pTok = ulog?.promptTokens ?? 0;
    const cTok = ulog?.completionTokens ?? 0;
    const infMs = ulog?.latencyMs ?? res.elapsedMs;
    const tokSec = infMs > 0 && cTok > 0 ? round2((cTok / infMs) * 1000) : 0;

    const quality = evaluateRecommendationResponse(reqItem, res.json, res.status, recipeCatalog, blogCatalog);
    recommendationEvaluations.push({
      ...reqItem,
      httpStatus: res.status,
      apiLatencyMs: res.elapsedMs,
      modelInferenceMs: infMs,
      promptTokens: pTok,
      completionTokens: cTok,
      tokensPerSec: tokSec,
      returnedItems: (res.json?.result || []).map((x) => ({ type: x.type, id: x.id, reason: x.reason })),
      quality
    });

    requestRecords.push({
      requestId: reqItem.id,
      feature: "RECOMMENDATION",
      phase: "MEASURED",
      scenarioCategory: reqItem.category,
      httpStatus: res.status,
      apiLatencyMs: res.elapsedMs,
      modelInferenceMs: infMs,
      promptEvalMs: null,
      generationMs: null,
      promptTokens: pTok,
      completionTokens: cTok,
      tokensPerSec: tokSec,
      success: res.status === 200,
      validJson: quality.validJson,
      functionalPass: quality.functionalPass,
      errorCategory: res.status === 200 ? "NONE" : `HTTP_${res.status}`,
      notes: quality.notes
    });
    console.log(`  [REC] ${reqItem.id} (${reqItem.category}): ${res.elapsedMs} ms, items=${quality.returnedCount}, pass=${quality.functionalPass}`);
  }
  await setAllergies(user1Auth.token, []);
  await setAllergies(user2Auth.token, []);

  // 9. Measured Moderation Evaluation (100 samples distributed across 3 accounts to stay well within 100/day per-account quota)
  console.log(`[Benchmark] Running ${moderationDataset.length} Moderation samples...`);
  const modAccounts = [user1Auth, user2Auth, adminAuth];
  const moderationEvaluations = [];
  for (let i = 0; i < moderationDataset.length; i++) {
    const sample = moderationDataset[i];
    const auth = modAccounts[i % modAccounts.length];
    const res = await httpJson(`${GATEWAY_URL}/api/ai/moderation/check`, {
      method: "POST",
      headers: { Authorization: `Bearer ${auth.token}` },
      body: {
        contentType: sample.contentType,
        externalContentId: 990001 + (i % 3),
        authorId: 990001 + (i % 3),
        text: sample.text
      }
    });
    if (i % 15 === 0) {
      hardwareSamples.push(sampleHardware("ACTIVE_INFERENCE", "MODERATION", sample.id));
    }
    if (res.json?.result?.caseId && res.json?.result?.decision === "REVIEW_REQUIRED") {
      createdModerationCases.push(res.json.result.caseId);
    }

    const ulog = await fetchLatestUsageLog(adminAuth.token, auth.userId, "MODERATION");
    const pTok = ulog?.promptTokens ?? 0;
    const cTok = ulog?.completionTokens ?? 0;
    const infMs = ulog?.latencyMs ?? res.elapsedMs;
    const tokSec = infMs > 0 && cTok > 0 ? round2((cTok / infMs) * 1000) : 0;

    const predictedDecision = res.json?.result?.decision || "REVIEW_REQUIRED";
    const confidence = res.json?.result?.confidence ?? 0;
    const categories = res.json?.result?.categories || [];
    const reason = res.json?.result?.reason || "";
    const isFallback = categories.includes("ai_fallback");
    const exactMatch = predictedDecision === sample.expectedDecision;

    moderationEvaluations.push({
      id: sample.id,
      category: sample.category,
      contentType: sample.contentType,
      expectedDecision: sample.expectedDecision,
      predictedDecision,
      confidence,
      categories,
      reason,
      isFallback,
      exactMatch,
      httpStatus: res.status,
      apiLatencyMs: res.elapsedMs,
      modelInferenceMs: infMs,
      promptTokens: pTok,
      completionTokens: cTok,
      tokensPerSec: tokSec
    });

    requestRecords.push({
      requestId: sample.id,
      feature: "MODERATION",
      phase: "MEASURED",
      scenarioCategory: sample.category,
      httpStatus: res.status,
      apiLatencyMs: res.elapsedMs,
      modelInferenceMs: infMs,
      promptEvalMs: null,
      generationMs: null,
      promptTokens: pTok,
      completionTokens: cTok,
      tokensPerSec: tokSec,
      success: res.status === 200 && !isFallback,
      validJson: res.json?.code === 1000 && !isFallback,
      functionalPass: exactMatch,
      errorCategory: res.status !== 200 ? `HTTP_${res.status}` : isFallback ? "AI_FALLBACK" : "NONE",
      notes: `expected=${sample.expectedDecision}, predicted=${predictedDecision}, conf=${confidence}`
    });

    if ((i + 1) % 10 === 0 || i === moderationDataset.length - 1) {
      console.log(`  [MODERATION] Completed ${i + 1}/${moderationDataset.length} (last: ${sample.id} exp=${sample.expectedDecision} pred=${predictedDecision} in ${res.elapsedMs} ms)`);
    }
  }

  // 10. Direct llama.cpp Engine Timing Probes (3 representative requests per feature to measure exact prompt_ms and predicted_per_second)
  console.log("[Benchmark] Running direct llama.cpp engine timing probes (prompt eval ms & token generation speed)...");
  const directEngineProbes = [];
  const probeConfigs = [
    {
      id: "PROBE_CHAT_1",
      feature: "CHAT",
      temperature: 0.4,
      maxTokens: 700,
      messages: [
        { role: "system", content: "Bạn là trợ lý dinh dưỡng chay của VeggiePal. Trả lời bằng ngôn ngữ người dùng, thực tế và ngắn gọn." },
        { role: "user", content: chatbotDataset[0].prompt }
      ]
    },
    {
      id: "PROBE_CHAT_2",
      feature: "CHAT",
      temperature: 0.4,
      maxTokens: 700,
      messages: [
        { role: "system", content: "Bạn là trợ lý dinh dưỡng chay của VeggiePal. Trả lời bằng ngôn ngữ người dùng, thực tế và ngắn gọn." },
        { role: "user", content: chatbotDataset[3].prompt }
      ]
    },
    {
      id: "PROBE_MOD_1",
      feature: "MODERATION",
      temperature: 0,
      maxTokens: 350,
      messages: [
        { role: "system", content: "Bạn là bộ kiểm duyệt an toàn VeggiePal." },
        {
          role: "user",
          content: `Phân loại nội dung cộng đồng sau. Vi phạm gồm: hate, harassment, sexual, violence, self_harm, illegal, spam, misinformation_dangerous. Trả duy nhất JSON: {"decision":"APPROVED|REJECTED|REVIEW_REQUIRED","categories":["..."],"reason":"...","confidence":0.0} REJECTED chỉ khi vi phạm rõ và confidence >= 0.85; không chắc chắn phải REVIEW_REQUIRED. Nội dung: ${moderationDataset[0].text}`
        }
      ]
    },
    {
      id: "PROBE_MOD_2",
      feature: "MODERATION",
      temperature: 0,
      maxTokens: 350,
      messages: [
        { role: "system", content: "Bạn là bộ kiểm duyệt an toàn VeggiePal." },
        {
          role: "user",
          content: `Phân loại nội dung cộng đồng sau. Vi phạm gồm: hate, harassment, sexual, violence, self_harm, illegal, spam, misinformation_dangerous. Trả duy nhất JSON: {"decision":"APPROVED|REJECTED|REVIEW_REQUIRED","categories":["..."],"reason":"...","confidence":0.0} REJECTED chỉ khi vi phạm rõ và confidence >= 0.85; không chắc chắn phải REVIEW_REQUIRED. Nội dung: ${moderationDataset[40]?.text || moderationDataset[1].text}`
        }
      ]
    },
    {
      id: "PROBE_REC_1",
      feature: "RECOMMENDATION",
      temperature: 0.2,
      maxTokens: 600,
      messages: [
        {
          role: "user",
          content: `Chọn tối đa 3 nội dung phù hợp sở thích 'món kho chay đậm đà'. Chỉ dùng candidate đã cho. Trả JSON array [{"type":"BLOG|RECIPE","id":1,"reason":"..."}]. Candidates: [{"type":"RECIPE","id":95,"title":"Nấm đùi gà kho gừng sả ớt"},{"type":"RECIPE","id":97,"title":"Khổ qua xào đậu hũ non"},{"type":"RECIPE","id":98,"title":"Đậu que xào nấm đông cô dầu mè"},{"type":"BLOG","id":1,"title":"Bí quyết ăn chay đủ chất"}]`
        }
      ]
    },
    {
      id: "PROBE_MP_1",
      feature: "MEAL_PLAN",
      temperature: 0.2,
      maxTokens: 850,
      messages: [
        {
          role: "system",
          content: "Bạn là chuyên gia lập thực đơn thuần chay VeggiePal. Chỉ trả JSON hợp lệ, không markdown."
        },
        {
          role: "user",
          content: `Tạo thực đơn 7 ngày, mỗi ngày gồm Sáng, Trưa, Tối. Chỉ chọn recipeId trong danh sách ứng viên. Trả JSON {"days":[{"day":"Thứ 2","meals":[{"mealType":"Sáng","recipeId":95,"servingMultiplier":1.0}]}]}. Ứng viên: [{"id":95,"title":"Nấm đùi gà kho gừng sả ớt","kcal":280,"p":14,"c":22,"f":12},{"id":96,"title":"Rau muống xào tỏi hành boa-rô","kcal":180,"p":8,"c":18,"f":9},{"id":97,"title":"Khổ qua xào đậu hũ non","kcal":240,"p":16,"c":15,"f":13},{"id":98,"title":"Đậu que xào nấm đông cô dầu mè","kcal":210,"p":11,"c":20,"f":10}]`
        }
      ]
    }
  ];

  for (const p of probeConfigs) {
    const t = await probeDirectLlamaTimings(p.messages, p.temperature, p.maxTokens);
    hardwareSamples.push(sampleHardware("DIRECT_ENGINE_PROBE", p.feature, p.id));
    directEngineProbes.push({ ...p, ...t });
    console.log(`  [ENGINE_PROBE] ${p.id} (${p.feature}): promptEval=${t.promptEvalMs} ms (${t.promptPerSec} tok/s), gen=${t.generationMs} ms (${t.tokensPerSec} tok/s)`);
  }

  // 11. Low-Concurrency Queue Test (2 simultaneous moderation requests against single-slot llama.cpp)
  console.log("[Benchmark] Executing controlled 2-request concurrency test against single-slot llama.cpp...");
  const concStart = performance.now();
  const [conc1, conc2] = await Promise.all([
    httpJson(`${GATEWAY_URL}/api/ai/moderation/check`, {
      method: "POST",
      headers: { Authorization: `Bearer ${user1Auth.token}` },
      body: { contentType: "COMMENT", externalContentId: 990009, authorId: 990009, text: "Món đậu hũ chiên sả ớt giòn ngon." }
    }),
    httpJson(`${GATEWAY_URL}/api/ai/moderation/check`, {
      method: "POST",
      headers: { Authorization: `Bearer ${user2Auth.token}` },
      body: { contentType: "COMMENT", externalContentId: 990010, authorId: 990010, text: "Canh bí đỏ nấu đậu phộng bùi béo." }
    })
  ]);
  const concWallMs = round2(performance.now() - concStart);
  hardwareSamples.push(sampleHardware("CONCURRENCY_2", "MODERATION", "CONC_MOD_1_2"));
  console.log(`  [CONCURRENCY_2] req1=${conc1.elapsedMs} ms (HTTP ${conc1.status}), req2=${conc2.elapsedMs} ms (HTTP ${conc2.status}), wall=${concWallMs} ms`);

  // 12. Cleanup temporary conversations and pending moderation cases created by benchmark
  console.log("[Benchmark] Cleaning up temporary benchmark conversations and moderation queue items...");
  let deletedConversations = 0;
  for (const conv of createdConversationIds) {
    const delRes = await httpJson(`${GATEWAY_URL}/api/ai/chat/conversations/${conv.id}`, {
      method: "DELETE",
      headers: { Authorization: `Bearer ${conv.token}` }
    });
    if (delRes.status === 200) deletedConversations++;
  }
  const uniqueModCases = [...new Set(createdModerationCases)];
  let dismissedCases = 0;
  for (const cid of uniqueModCases) {
    const disRes = await httpJson(`${GATEWAY_URL}/api/ai/admin/moderation/${cid}?reason=Benchmark+cleanup`, {
      method: "DELETE",
      headers: { Authorization: `Bearer ${adminAuth.token}` }
    });
    if (disRes.status === 200) dismissedCases++;
  }
  console.log(`[Benchmark] Cleanup complete: deleted ${deletedConversations} chat conversations, dismissed ${dismissedCases} pending moderation cases.`);

  // 13. Export CSV files
  // 13a. requests.csv
  const requestsCsvHeader = [
    "request_id",
    "feature",
    "phase",
    "scenario_category",
    "http_status",
    "api_latency_ms",
    "model_inference_ms",
    "prompt_eval_ms",
    "generation_ms",
    "prompt_tokens",
    "completion_tokens",
    "tokens_per_sec",
    "success",
    "valid_json",
    "functional_pass",
    "error_category",
    "notes"
  ];
  const requestsCsvLines = [toCsvRow(requestsCsvHeader)];
  for (const r of requestRecords) {
    requestsCsvLines.push(
      toCsvRow([
        r.requestId,
        r.feature,
        r.phase,
        r.scenarioCategory,
        r.httpStatus,
        r.apiLatencyMs,
        r.modelInferenceMs,
        r.promptEvalMs,
        r.generationMs,
        r.promptTokens,
        r.completionTokens,
        r.tokensPerSec,
        r.success,
        r.validJson,
        r.functionalPass,
        r.errorCategory,
        r.notes
      ])
    );
  }
  fs.writeFileSync(path.join(resultsDir, "requests.csv"), requestsCsvLines.join("\n") + "\n", "utf8");

  // 13b. hardware.csv
  const hardwareCsvHeader = [
    "timestamp",
    "phase",
    "feature",
    "request_id",
    "llama_cpu_pct",
    "llama_mem_mib",
    "llama_mem_limit_mib",
    "ai_service_cpu_pct",
    "ai_service_mem_mib",
    "ai_service_mem_limit_mib",
    "gpu_name",
    "gpu_util_pct",
    "gpu_vram_used_mib",
    "gpu_vram_total_mib",
    "gpu_temp_c",
    "gpu_power_w"
  ];
  const hardwareCsvLines = [toCsvRow(hardwareCsvHeader)];
  for (const h of hardwareSamples) {
    hardwareCsvLines.push(
      toCsvRow([
        h.timestamp,
        h.phase,
        h.feature,
        h.requestId,
        h.llamaCpuPct,
        h.llamaMemMiB,
        h.llamaMemLimitMiB,
        h.aiServiceCpuPct,
        h.aiServiceMemMiB,
        h.aiServiceMemLimitMiB,
        h.gpuName,
        h.gpuUtilPct,
        h.gpuMemUsedMiB,
        h.gpuMemTotalMiB,
        h.gpuTempC,
        h.gpuPowerW
      ])
    );
  }
  fs.writeFileSync(path.join(resultsDir, "hardware.csv"), hardwareCsvLines.join("\n") + "\n", "utf8");

  // 13c. summary.csv
  const features = ["CHAT", "MEAL_PLAN", "RECOMMENDATION", "MODERATION"];
  const summaryCsvHeader = [
    "feature",
    "total_measured",
    "cold_warmup_ms",
    "api_mean_ms",
    "api_median_ms",
    "api_p95_ms",
    "api_min_ms",
    "api_max_ms",
    "inference_mean_ms",
    "inference_median_ms",
    "inference_p95_ms",
    "inference_max_ms",
    "mean_prompt_tokens",
    "mean_completion_tokens",
    "mean_tokens_per_sec",
    "success_rate_pct",
    "valid_json_rate_pct",
    "functional_pass_rate_pct"
  ];
  const summaryCsvLines = [toCsvRow(summaryCsvHeader)];
  const summaryObjects = {};

  for (const feat of features) {
    const warmupRec = requestRecords.find((r) => r.feature === feat && r.phase === "COLD_WARMUP");
    const measured = requestRecords.filter((r) => r.feature === feat && r.phase === "MEASURED");
    const apiStats = computeLatencyStats(measured.map((r) => r.apiLatencyMs));
    const infValues = measured.filter((r) => r.modelInferenceMs > 0).map((r) => r.modelInferenceMs);
    const infStats = computeLatencyStats(infValues);
    const tokSecValues = measured.filter((r) => r.tokensPerSec > 0).map((r) => r.tokensPerSec);
    const tokStats = computeLatencyStats(tokSecValues);
    const promptStats = computeLatencyStats(measured.filter((r) => r.promptTokens > 0).map((r) => r.promptTokens));
    const compStats = computeLatencyStats(measured.filter((r) => r.completionTokens > 0).map((r) => r.completionTokens));

    const succCount = measured.filter((r) => r.success).length;
    const validCount = measured.filter((r) => r.validJson).length;
    const funcCount = measured.filter((r) => r.functionalPass).length;
    const total = measured.length || 1;

    const rowObj = {
      feature: feat,
      totalMeasured: measured.length,
      coldWarmupMs: warmupRec?.apiLatencyMs ?? 0,
      apiMeanMs: apiStats.mean,
      apiMedianMs: apiStats.median,
      apiP95Ms: apiStats.p95,
      apiMinMs: apiStats.min,
      apiMaxMs: apiStats.max,
      inferenceMeanMs: infStats.mean,
      inferenceMedianMs: infStats.median,
      inferenceP95Ms: infStats.p95,
      inferenceMaxMs: infStats.max,
      meanPromptTokens: promptStats.mean,
      meanCompletionTokens: compStats.mean,
      meanTokensPerSec: tokStats.mean,
      successRatePct: round2((succCount / total) * 100),
      validJsonRatePct: round2((validCount / total) * 100),
      functionalPassRatePct: round2((funcCount / total) * 100)
    };
    summaryObjects[feat] = rowObj;

    summaryCsvLines.push(
      toCsvRow([
        rowObj.feature,
        rowObj.totalMeasured,
        rowObj.coldWarmupMs,
        rowObj.apiMeanMs,
        rowObj.apiMedianMs,
        rowObj.apiP95Ms,
        rowObj.apiMinMs,
        rowObj.apiMaxMs,
        rowObj.inferenceMeanMs,
        rowObj.inferenceMedianMs,
        rowObj.inferenceP95Ms,
        rowObj.inferenceMaxMs,
        rowObj.meanPromptTokens,
        rowObj.meanCompletionTokens,
        rowObj.meanTokensPerSec,
        rowObj.successRatePct,
        rowObj.validJsonRatePct,
        rowObj.functionalPassRatePct
      ])
    );
  }
  fs.writeFileSync(path.join(resultsDir, "summary.csv"), summaryCsvLines.join("\n") + "\n", "utf8");

  // 13d. moderation_confusion_matrix.csv
  const modMetrics = computeModerationMetrics(moderationEvaluations);
  const cmLines = [
    toCsvRow(["expected_actual_or_metric", "pred_APPROVED", "pred_REJECTED", "pred_REVIEW_REQUIRED", "support", "precision", "recall", "f1"])
  ];
  for (const cls of ["APPROVED", "REJECTED", "REVIEW_REQUIRED"]) {
    const c = modMetrics.perClass[cls];
    cmLines.push(
      toCsvRow([
        cls,
        modMetrics.confusionMatrix[cls].APPROVED,
        modMetrics.confusionMatrix[cls].REJECTED,
        modMetrics.confusionMatrix[cls].REVIEW_REQUIRED,
        c.support,
        c.precision,
        c.recall,
        c.f1
      ])
    );
  }
  cmLines.push(
    toCsvRow([
      "OVERALL_MACRO_SUMMARY",
      `accuracy=${modMetrics.accuracy}`,
      `unsafe_approved=${modMetrics.unsafeApprovedCount}/${modMetrics.expectedRejectedCount}`,
      `unsafe_rate=${modMetrics.unsafeApprovalRate}`,
      modMetrics.total,
      modMetrics.macroPrecision,
      modMetrics.macroRecall,
      modMetrics.macroF1
    ])
  );
  fs.writeFileSync(path.join(resultsDir, "moderation_confusion_matrix.csv"), cmLines.join("\n") + "\n", "utf8");

  // 13e. Detailed JSON artifact for report generation
  const fullDetails = {
    executedAt: new Date().toISOString(),
    mode: MODE,
    summaryByFeature: summaryObjects,
    directEngineProbes,
    concurrencyTest: {
      req1Status: conc1.status,
      req1LatencyMs: conc1.elapsedMs,
      req2Status: conc2.status,
      req2LatencyMs: conc2.elapsedMs,
      wallClockMs: concWallMs
    },
    hardwareSamples,
    chatEvaluations,
    mealplanEvaluations,
    recommendationEvaluations,
    moderationMetrics: modMetrics,
    moderationEvaluations
  };
  fs.writeFileSync(path.join(resultsDir, "detailed_evaluation.json"), JSON.stringify(fullDetails, null, 2), "utf8");

  console.log("[Benchmark] All CSV and JSON results written to backend/ai-inference/benchmark/results/");
}

main().catch((err) => {
  console.error("[Benchmark] Fatal error:", err);
  process.exit(1);
});

