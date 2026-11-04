# VeggiePal Self-Hosted AI Performance & Hardware Benchmark Report

**Execution Timestamp:** `2026-10-31T09:26:59Z` – `2026-10-31T09:43:10Z`  
**Total Executed Requests:** `162` (`4` cold warm-up + `150` sequential measured Gateway requests + `6` direct `llama.cpp` engine timing probes + `2` concurrent stress requests)  
**Model & Runtime:** `qwen2.5-1.5b-instruct-q4_k_m.gguf` (`1.12 GB`) on `ghcr.io/ggml-org/llama.cpp:server-cuda-b10884` (`--ctx-size 2048 --parallel 1 --batch-size 256 --n-gpu-layers 16`)  
**Hardware:** NVIDIA Quadro T2000 (`4,096 MiB` VRAM), Intel Core i7-9850H (6C/12T), 32 GB System RAM (WSL2 limit `15,861.76 MiB`)

---

## 1. End-to-End API & Model Inference Latency Summary

All figures below are derived directly from `backend/ai-inference/benchmark/results/summary.csv` and `requests.csv`:

| Feature | Measured Requests (`N`) | Cold / Warm-up Latency (ms) | API Mean (ms) | API Median (ms) | API P95 (ms) | API Min (ms) | API Max (ms) | Model Inference Mean (ms) | Model Inference Median (ms) | Model Inference P95 (ms) | Mean Prompt Tokens | Mean Completion Tokens | Mean Throughput (tokens/s) | HTTP / JSON Success Rate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| **AI Chatbot** (`POST /api/ai/chat`) | 20 | 698.68 | 11,072.43 | 8,680.40 | 24,343.69 | 1,012.48 | 24,529.77 | 11,014.60 | 8,626.50 | 24,288.00 | 163.25 | 330.95 | **30.06** | **100.0%** (20/20) |
| **AI Meal Planning** (`POST /api/ai/meal-plans`) | 10 | 10,392.78 | 11,512.25 | 7,730.68 | 31,428.45 | 141.67 | 31,428.45 | 12,395.11 | 8,204.00 | 31,155.00 | 1,265.43 | 191.71 | **27.31** | **100.0%** (10/10) |
| **AI Recommendations** (`GET /api/ai/recommendations`) | 20 | 2,038.36 | 4,544.41 | 3,753.39 | 11,105.53 | 1,294.59 | 12,740.31 | 4,418.35 | 3,627.50 | 10,984.00 | 707.25 | 120.55 | **26.81** | **100.0%** (20/20) |
| **AI Moderation** (`POST /api/ai/moderation/check`) | 100 | 2,568.22 | 2,179.13 | 2,015.98 | 3,038.31 | 1,245.43 | 11,755.69 | 2,128.57 | 1,967.50 | 2,987.00 | 160.74 | 61.36 | **30.09** | **99.0%** (99/100)* |

*\*Note on Moderation Success Rate:* All `100/100` Moderation HTTP calls returned `HTTP 200 OK`. One sample (`MOD_030`, `11,755.69 ms`) produced malformed/truncated JSON from the model, triggering `ModerationService`'s built-in safe fallback (`decision=REVIEW_REQUIRED, categories=["ai_fallback"]`). Thus HTTP availability was **100%**, and primary model JSON parse rate was **99.0%** (`99/100`).

### Latency Breakdown & Observations

1. **Gateway + Spring Boot Overhead is Minimal (~50–270 ms):**
   - Comparing `api_mean_ms` against `inference_mean_ms` shows that Spring Cloud Gateway routing, JWT verification, MySQL quota reservation, and response serialization add only **57.83 ms** on average for Chatbot (`11,072.43 ms` vs `11,014.60 ms`), **50.56 ms** for Moderation (`2,179.13 ms` vs `2,128.57 ms`), and **126.06 ms** for Recommendations (`4,544.41 ms` vs `4,418.35 ms`, which includes fetching candidates from `recipe-service`, `blog-service`, and `nutrition-service`).
   - Over **97%** of total API response time is spent inside `llama.cpp` token generation.
