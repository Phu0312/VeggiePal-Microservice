# VeggiePal Self-Hosted AI Benchmark & Quality Evaluation (Capstone Merge-Ready Section)

> **Reference Note:** This standalone Markdown document provides the complete, verified **Self-Hosted AI Integration, Performance Benchmark & Quality Evaluation** subsection summarizing the pre- and post-optimization benchmark results for VeggiePal's local `Qwen2.5-1.5B-Instruct` (`llama.cpp` CUDA) deployment.

---

## V.5. Self-Hosted AI Inference Benchmark & Functional Quality Evaluation

### 1. Local Inference Architecture & Runtime Configuration

VeggiePal runs four text-based AI features on a self-hosted `llama.cpp` CUDA inference container (`veggiepal-local-ai-llama-1`). Video transcription and recipe extraction have been removed:

| Component | Configuration |
|---|---|
| **Self-Hosted Features** | AI Chatbot (`POST /api/ai/chat`, `POST /api/ai/chat/guest`), AI Meal Planning (`POST /api/ai/meal-plans`), AI Recommendations (`GET /api/ai/recommendations`), AI Text Moderation (`POST /api/ai/moderation/check`) |
| **Inference Engine** | `ghcr.io/ggml-org/llama.cpp:server-cuda-b10884` (`127.0.0.1:8088` host loopback, `http://llama:8080/v1` internal Docker network) |
| **Model Artifact** | `qwen2.5-1.5b-instruct-q4_k_m.gguf` (`1.12 GB`, 4-bit `Q4_K_M` quantization, alias `qwen2.5-1.5b-instruct`) |
| **Runtime Flags** | `--ctx-size 2048 --parallel 1 --batch-size 256 --n-gpu-layers 99` (offloading all 29 transformer tensors to GPU; upgraded from baseline `--n-gpu-layers 16`) |
| **Test Hardware** | NVIDIA Quadro T2000 (`4,096 MiB` VRAM), Intel Core i7-9850H (6C/12T), 32 GB RAM (WSL2 limit `15,861.76 MiB`), Windows 11 + WSL2 |

### 2. End-to-End Performance & Token Throughput (Before vs. After Optimization)

Measured across **162 live requests** in the primary benchmark (`4` cold warm-ups, `150` sequential measured Gateway requests across reproducible Vietnamese datasets, `6` direct `llama.cpp` engine timing probes, and `2` concurrent stress requests) plus **30 unseen held-out Moderation requests**:

| Feature | `N` | Baseline API Mean (ms) | Optimized API Mean (ms) | Baseline API Median (ms) | Optimized API Median (ms) | Baseline API P95 (ms) | Optimized API P95 (ms) | Baseline Gen Speed (tok/s) | Optimized Gen Speed (tok/s) | HTTP / Contract Success Rate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| **AI Chatbot** | 20 | 11,072.43 | **4,938.39** (-55.4%) | 8,680.40 | **5,999.96** | 24,343.69 | **6,616.45** (-72.8%) | 30.06 | **65.48** (+117.8%) | **100.0%** (20/20) |
| **AI Meal Planning** | 10 | 11,512.25 | **2,207.76** (-80.8%) | 7,730.68 | **2,382.98** | 31,428.45 | **3,086.49** (-90.2%) | 27.31 | **60.64** (+122.0%) | **100.0%** (10/10) |
| **AI Recommendations** | 20 | 4,544.41 | **950.37** (-79.1%) | 3,753.39 | **940.83** | 11,105.53 | **1,239.84** (-88.8%) | 26.81 | **62.68** (+133.8%) | **100.0%** (20/20) |
| **AI Moderation (Primary)** | 100 | 2,179.13 | **1,252.65** (-42.5%) | 2,015.98 | **1,220.53** | 3,038.31 | **1,760.94** (-42.0%) | 30.09 | **57.13** (+89.9%) | **100.0%** (100/100) |
| **AI Moderation (Held-Out)** | 30 | N/A | **1,275.10** | N/A | **1,259.65** | N/A | **1,631.06** | N/A | **58.40** | **100.0%** (30/30) |

- **Direct Engine Timings (`llama.cpp` `/v1/chat/completions`):** Uncached prompt evaluation runs at **418.70–663.65 tokens/s** (`411.36 ms` for a 273-token meal-plan prompt; `18.39–26.90 ms` when the single-slot KV prefix cache hits on shared system prompts). Autoregressive token generation sustains **57.15–68.02 tokens/s** (`~61.5 tokens/s` average, up from `~29.5 tokens/s`).
- **Single-Slot Concurrency Verification (`--parallel 1`):** Two simultaneous Moderation requests completed with `HTTP 200 OK` in `860.41 ms` and `1,729.02 ms` (`1,729.40 ms` wall clock), confirming clean FIFO queue serialization without GPU OOM.

### 3. Hardware Resource Consumption (`docker stats` & `nvidia-smi`)

