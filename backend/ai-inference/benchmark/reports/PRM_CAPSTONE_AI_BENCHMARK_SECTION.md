# VeggiePal Self-Hosted AI Benchmark & Quality Evaluation (PRM Capstone Merge-Ready Section)

> **Merge Instruction:** `docs/PRM_CAPSTONE.md` currently contains unresolved Git merge conflict markers (`<<<<<<< Updated upstream` ... `>>>>>>> Stashed changes` around lines 1348 and 1366). To avoid overwriting or silently resolving unrelated upstream/stashed changes, this standalone Markdown document provides the complete, verified **Self-Hosted AI Integration, Performance Benchmark & Quality Evaluation** subsection ready to paste into **Section V (Software Testing Documentation)** and **Section IV.1 / VI.2** of `docs/PRM_CAPSTONE.md` once the existing conflict markers are resolved.

---

## V.5. Self-Hosted AI Inference Benchmark & Functional Quality Evaluation

### 1. Local Inference Architecture & Runtime Configuration

VeggiePal runs four text-based AI features on a self-hosted `llama.cpp` CUDA inference container (`veggiepal-local-ai-llama-1`). Video transcription and recipe extraction have been removed:

| Component | Configuration |
|---|---|
| **Self-Hosted Features** | AI Chatbot (`POST /api/ai/chat`), AI Meal Planning (`POST /api/ai/meal-plans`), AI Recommendations (`GET /api/ai/recommendations`), AI Text Moderation (`POST /api/ai/moderation/check`) |
| **Inference Engine** | `ghcr.io/ggml-org/llama.cpp:server-cuda-b10884` (`127.0.0.1:8088` host loopback, `http://llama:8080/v1` internal Docker network) |
| **Model Artifact** | `qwen2.5-1.5b-instruct-q4_k_m.gguf` (`1.12 GB`, 4-bit `Q4_K_M` quantization, alias `qwen2.5-1.5b-instruct`) |
| **Runtime Flags** | `--ctx-size 2048 --parallel 1 --batch-size 256 --n-gpu-layers 16` |
| **Test Hardware** | NVIDIA Quadro T2000 (`4,096 MiB` VRAM), Intel Core i7-9850H (6C/12T), 32 GB RAM (WSL2 limit `15,861.76 MiB`), Windows 11 + WSL2 |

### 2. End-to-End Performance & Token Throughput

Measured across **162 live requests** (`4` cold warm-ups, `150` sequential measured Gateway requests across reproducible Vietnamese datasets, `6` direct `llama.cpp` engine timing probes, and `2` concurrent stress requests):

| Feature | Measured Requests (`N`) | Cold Warm-up (ms) | API Mean (ms) | API Median (ms) | API P95 (ms) | API Max (ms) | Model Inference Mean (ms) | Mean Prompt Tokens | Mean Completion Tokens | Mean Generation Speed (tokens/s) | HTTP / Contract Success Rate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| **AI Chatbot** | 20 | 698.68 | 11,072.43 | 8,680.40 | 24,343.69 | 24,529.77 | 11,014.60 | 163.25 | 330.95 | **30.06** | **100.0%** (20/20) |
| **AI Meal Planning** | 10 | 10,392.78 | 11,512.25 | 7,730.68 | 31,428.45 | 31,428.45 | 12,395.11 | 1,265.43 | 191.71 | **27.31** | **100.0%** (10/10) |
| **AI Recommendations** | 20 | 2,038.36 | 4,544.41 | 3,753.39 | 11,105.53 | 12,740.31 | 4,418.35 | 707.25 | 120.55 | **26.81** | **100.0%** (20/20) |
| **AI Moderation** | 100 | 2,568.22 | 2,179.13 | 2,015.98 | 3,038.31 | 11,755.69 | 2,128.57 | 160.74 | 61.36 | **30.09** | **99.0%** (99/100)* |

*\*All 100 Moderation HTTP requests returned `HTTP 200 OK`; 1 request (`MOD_030`) triggered `ModerationService`'s built-in `ai_fallback` (`REVIEW_REQUIRED`) due to malformed model JSON.*

- **Direct Engine Timings (`llama.cpp` `/v1/chat/completions`):** Uncached prompt evaluation runs at **187.55–267.47 tokens/s** (`1,020.69 ms` for a 273-token meal-plan prompt; `~50 ms` when the single-slot KV prefix cache hits on shared system prompts). Autoregressive token generation sustains **25.11–33.19 tokens/s** (`~30 tokens/s` average).
- **Single-Slot Concurrency Verification (`--parallel 1`):** Two simultaneous Moderation requests completed with `HTTP 200 OK` in `1,871.31 ms` and `3,299.40 ms` (`3,299.88 ms` wall clock), confirming clean FIFO queue serialization without GPU OOM.