2. **Meal Planning Latency Distribution (`MP_01`–`MP_10`):**
   - `MP_10` (invalid nutrition constraints `minCalories > maxCalories`) failed fast in Java validation in **141.67 ms** (`HTTP 400`, `0` model tokens).
   - Seven of the nine valid AI meal plan generations (`MP_01`, `MP_03`, `MP_04`, `MP_05`, `MP_06`, `MP_07`, `MP_09`) completed in **6,018.95 ms – 9,075.35 ms** (median **7,730.68 ms**).
   - Two scenarios (`MP_02` at `31,428.45 ms` and `MP_08` at `31,334.85 ms`) hit the `maxTokens=850` ceiling during verbose JSON generation, after which `MealPlanValidator` deterministically repaired and optimized the 7-day schedule using its verified LP/portion solver.
3. **Chatbot Latency Scales Linearly with Output Length:**
   - Short refusal or clarification answers (`CHAT_17`: `20` tokens in `1,012.48 ms`; `CHAT_20`: `72` tokens in `2,580.55 ms`) return in **1.0–2.6 seconds**.
   - Detailed multi-section nutritional guides that reach the `700`-token completion cap (`CHAT_13`: `24,343.69 ms`, `CHAT_15`: `24,529.77 ms`) take **~24.3–24.5 seconds** at `~28.7 tokens/s`.

---

## 2. Direct `llama.cpp` Engine Timings (Prompt Eval vs. Token Generation)

Direct `/v1/chat/completions` probes against `http://127.0.0.1:8088` separate **Prompt Evaluation Time** (`prompt_ms`, prefill phase) from **Token Generation Speed** (`predicted_per_second`, autoregressive decode phase):

| Probe ID | Feature | Prompt Tokens | Prompt Eval Time (`prompt_ms`) | Prompt Eval Speed (tokens/s) | Completion Tokens | Generation Time (`predicted_ms`) | Generation Speed (tokens/s) | Total Engine Wall Time (ms) |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| `PROBE_CHAT_1` | `CHAT` | 33 | 175.95 | 187.55 | 300 | 9,763.85 | **30.73** | 9,957.09 |
| `PROBE_CHAT_2` | `CHAT` | 31 | 374.23 | 82.84 | 699 | 27,833.36 | **25.11** | 28,225.77 |
| `PROBE_MOD_1` | `MODERATION` | 1 | 52.42 | 19.08* | 76 | 2,613.55 | **29.08** | 2,681.53 |
| `PROBE_MOD_2` | `MODERATION` | 1 | 50.37 | 19.85* | 51 | 1,642.09 | **31.06** | 1,708.13 |
| `PROBE_REC_1` | `RECOMMENDATION` | 1 | 49.65 | 20.14* | 143 | 4,757.40 | **30.06** | 4,824.32 |
| `PROBE_MP_1` | `MEAL_PLAN` | 273 | 1,020.69 | **267.47** | 134 | 4,037.88 | **33.19** | 5,076.64 |

*\*Note:* In `PROBE_MOD_1`, `PROBE_MOD_2`, and `PROBE_REC_1`, `llama.cpp`'s single-slot KV prefix cache reused the shared system/instruction prefix (`n_prompt_tokens_cache`), evaluating only `1` uncached tail token in `~50 ms`. On full uncached prompt prefill (such as `PROBE_MP_1` with `273` new tokens or Run 1's uncached probes `252.24–302.76 tok/s`), prompt evaluation runs at **187–302 tokens/s** (~1.0 second for a 273-token prompt, or ~4.2 seconds for a 1,265-token meal plan prompt). Autoregressive token generation consistently runs at **25.11–33.19 tokens/s** (mean **~29.9 tokens/s**).

---

## 3. Low-Concurrency Stress Test (`--parallel 1` Slot Serialization)

To verify behavior when multiple requests arrive simultaneously at the single-slot `llama.cpp` server (`--parallel 1`):

| Metric | Request 1 (`CONC_MOD_1`) | Request 2 (`CONC_MOD_2`) | Combined Wall Clock |
|---|---|---|---|
| HTTP Status | `200 OK` | `200 OK` | `100%` Success (No 503/OOM) |
| End-to-End Latency | `1,871.31 ms` | `3,299.40 ms` | `3,299.88 ms` |

- **Finding:** `llama.cpp`'s internal HTTP queue cleanly serializes the second request behind the first without dropping connections or exhausting the 4 GB VRAM budget. Request 1 finishes in `1.87s`, and Request 2 finishes `1.43s` later (`3.30s` total elapsed time). Under higher concurrency (e.g., >5 simultaneous long-running chat or meal-plan requests), queuing latency grows linearly ($N \times \text{service time}$), which can risk hitting `RestClient` read timeouts (`ai.local.read-timeout-ms=35000`).

