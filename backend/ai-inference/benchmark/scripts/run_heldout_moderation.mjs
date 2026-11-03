#!/usr/bin/env node
/**
 * Held-Out Moderation Generalization Benchmark
 *
 * Evaluates backend/ai-inference/benchmark/datasets/moderation_heldout.json (30 unseen samples)
 * against the live VeggiePal AI Moderation endpoint (`POST /api/ai/moderation/check`) and
 * writes confusion matrix and per-sample results to
 * `backend/ai-inference/benchmark/results/moderation_heldout_evaluation.json`.
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { computeModerationMetrics, computeLatencyStats, round2 } from "./evaluate_quality.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const benchmarkRoot = path.resolve(__dirname, "..");
const datasetsDir = path.join(benchmarkRoot, "datasets");
const resultsDir = path.join(benchmarkRoot, "results");

const GATEWAY_URL = process.env.BENCHMARK_GATEWAY_URL || "http://localhost:9080";
const USER_EMAIL = process.env.BENCHMARK_USER_EMAIL || "user@veggiepal.com";
const USER2_EMAIL = process.env.BENCHMARK_USER2_EMAIL || "user2@veggiepal.com";
const ADMIN_EMAIL = process.env.BENCHMARK_ADMIN_EMAIL || "admin@veggiepal.com";
const TEST_PASSWORD = process.env.BENCHMARK_PASSWORD || "password";

async function httpJson(url, options = {}) {
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
  return { status: res.status, elapsedMs, json };
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
    token: res.json.result.accessToken
  };
}

async function main() {
  fs.mkdirSync(resultsDir, { recursive: true });
  const heldoutDataset = JSON.parse(fs.readFileSync(path.join(datasetsDir, "moderation_heldout.json"), "utf8"));
  console.log(`[HeldOut] Running ${heldoutDataset.length} unseen moderation samples...`);

  const adminAuth = await loginAccount(ADMIN_EMAIL, TEST_PASSWORD);
  const user1Auth = await loginAccount(USER_EMAIL, TEST_PASSWORD);
  const user2Auth = await loginAccount(USER2_EMAIL, TEST_PASSWORD);
  const accounts = [user1Auth, user2Auth, adminAuth];

  const evaluations = [];
  const createdCaseIds = [];

  for (let i = 0; i < heldoutDataset.length; i++) {
    const sample = heldoutDataset[i];
    const auth = accounts[i % accounts.length];
    const res = await httpJson(`${GATEWAY_URL}/api/ai/moderation/check`, {
      method: "POST",
      headers: { Authorization: `Bearer ${auth.token}` },
      body: {
        contentType: sample.contentType,
        externalContentId: 995001 + (i % 3),
        authorId: 995001 + (i % 3),
        text: sample.text
      }
    });

    const predictedDecision = res.json?.result?.decision || "REVIEW_REQUIRED";
    const confidence = res.json?.result?.confidence ?? 0;
    const categories = res.json?.result?.categories || [];
    const reason = res.json?.result?.reason || "";
    const isFallback = categories.includes("ai_fallback");
    const exactMatch = predictedDecision === sample.expectedDecision;

    if (res.json?.result?.caseId && predictedDecision === "REVIEW_REQUIRED") {
      createdCaseIds.push(res.json.result.caseId);
    }

    evaluations.push({
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
      apiLatencyMs: res.elapsedMs
    });

    console.log(
      `  [HELDOUT] ${sample.id} (${sample.category}): exp=${sample.expectedDecision} pred=${predictedDecision} match=${exactMatch} (${res.elapsedMs} ms)`
    );
  }

  // Cleanup pending moderation queue items created during held-out test
  const uniqueCaseIds = [...new Set(createdCaseIds)];
  let dismissed = 0;
  for (const cid of uniqueCaseIds) {
    const disRes = await httpJson(`${GATEWAY_URL}/api/ai/admin/moderation/${cid}?reason=Heldout+benchmark+cleanup`, {
      method: "DELETE",
      headers: { Authorization: `Bearer ${adminAuth.token}` }
    });
    if (disRes.status === 200) dismissed++;
  }

  const metrics = computeModerationMetrics(evaluations);
  const latencyStats = computeLatencyStats(evaluations.map((e) => e.apiLatencyMs));

  const output = {
    executedAt: new Date().toISOString(),
    dataset: "moderation_heldout.json",
    totalSamples: heldoutDataset.length,
    latencyStats,
    metrics,
    cleanupDismissedCases: dismissed,
    evaluations
  };

  const outPath = path.join(resultsDir, "moderation_heldout_evaluation.json");
  fs.writeFileSync(outPath, JSON.stringify(output, null, 2), "utf8");
  console.log(
    `[HeldOut] Complete: Accuracy=${(metrics.accuracy * 100).toFixed(2)}%, Macro F1=${metrics.macroF1}, Unsafe Approvals=${metrics.unsafeApprovedCount}/${metrics.expectedRejectedCount}`
  );
}

main().catch((err) => {
  console.error("[HeldOut] Fatal error:", err);
  process.exit(1);
});

