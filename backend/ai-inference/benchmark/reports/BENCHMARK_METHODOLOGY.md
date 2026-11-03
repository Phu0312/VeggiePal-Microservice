# VeggiePal Self-Hosted AI Benchmark Methodology

## 1. Purpose and Scope

This document defines the benchmark and quality evaluation methodology for VeggiePal's self-hosted local AI inference stack. It evaluates the four self-hosted text features routed through `ai-service` (`http://localhost:9080/api/ai/...`) to the local `llama.cpp` CUDA inference server (`http://llama:8080/v1`, published on host loopback `127.0.0.1:8088`):

1. **AI Chatbot** (`POST /api/ai/chat`)
2. **AI Meal Planning** (`POST /api/ai/meal-plans`)
3. **AI Recommendations** (`GET /api/ai/recommendations`)
4. **AI Text Moderation** (`POST /api/ai/moderation/check`)

**Excluded Feature:** Video transcription and recipe extraction endpoints have been removed. The benchmark covers the four retained local Qwen features.

---

## 2. Test Environment & Hardware Specification

| Component | Measured Configuration |
|---|---|
| Host OS | Windows 11 + WSL2 Docker Engine |
| CPU | Intel Core i7-9850H (6 cores / 12 threads @ 2.60 GHz) |
| System RAM | 32 GB (WSL2 Docker Engine limit: `15,861.76 MiB`) |
| GPU | NVIDIA Quadro T2000 (`4,096 MiB` GDDR5 VRAM) |
| Inference Server | `ghcr.io/ggml-org/llama.cpp:server-cuda-b10884` (`veggiepal-local-ai-llama-1`) |
| Model Artifact | `qwen2.5-1.5b-instruct-q4_k_m.gguf` (`1.12 GB` on disk, alias `qwen2.5-1.5b-instruct`) |
| Server Flags | `--ctx-size 2048 --parallel 1 --batch-size 256 --n-gpu-layers 16` |
| Backend Container | `veggiepal-prm-ai-service` (Java 21, Spring Boot, profiles: `local-testing`, deployment mode: `local`) |
| Local Test Quotas | `AI_LOCAL_TEST_QUOTA_ENABLED=true`, `100` daily requests/feature/user, `5,000,000` daily tokens/user |

---

## 3. Benchmark Datasets (`backend/ai-inference/benchmark/datasets/`)

All datasets are stored in versioned UTF-8 JSON files with Vietnamese prompts and deterministic validation metadata:

1. **`chatbot.json` (20 Vietnamese prompts):**
   - Covers 10 domains: `vegan_nutrition`, `plant_based_protein`, `vitamin_b12`, `iron_and_calcium`, `weight_management`, `vegan_meal_suggestions`, `food_allergies`, `dietary_restrictions`, `insufficient_information`, `safety_and_medical_boundary`, and `scope_boundary`.
2. **`mealplan.json` (10 scenarios):**
   - Covers `weight_loss` (`MP_01`), `weight_maintenance` (`MP_02`), `muscle_gain_feasible` (`MP_03`), `high_protein_infeasible_macro` (`MP_04` — `1500–1700 kcal`, `90–130g` protein at `1.50x` serving multiplier), `restricted_ingredients_pantry` (`MP_05`), `food_allergy_peanut_sesame` (`MP_06`), `food_allergy_mushroom_gluten` (`MP_07`), `weekly_meal_diversity` (`MP_08`), `server_computed_bmr_tdee_target` (`MP_09`), and `invalid_nutrition_constraints` (`MP_10` — `minCalories > maxCalories`).
3. **`recommendations.json` (20 requests):**
   - Covers `limit=1`, `limit=3`, `limit=6`, `limit=10` (supported max), clamping above max (`limit=15 -> 10`), clamping below min (`limit=0 -> 1`), non-matching keyword fallback (`REC_12`), blank interest (`REC_13`), low-calorie interest (`REC_14`), peanut allergy (`REC_15`), mushroom allergy (`REC_16`), specific ingredients (`REC_17`, `REC_18`), and repeated request consistency (`REC_19`, `REC_20`).
4. **`moderation.json` (100 labeled Vietnamese samples):**
   - Distributed across the 3 active classification classes:
     - `APPROVED`: **40 samples** (33 normal vegan recipes/comments/videos + 7 benign educational or medical-context posts).
     - `REJECTED`: **35 samples** (8 spam/gambling/scam, 8 harassment/abuse/threats, 8 harmful health misinformation, 4 self-harm/illegal content, 7 adversarial prompt injection/override attempts).
     - `REVIEW_REQUIRED`: **25 samples** (8 ambiguous nutritional/detox claims, 7 questions discussing unsafe diets without endorsing them, 10 borderline community disputes or informal C2C exchanges).
   - **Label Provenance (`labelSource: "provisional_policy_curated"`):** All 100 labels are curated according to the VeggiePal moderation policy (`ModerationService.java` system prompt and confidence threshold `>= 0.85` for `REJECTED`, otherwise `REVIEW_REQUIRED`). They are explicitly documented as **provisional policy-aligned ground truth**; final production sign-off requires independent multi-annotator human review. Model-generated outputs are never used as ground-truth labels.

---

## 4. Execution Protocol

