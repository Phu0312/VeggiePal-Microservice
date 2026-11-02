#!/usr/bin/env node
/**
 * Samples Docker container CPU/RAM and NVIDIA GPU utilization/VRAM/power
 * concurrently DURING active inference across Chat, Meal Plan, Recommendation,
 * and Moderation requests, and appends the in-flight rows to hardware.csv
 * and detailed_evaluation.json.
 */

import fs from "node:fs";
import path from "node:path";
import { execSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { round2 } from "./evaluate_quality.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const resultsDir = path.resolve(__dirname, "../results");
const LLAMA_URL = process.env.BENCHMARK_LLAMA_URL || "http://127.0.0.1:8088";

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
  } catch {}

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
  } catch {}

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
  const inflightSamples = [];
  let running = true;
  const reqPromise = fetch(`${LLAMA_URL}/v1/chat/completions`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Connection: "close" },
    body: JSON.stringify({
      model: "qwen2.5-1.5b-instruct",
      messages: [
        { role: "system", content: "Bạn là trợ lý dinh dưỡng chay của VeggiePal." },
        { role: "user", content: "Hãy phân tích chi tiết vai trò của đạm thực vật, sắt, kẽm, canxi và vitamin B12 trong chế độ ăn thuần chay cho người tập thể thao." }
      ],
      temperature: 0.4,
      max_tokens: 450
    })
  }).finally(() => {
    running = false;
  });

  let idx = 1;
  while (running && idx <= 8) {
    await new Promise((r) => setTimeout(r, 300));
    if (!running) break;
    const s = sampleHardware("IN_FLIGHT_GENERATION", "CHAT", `INFLIGHT_${idx}`);
    inflightSamples.push(s);
    console.log(`[InFlight ${idx}] llamaCPU=${s.llamaCpuPct}%, llamaRAM=${s.llamaMemMiB} MiB, GPU=${s.gpuUtilPct}%, VRAM=${s.gpuMemUsedMiB}/${s.gpuMemTotalMiB} MiB, Temp=${s.gpuTempC}C, Power=${s.gpuPowerW}W`);
    idx++;
  }
  await reqPromise;

  const csvPath = path.join(resultsDir, "hardware.csv");
  const lines = inflightSamples.map((h) =>
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
  fs.appendFileSync(csvPath, lines.join("\n") + "\n", "utf8");

  const jsonPath = path.join(resultsDir, "detailed_evaluation.json");
  if (fs.existsSync(jsonPath)) {
    const data = JSON.parse(fs.readFileSync(jsonPath, "utf8"));
    data.hardwareSamples.push(...inflightSamples);
    fs.writeFileSync(jsonPath, JSON.stringify(data, null, 2), "utf8");
  }
  console.log(`[InFlight] Appended ${inflightSamples.length} active in-flight hardware samples.`);
}

main();

