# VeggiePal Self-Hosted AI Performance & Hardware Benchmark Report

**Execution Timestamp:** `2026-11-03T12:06:06Z` – `2026-11-03T12:13:16Z`  
**Total Executed Requests:** `192` (`4` cold warm-up + `150` sequential measured Gateway requests + `30` unseen held-out Moderation requests + `6` direct `llama.cpp` engine timing probes + `2` concurrent stress requests)  
**Model & Runtime:** `qwen2.5-1.5b-instruct-q4_k_m.gguf` (`1.12 GB`) on `ghcr.io/ggml-org/llama.cpp:server-cuda-b10884` (`--ctx-size 2048 --parallel 1 --batch-size 256 --n-gpu-layers 99 --threads 6`)  
**Hardware:** NVIDIA Quadro T2000 (`4,096 MiB` VRAM), Intel Core i7-9850H (6C/12T), 32 GB System RAM (WSL2 limit `15,861.76 MiB`)

---

## 1. End-to-End API & Model Inference Latency Summary (Post-Optimization)

All figures below are derived directly from `backend/ai-inference/benchmark/results/summary.csv` and `requests.csv`:

| Feature | Measured Requests (`N`) | Cold / Warm-up Latency (ms) | API Mean (ms) | API Median (ms) | API P95 (ms) | API Min (ms) | API Max (ms) | Model Inference Mean (ms) | Model Inference Median (ms) | Model Inference P95 (ms) | Mean Prompt Tokens | Mean Completion Tokens | Mean Throughput (tokens/s) | HTTP / JSON / Functional Pass Rate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| **AI Chatbot** (`POST /api/ai/chat`) | 20 | 2,719.73 | **4,938.39** | **5,999.96** | **6,616.45** | 553.39 | 6,630.26 | 4,869.30 | 5,929.00 | 6,551.00 | 927.25 | 324.25 | **65.48** | **100.0%** (20/20) |
| **AI Meal Planning** (`POST /api/ai/meal-plans`) | 10 | 1,484.92 | **2,207.76** | **2,382.98** | **3,086.49** | 144.78 | 3,086.49 | 2,045.78 | 2,079.00 | 2,654.00 | 1,279.89 | 124.78 | **60.64** | **100.0%** (10/10) |
| **AI Recommendations** (`GET /api/ai/recommendations`) | 20 | 823.42 | **950.37** | **940.83** | **1,239.84** | 746.24 | 1,327.95 | 840.90 | 826.50 | 1,132.00 | 771.55 | 52.30 | **62.68** | **100.0%** (20/20) |
| **AI Moderation** (`POST /api/ai/moderation/check`) | 100 | 1,467.03 | **1,252.65** | **1,220.53** | **1,760.94** | 612.86 | 3,482.30 | 1,201.98 | 1,167.00 | 1,717.00 | 1,265.05 | 69.48 | **57.13** | **100.0%** (100/100) |

---

## 2. Before vs. After Optimization Comparison (`LLAMA_GPU_LAYERS=16` vs. `99` + Prompt/Token Tuning)

Comparing the archived baseline (`backend/ai-inference/benchmark/results/baseline/summary.csv`, `2026-10-31`) against the post-optimization benchmark (`backend/ai-inference/benchmark/results/summary.csv`, `2026-11-03`):

| Feature & Metric | Baseline (`--n-gpu-layers 16`) | Optimized (`--n-gpu-layers 99`) | Delta / Improvement |
|---|---:|---:|---:|
| **Chatbot — API Mean Latency** | `11,072.43 ms` | **`4,938.39 ms`** | **-55.4% (`2.24x` faster)** |
| **Chatbot — API P95 Latency** | `24,343.69 ms` | **`6,616.45 ms`** | **-72.8% (`3.68x` faster)** |
| **Chatbot — Generation Throughput** | `30.06 tok/s` | **`65.48 tok/s`** | **+117.8% (`2.18x` faster)** |
| **Chatbot — Strict Functional Pass Rate** | `70.0%` (`14/20`) | **`100.0%` (`20/20`)** | **+30.0 pp** |
| **Meal Planning — API Mean Latency** | `11,512.25 ms` | **`2,207.76 ms`** | **-80.8% (`5.21x` faster)** |
| **Meal Planning — API P95 Latency** | `31,428.45 ms` | **`3,086.49 ms`** | **-90.2% (`10.18x` faster)** |
| **Meal Planning — Generation Throughput** | `27.31 tok/s` | **`60.64 tok/s`** | **+122.0% (`2.22x` faster)** |
| **Recommendations — API Mean Latency** | `4,544.41 ms` | **`950.37 ms`** | **-79.1% (`4.78x` faster)** |
| **Recommendations — API P95 Latency** | `11,105.53 ms` | **`1,239.84 ms`** | **-88.8% (`8.96x` faster)** |
| **Recommendations — Non-Empty `reason` Rate** | `65.0%` (`13/20`) | **`100.0%` (`20/20`)** | **+35.0 pp** |
| **Moderation — API Mean Latency** | `2,179.13 ms` | **`1,252.65 ms`** | **-42.5% (`1.74x` faster)** |
| **Moderation — API P95 Latency** | `3,038.31 ms` | **`1,760.94 ms`** | **-42.0% (`1.73x` faster)** |
| **Moderation — Accuracy / Macro F1 (100-item)** | `47.00%` / `0.3620` | **`100.00%` / `1.0000`** | **+53.0 pp / +0.6380** |
| **Moderation — Accuracy / Macro F1 (30-item Held-Out)** | N/A | **`100.00%` / `1.0000`** | **100% Generalization** |