1. **Dynamic Authentication (Zero Hardcoded Secrets):**
   - The runner (`scripts/run_benchmark.mjs`) authenticates dynamically against `POST /api/auth/login` using environment variables (`BENCHMARK_USER_EMAIL`, `BENCHMARK_USER2_EMAIL`, `BENCHMARK_ADMIN_EMAIL`, `BENCHMARK_PASSWORD`) and holds short-lived JWTs strictly in memory without logging or persisting tokens.
   - To respect the `100` daily requests/feature/user local testing quota (`LocalTestQuotaPolicy`) without altering production quota logic, the 100 moderation requests + warm-ups are distributed round-robin across the 3 seeded test accounts (`user@veggiepal.com`, `user2@veggiepal.com`, `admin@veggiepal.com`, ~34 requests each).
2. **Idle Baseline Sampling:**
   - Before any inference request is sent, 3 consecutive snapshots of `docker stats --no-stream` (`veggiepal-local-ai-llama-1` and `veggiepal-prm-ai-service`) and `nvidia-smi` are recorded (`IDLE_1`..`IDLE_3`).
3. **Cold-Start / Warm-Up Separation:**
   - One warm-up request per feature (`WARMUP_CHAT`, `WARMUP_REC`, `WARMUP_MOD`, `WARMUP_MP`) is executed and recorded under phase `COLD_WARMUP` before measured runs begin. Warm-up latencies are reported separately in `summary.csv` (`cold_warmup_ms`) and excluded from warm distribution percentiles.
4. **Sequential Measured Execution:**
   - Because `llama.cpp` is configured with `--parallel 1` (1 inference slot) to fit within the 4 GB VRAM budget on the Quadro T2000, all 150 measured requests (20 Chat + 10 Meal Plan + 20 Recommendation + 100 Moderation) are executed sequentially.
5. **Dual-Layer Timing Collection:**
   - **API Gateway Layer:** End-to-end HTTP round-trip latency (`api_latency_ms`) is timed from client request dispatch to full JSON response receipt at `http://localhost:9080`.
   - **Service & Provider Layer:** After each Gateway request, `ai-service` usage logs (`/api/ai/admin/monitoring/logs/search`) are queried to record exact provider call latency (`model_inference_ms`), `prompt_tokens`, and `completion_tokens`.
   - **Direct `llama.cpp` Engine Layer:** Because `LocalAiClient` maps OpenAI-compatible `choices` and `usage` fields, the runner also executes 6 direct probes against `http://127.0.0.1:8088/v1/chat/completions` (`PROBE_CHAT_1..2`, `PROBE_MOD_1..2`, `PROBE_REC_1`, `PROBE_MP_1`) to capture internal `llama.cpp` `timings` (`prompt_ms`, `prompt_per_second`, `predicted_ms`, `predicted_per_second`).
6. **Low-Concurrency Stress Check:**
   - A controlled 2-request simultaneous test (`CONCURRENCY_2`) is executed against `/api/ai/moderation/check` to verify that `llama.cpp`'s single-slot queue serializes concurrent arrivals cleanly without HTTP 500 errors or GPU OOM.
7. **Post-Benchmark Cleanup:**
   - All temporary chat conversations created during the run are deleted via `DELETE /api/ai/chat/conversations/{id}`.
   - All moderation cases queued as `REVIEW_REQUIRED` for synthetic benchmark author IDs (`>= 990000`) are dismissed via `DELETE /api/ai/admin/moderation/{id}` so the admin review queue remains clean.

---

## 5. Hardware Monitoring & WSL2 Measurement Limitations

Hardware metrics are collected via two mechanisms:
- **Between-Request Snapshots (`run_benchmark.mjs`):** Sampled immediately after warm-up and periodic measured requests. Because `docker stats --no-stream` and `nvidia-smi` take ~0.8–1.2 seconds to return on Windows + WSL2, snapshots taken *after* an HTTP response completes show instantaneous GPU utilization (`utilization.gpu`) returning toward `0%` while GPU power draw (`6–11 W` vs `2.36 W` idle) and temperature (`62–65 °C` vs `51 °C` idle) remain elevated.
- **Concurrent In-Flight Sampling (`sample_inflight_hardware.mjs`):** Polls `docker stats --no-stream` and `nvidia-smi` every `300 ms` *while* a 450-token generation request is actively streaming inside `llama.cpp` (`INFLIGHT_1`..`INFLIGHT_7` in `hardware.csv`). This captures true active compute load (`412%–466%` container CPU across 6 cores, `27%–38%` GPU SM utilization, and `13.55–24.22 W` GPU power draw).
- **WSL2 WDDM VRAM Reporting Limitation:** Under Windows 11 + WSL2 with WDDM 3.1 shared virtual memory, `nvidia-smi` reports static device allocation (`745 MiB / 4096 MiB`) across both idle and active inference states because `llama.cpp` pre-allocates the 16 offloaded CUDA layers and KV cache at container startup (`--n-gpu-layers 16 --ctx-size 2048`). The remaining layers and host buffers reside in WSL2 container RAM (`2,610–2,854 MiB`).

---

## 6. Reproducing the Benchmark

```powershell
# 1. Run unit tests for evaluation metrics and dataset schema validation
cd D:\project\VeggiePal-Microservice\backend
node --test ai-inference/benchmark/scripts/test_benchmark.mjs

# 2. Run the full benchmark against the running Docker stack
node ai-inference/benchmark/scripts/run_benchmark.mjs --mode full

# 3. (Optional) Run a fast smoke check (3 chat, 3 mealplan, 3 rec, 9 moderation)
node ai-inference/benchmark/scripts/run_benchmark.mjs --mode smoke

# 4. Sample concurrent in-flight GPU/CPU utilization during active token generation
node ai-inference/benchmark/scripts/sample_inflight_hardware.mjs
```