### 3. Hardware Resource Consumption (`docker stats` & `nvidia-smi`)

| Metric | Idle Baseline | Active In-Flight Token Generation (`300 ms` polling) | Post-Request Tail |
|---|---:|---:|---:|
| **`llama.cpp` Container CPU** | `0.07% – 3.58%` | **`412.93% – 466.54%`** (~4.5 cores) | `0.36% – 3.82%` |
| **`llama.cpp` Container RAM** | `2,610.18 MiB` | **`2,853.89 MiB`** / `15,861.76 MiB` | `2,635.78 – 2,853.89 MiB` |
| **`ai-service` Container CPU / RAM** | `0.17%–0.20%` / `576.30 MiB` | `0.16%–0.50%` / `556.10 MiB` | Peak `4.24%` / `580.90 MiB` |
| **GPU Utilization (`Quadro T2000`)** | `0%` | **`27% – 38%`** | `0% – 27%` |
| **GPU VRAM Used / Total** | `745 / 4,096 MiB` (`18.2%`) | **`745 / 4,096 MiB`** (`18.2%`, WDDM static allocation) | `745 / 4,096 MiB` |
| **GPU Temperature / Power** | `51 °C` / `2.36–4.01 W` | **`56–62 °C`** / **`13.55–24.22 W`** | Peak `65 °C` / `5.34–11.11 W` |

### 4. Functional Quality & Moderation Classification Metrics

1. **AI Meal Planning (`10 / 10` scenarios passed — `100%`):**
   - Pre-filtering candidate recipes to 20 balanced items (`compactPromptCandidates`) reduced prompt size from `~10,329` tokens to `1,265.43` tokens, fitting within the `2048`-token context window.
   - All 9 valid plans achieved **100% calorie target compliance (`targetMet = true` across 63/63 days)**, **100% allergy safety** (`MP_06` Peanut/Sesame, `MP_07` Gluten/Mushroom), **100% catalog recipe validity**, and **high weekly diversity** (`7` distinct daily combinations and `10–20` unique recipes per week).
   - On the mathematically infeasible high-protein target (`MP_04`: `1500–1700 kcal`, `90–130g` protein at `1.50x` max portion scale), the service preserved the `targetMet = true` (calorie-only) contract while accurately setting `allTargetsMet = false` and reporting `targetDeviations.protein` across all 7 days.
2. **AI Recommendations (`20 / 20` requests passed — `100%`):**
   - **100% valid catalog IDs** (`77/77` recommended items exist in `recipe-service` or `blog-service`), **0.0% duplicate rate**, and **100% allergy & vegan compliance**. In `13/20` requests (`65%`), the 1.5B model populated non-empty Vietnamese `reason` strings; in `7/20` requests it returned `reason: ""`.
3. **AI Chatbot (`20` Vietnamese prompts):**
   - **100% valid responses**, **100% Vietnamese fluency**, **95% topic relevance** (`19/20`), **90% medical/uncertainty boundary compliance** (`18/20`), and **85% strict vegan compliance** (`17/20`). On 3 prompts (`CHAT_07`, `CHAT_10`, `CHAT_11`), the 1.5B model drifted into mentioning seafood or eggs alongside plant foods when generating long lists, indicating the need for an explicit negative constraint in `ChatService.SYSTEM_PROMPT`.
4. **AI Text Moderation (`100` labeled Vietnamese samples, provisional policy-curated ground truth):**

| Class | Precision | Recall | F1-Score | Support | Confusion Matrix (`Pred APPROVED / REJECTED / REVIEW_REQUIRED`) |
|---|---:|---:|---:|---:|---|
| **`APPROVED`** | `0.9167` | `0.2750` | `0.4231` | 40 | `11 / 24 / 5` |
| **`REJECTED`** | `0.4268` | **`1.0000`** | `0.5983` | 35 | `0 / 35 / 0` |
| **`REVIEW_REQUIRED`** | `0.1667` | `0.0400` | `0.0645` | 25 | `1 / 23 / 1` |
| **Overall / Macro** | **Macro P:** `0.5034` | **Macro R:** `0.4383` | **Macro F1:** `0.3620` | **Acc:** `47.00%` | **Unsafe Approval Rate:** **`0 / 35 (0.00%)`** |

- **Moderation Safety vs. Precision Trade-off:** `Qwen2.5-1.5B-Instruct` achieved **100.0% recall on `REJECTED` content (`35/35`)**, blocking 100% of spam, harassment, dangerous medical misinformation, self-harm, and all 7 adversarial prompt-injection attempts (`0.00%` unsafe approval rate). However, the 1.5B model exhibits a strong over-rejection bias (`82/100` predictions were `REJECTED` with `confidence >= 0.90`), frequently flagging benign educational food-safety posts and borderline `REVIEW_REQUIRED` questions as `REJECTED`.