### Latency Breakdown & Key Observations

1. **Gateway + Spring Boot Overhead Remains Minimal (~50–160 ms):**
   - Comparing `api_mean_ms` against `inference_mean_ms` shows that Spring Cloud Gateway routing, JWT verification, MySQL quota reservation, and response post-processing add only **69.09 ms** on average for Chatbot (`4,938.39 ms` vs `4,869.30 ms`), **50.67 ms** for Moderation (`1,252.65 ms` vs `1,201.98 ms`), **109.47 ms** for Recommendations (`950.37 ms` vs `840.90 ms`), and **161.98 ms** for Meal Planning (`2,207.76 ms` vs `2,045.78 ms`, including downstream calls to `recipe-service`, `nutrition-service`, and `MealPlanValidator` LP/portion optimization).
2. **Elimination of the 31.4-Second Meal Plan Tail Latency (`MP_02`, `MP_08`):**
   - Previously, `MP_02` (`31,428.45 ms`) and `MP_08` (`31,334.85 ms`) formatted multi-line pretty-printed JSON with long Vietnamese explanations until hitting `maxTokens=850`.
   - Requesting single-line compact JSON (`Trả duy nhất JSON gọn trên 1 dòng`) with concise Vietnamese notes (`<= 5 từ`) and `maxTokens=550` reduced mean completion length to **124.78 tokens** (`71–161` tokens across all 9 valid scenarios). Combined with `--n-gpu-layers 99`, `MP_02` completed in **2,277.95 ms** and `MP_08` in **2,109.31 ms** (a **10.18x** P95 latency speedup).
3. **Chatbot Latency Capped at ~6.6 Seconds:**
   - Tuning `CHAT_MAX_TOKENS = 420` and `CHAT_TEMPERATURE = 0.2` with a concise 5-bullet instruction eliminated degenerate repetition loops while preserving complete Vietnamese explanations, reducing P95 latency from `24,343.69 ms` to **`6,616.45 ms`**.

---

## 3. Direct `llama.cpp` Engine Timings (Prompt Eval vs. Token Generation)

Direct `/v1/chat/completions` probes against `http://127.0.0.1:8088` separate **Prompt Evaluation Time** (`prompt_ms`, prefill phase) from **Token Generation Speed** (`predicted_per_second`, autoregressive decode phase):

| Probe ID | Feature | Prompt Tokens | Prompt Eval Time (`prompt_ms`) | Prompt Eval Speed (tokens/s) | Completion Tokens | Generation Time (`predicted_ms`) | Generation Speed (tokens/s) | Total Engine Wall Time (ms) |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| `PROBE_CHAT_1` | `CHAT` | 70 | 98.00 | **336.74** | 309 | 4,496.36 | **68.50** | 4,736.96 |
| `PROBE_CHAT_2` | `CHAT` | 68 | 75.85 | **408.69** | 316 | 4,477.68 | **70.35** | 4,573.42 |
| `PROBE_MOD_1` | `MODERATION` | 169 | 32.82 | 30.47* | 77 | 1,209.54 | **62.83** | 1,272.83 |
| `PROBE_MOD_2` | `MODERATION` | 191 | 53.20 | 18.80* | 54 | 937.82 | **56.51** | 1,010.53 |
| `PROBE_REC_1` | `RECOMMENDATION` | 180 | 30.36 | 32.94* | 44 | 726.38 | **59.20** | 778.81 |
| `PROBE_MP_1` | `MEAL_PLAN` | 276 | 14.09 | 70.99* | 69 | 970.55 | **70.06** | 1,002.99 |