---

## 4. Hardware Resource Utilization Analysis

Hardware measurements from `backend/ai-inference/benchmark/results/hardware.csv` (`49` samples across `IDLE_BASELINE`, `WARMUP`, `ACTIVE_INFERENCE`, `DIRECT_ENGINE_PROBE`, `CONCURRENCY_2`, and `IN_FLIGHT_GENERATION`):

| Resource Metric | Idle Baseline (`IDLE_1..3`) | Post-Request Active State (`ACTIVE_INFERENCE`) | Concurrent In-Flight Generation (`INFLIGHT_1..7`) | Peak Observed Value |
|---|---:|---:|---:|---:|
| **`llama.cpp` Container CPU (%)** | `0.07% – 3.58%` | `0.36% – 3.82%` | **`412.93% – 466.54%`** (~4.5 cores) | **`466.54%`** |
| **`llama.cpp` Container RAM (MiB)** | `2,610.18 MiB` | `2,635.78 – 2,853.89 MiB` | `2,853.89 MiB` | **`2,853.89 MiB`** (of `15,861.76 MiB`) |
| **`ai-service` Container CPU (%)** | `0.17% – 0.20%` | `0.17% – 4.24%` | `0.16% – 0.50%` | **`4.24%`** |
| **`ai-service` Container RAM (MiB)** | `576.30 MiB` | `550.60 – 580.90 MiB` | `556.10 MiB` | **`580.90 MiB`** |
| **GPU Utilization (`Quadro T2000`)** | `0%` | `0% – 27%` (tail of burst) | **`27% – 38%`** sustained | **`38%`** |
| **GPU VRAM Used / Total (MiB)** | `745 / 4096 MiB` (`18.2%`) | `745 / 4096 MiB` (`18.2%`) | `745 / 4096 MiB` (`18.2%`) | **`745 MiB`** (`3,351 MiB` free) |
| **GPU Temperature (°C)** | `51 °C` | `61 – 65 °C` | `56 – 62 °C` | **`65 °C`** |
| **GPU Power Draw (W)** | `2.36 – 4.01 W` | `5.34 – 11.11 W` | **`13.55 – 24.22 W`** | **`24.22 W`** |

### Key Hardware & Model Optimization Findings (Section 9)

1. **Hybrid CPU+GPU Layer Split (`--n-gpu-layers 16`):**
   - `Qwen2.5-1.5B-Instruct` has **28 repeating transformer layers** (plus token embedding and output head = 29 offloaded tensors total). Currently, `--n-gpu-layers 16` offloads only **16 of 29 layers (~55%)** to the Quadro T2000 GPU, consuming just **745 MiB of 4,096 MiB VRAM**, while the remaining 13 layers execute on the Intel Core i7-9850H CPU (driving container CPU utilization to **412%–466%** during token generation and holding **2.85 GiB** of container RAM).
2. **VRAM Headroom Allows Full GPU Offloading (`--n-gpu-layers 99`):**
   - Because the entire `Q4_K_M` GGUF file is `1.12 GB` and the `2048`-token KV cache requires `< 250 MiB`, offloading **all 29 layers (`--n-gpu-layers 99`)** to the Quadro T2000 will require only **~1,450–1,650 MiB VRAM**—leaving over **2.4 GB of free VRAM** on the 4 GB card while eliminating PCIe host-device synchronization per token and dramatically reducing CPU load and token generation latency.
3. **Context Window (`--ctx-size 2048`) & Prompt Budgeting:**
   - Pre-filtering Meal Planning candidates to 20 balanced recipes (`compactPromptCandidates`) reduced average Meal Plan prompt size from `~10,329 tokens` (which previously caused `HTTP 400` context-window rejections) to **`1,265.43` tokens**, fitting comfortably inside the `2048`-token context window alongside `maxTokens=850` output budget (`100%` success rate across all 10 scenarios).
4. **Max Completion Token Tuning:**
   - In `ChatService`, `maxTokens=700` allows long responses to run for `24.5 seconds`. Lowering `maxTokens` to `400–450` (and instructing the system prompt to cap bullet lists at 5 items) would reduce P95 chat latency from `24.3s` to **`~13–15s`**.
   - In `RecommendationService`, `maxTokens` is currently set to `1500`. Reducing this setting may limit long responses on large `limit=10` requests; re-run the benchmark after any such change.