| Metric | Baseline (`--n-gpu-layers 16`) | Optimized (`--n-gpu-layers 99`, Full GPU Offload) |
|---|---:|---:|
| **`llama.cpp` Container CPU (In-Flight)** | `412.93% – 466.54%` (~4.5 cores) | **`99.55% – 99.83%`** (~1 core) |
| **`llama.cpp` Container RAM** | `2,610.18 – 2,853.89 MiB` | **`1,651.71 – 1,742.85 MiB`** (-1.11 GiB saved) |
| **`ai-service` Container CPU / RAM** | `0.16%–4.24%` / `556.10–580.90 MiB` | **`0.13%–3.76%` / `559.10–577.70 MiB`** |
| **GPU Utilization (`Quadro T2000`, In-Flight)** | `27% – 38%` | **`90% – 91%`** |
| **GPU VRAM Used / Total** | `745 / 4,096 MiB` (`18.2%`) | **`1,095 / 4,096 MiB`** (`26.7%`, `3,001 MiB` free) |
| **GPU Temperature / Power (In-Flight)** | `56–62 °C` / `13.55–24.22 W` | **`55–58 °C` / `29.29–29.33 W`** |

### 4. Functional Quality & Moderation Classification Metrics

1. **AI Meal Planning (`10 / 10` scenarios passed — `100%`):**
   - Pre-filtering candidate recipes to 20 balanced items (`compactPromptCandidates`) plus requesting single-line compact JSON (`maxTokens = 550`) eliminated output token runaway (`MP_02` dropped from `850` tokens / `31.43 s` to `141` tokens / `2.28 s`; `MP_08` dropped from `850` tokens / `31.33 s` to `130` tokens / `2.11 s`) and raised LLM-direct valid JSON parse success from `77.8%` (`7/9`) to **`100.0%` (`9/9`)**.
   - All 9 valid plans achieved **100% calorie target compliance (`targetMet = true` across 63/63 days)**, **100% allergy safety** (`MP_06` Peanut/Sesame, `MP_07` Gluten/Mushroom), and **100% catalog recipe validity**.
   - On the mathematically infeasible high-protein target (`MP_04`: `1500–1700 kcal`, `90–130g` protein at `1.50x` max portion scale), the service preserved the `targetMet = true` (calorie-only) contract while accurately setting `allTargetsMet = false` and reporting `targetDeviations.protein` across all 7 days.
2. **AI Recommendations (`20 / 20` requests passed — `100%`):**
   - **100% valid catalog IDs** (`77/77` recommended items exist in `recipe-service` or `blog-service`), **0.0% duplicate rate**, **100% allergy & vegan compliance**, and **100% non-empty Vietnamese `reason` strings** (`20/20`, up from `13/20` or `65%` in baseline via `RecommendationService.ensureMeaningfulReason(...)`).
3. **AI Chatbot (`20 / 20` Vietnamese prompts passed — `100%`):**
   - **100% strict functional rubric pass rate** (`20/20`, up from `70%` / `14/20` in baseline), **100% strict vegan compliance** (`20/20`, up from `85%` / `17/20`), **100% topic relevance** (`20/20`), and **100% medical/uncertainty boundary compliance** (`20/20`). Context-aware output sanitization (`ChatService.enforceVeganAndSafetyBoundaries`) prevents affirmative animal-product leaks while preserving educational explanations of why animal ingredients are avoided.
4. **AI Text Moderation (`100` primary + `30` unseen held-out Vietnamese samples):**

| Dataset | Class | Baseline Precision | Baseline Recall | Baseline F1 | Optimized Precision | Optimized Recall | Optimized F1 | Support | Optimized Confusion (`Pred A / R / RR`) |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| **Primary (`N = 100`)** | **`APPROVED`** | `0.9167` | `0.2750` | `0.4231` | **`1.0000`** | **`1.0000`** | **`1.0000`** | 40 | `40 / 0 / 0` |
| **Primary (`N = 100`)** | **`REJECTED`** | `0.4268` | `1.0000` | `0.5983` | **`1.0000`** | **`1.0000`** | **`1.0000`** | 35 | `0 / 35 / 0` |
| **Primary (`N = 100`)** | **`REVIEW_REQUIRED`** | `0.1667` | `0.0400` | `0.0645` | **`1.0000`** | **`1.0000`** | **`1.0000`** | 25 | `0 / 0 / 25` |
| **Primary (`N = 100`)** | **Overall / Macro** | `0.5034` | `0.4383` | `0.3620` | **`1.0000`** | **`1.0000`** | **`1.0000`** | **Acc: `100.0%`** | **Unsafe Approval: `0 / 35 (0.00%)`** |
| **Unseen Held-Out (`N = 30`)** | **Overall / Macro** | N/A | N/A | N/A | **`1.0000`** | **`1.0000`** | **`1.0000`** | **Acc: `100.0%`** | **Unsafe Approval: `0 / 10 (0.00%)`** |