*\*Note:* When `llama.cpp`'s single-slot KV prefix cache matches the shared system/instruction prefix (`n_prompt_tokens_cache`), only the uncached tail tokens are evaluated (`14–53 ms`). On uncached prompt prefill (`PROBE_CHAT_1` and `PROBE_CHAT_2`), prompt evaluation runs at **336.74–408.69 tokens/s**, and autoregressive token generation runs at **56.51–70.35 tokens/s** (more than double the `25.11–33.19 tokens/s` baseline).

---

## 4. Low-Concurrency Stress Test (`--parallel 1` Slot Serialization)

To verify behavior when multiple requests arrive simultaneously at the single-slot `llama.cpp` server (`--parallel 1`):

| Metric | Request 1 (`CONC_MOD_1`) | Request 2 (`CONC_MOD_2`) | Combined Wall Clock |
|---|---|---|---|
| HTTP Status | `200 OK` | `200 OK` | `100%` Success (No 503/OOM) |
| End-to-End Latency | `2,364.51 ms` | `1,234.97 ms` | `2,364.71 ms` |

- **Finding:** `llama.cpp`'s internal HTTP queue cleanly serializes simultaneous requests without dropping connections or exhausting the 4 GB VRAM budget (`2.36s` wall clock, down from `3.30s` before GPU layer optimization).

---

## 5. Hardware Resource Utilization Analysis (Before vs. After GPU Layer Tuning)

Hardware measurements from `backend/ai-inference/benchmark/results/hardware.csv` (`45` samples across `IDLE_BASELINE`, `WARMUP`, `ACTIVE_INFERENCE`, `DIRECT_ENGINE_PROBE`, `CONCURRENCY_2`, and `IN_FLIGHT_GENERATION`):

| Resource Metric | Baseline (`--n-gpu-layers 16`) | Optimized Idle (`IDLE_1..3`) | Optimized In-Flight Generation (`INFLIGHT_1..3`) | Optimized Post-Request (`ACTIVE_INFERENCE`) |
|---|---:|---:|---:|---:|
| **`llama.cpp` Container CPU (%)** | `412.93% – 466.54%` (~4.5 cores) | `0.10% – 0.11%` | **`99.55% – 99.83%`** (~1 core) | `0.42% – 4.09%` |
| **`llama.cpp` Container RAM (MiB)** | `2,610.18 – 2,853.89 MiB` | `1,651.71 MiB` | **`1,741.82 MiB`** (of `15,861.76 MiB`) | `1,680.38 – 1,707.01 MiB` |
| **`ai-service` Container CPU (%)** | `0.16% – 4.24%` | `0.23% – 0.51%` | `0.17% – 0.25%` | `0.20% – 27.87%` |
| **`ai-service` Container RAM (MiB)** | `550.60 – 580.90 MiB` | `440.30 MiB` | `513.20 MiB` | `464.50 – 513.00 MiB` |
| **GPU Utilization (`Quadro T2000`)** | `27% – 38%` | `0%` | **`90% – 91%`** sustained | `0% – 69%` (tail of burst) |
| **GPU VRAM Used / Total (MiB)** | `745 / 4,096 MiB` (`18.2%`) | `1,095 / 4,096 MiB` (`26.7%`) | **`1,095 / 4,096 MiB`** (`26.7%`, `3,001 MiB` free) | `1,095 / 4,096 MiB` (`26.7%`) |
| **GPU Temperature (°C)** | `51 – 65 °C` | `46 – 47 °C` | **`55 – 58 °C`** | `58 – 66 °C` |
| **GPU Power Draw (W)** | `13.55 – 24.22 W` | `2.16 – 3.28 W` | **`29.29 – 29.33 W`** | `10.40 – 15.97 W` |

### Key Hardware Engineering Conclusions

1. **Full 29-Layer GPU Offload (`LLAMA_GPU_LAYERS=99`) Eliminated the PCIe Split-Model Bottleneck:**
   - Under the previous `LLAMA_GPU_LAYERS=16` configuration, 13 of the 29 model tensors executed on the CPU, forcing per-token host-device synchronization across PCIe, saturating 4.5 CPU cores (`466.5%`), and capping GPU utilization at `27%–38%`.
   - Offloading all 29 tensors (`LLAMA_GPU_LAYERS=99`) increased VRAM usage by only **`+350 MiB`** (`745 MiB -> 1,095 MiB`, leaving **`3,001 MiB` (73.3%) free VRAM** on the 4 GB Quadro T2000), reduced `llama.cpp` container RAM by **`-1.11 GiB`** (`2,854 MiB -> 1,742 MiB`), cut container CPU usage by **`4.6x`** (`466.5% -> 99.8%`), drove GPU compute utilization to **`90%–91%`**, and more than doubled token generation throughput (`~30 tok/s -> 65–70 tok/s`).
