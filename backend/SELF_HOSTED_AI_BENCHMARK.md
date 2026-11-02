# Self-hosted AI benchmark

## 1. Automated Benchmark & Quality Evaluation Suite (`ai-inference/benchmark/`)

The repository includes a reproducible end-to-end benchmark and quality evaluation suite under `backend/ai-inference/benchmark/` that authenticates dynamically via environment variables (never hardcoding JWTs), evaluates all four self-hosted AI features (`CHAT`, `MEAL_PLAN`, `RECOMMENDATION`, `MODERATION`), collects direct `llama.cpp` engine timings (`prompt_ms`, `predicted_per_second`), samples Docker and NVIDIA GPU hardware metrics (`docker stats` and `nvidia-smi`), and cleans up temporary test records.

### Directory Layout

```text
backend/ai-inference/benchmark/
├── datasets/
│   ├── chatbot.json                      # 20 Vietnamese vegan nutrition & safety prompts
│   ├── mealplan.json                     # 10 meal planning scenarios (feasible, infeasible, allergies, diversity, invalid)
│   ├── recommendations.json              # 20 recommendation requests (limits, interests, allergies, clamping)
│   └── moderation.json                   # 100 labeled Vietnamese samples (APPROVED, REJECTED, REVIEW_REQUIRED)
├── scripts/
│   ├── evaluate_quality.mjs              # Quality rubrics, latency percentiles, and confusion matrix calculator
│   ├── run_benchmark.mjs                 # Main benchmark runner (Gateway + direct llama.cpp + hardware monitoring)
│   ├── sample_inflight_hardware.mjs      # 300ms in-flight polling of CPU/RAM/GPU during active token generation
│   └── test_benchmark.mjs                # Unit tests for datasets and evaluation metrics
├── results/
│   ├── requests.csv                      # Per-request latency, token counts, tok/s, and pass/fail status
│   ├── hardware.csv                      # Idle, post-request, and in-flight CPU/RAM/GPU/VRAM/power samples
│   ├── summary.csv                       # Aggregated latency (mean, median, P95, max), throughput, and pass rates
│   ├── moderation_confusion_matrix.csv   # 3-class confusion matrix, precision, recall, F1, macro F1, unsafe rate
│   └── detailed_evaluation.json          # Full structured evaluation artifact
└── reports/
    ├── BENCHMARK_METHODOLOGY.md          # Methodology, dataset design, and WSL2 monitoring constraints
    ├── PERFORMANCE_REPORT.md             # Latency, throughput, concurrency, and hardware utilization report
    ├── QUALITY_EVALUATION.md             # Functional quality & moderation classification analysis
    └── PRM_CAPSTONE_AI_BENCHMARK_SECTION.md # Standalone merge-ready section for docs/PRM_CAPSTONE.md
```

### Running the Suite

```powershell
cd D:\project\VeggiePal-Microservice\backend

# Run unit tests
node --test ai-inference/benchmark/scripts/test_benchmark.mjs

# Run full benchmark (162 total requests)
node ai-inference/benchmark/scripts/run_benchmark.mjs --mode full

# Run fast smoke check
node ai-inference/benchmark/scripts/run_benchmark.mjs --mode smoke
```

---

## 2. Legacy Ad-Hoc Runner (`ai-inference/benchmark.py`)

Run `python ai-inference/benchmark.py ai-inference/cases.json results.csv` after starting the backend and inference server. Supply your own `cases.json` using the format below; use a valid JWT or guest session and a real user profile. Do not commit tokens or personal health data.

```json
[
  {"feature":"chat","url":"http://localhost:9080/api/ai/chat","method":"POST","headers":{"Authorization":"Bearer REPLACE"},"body":{"message":"Ăn chay cần chú ý chất gì?"}},
  {"feature":"meal","url":"http://localhost:9080/api/ai/meal-plans","method":"POST","headers":{"Authorization":"Bearer REPLACE"},"body":{"name":"Thực đơn tuần","healthGoal":"Duy trì cân nặng","goalType":"MAINTAIN"}},
  {"feature":"recommendation","url":"http://localhost:9080/api/ai/recommendations?interest=đậu","method":"GET","headers":{"Authorization":"Bearer REPLACE"}},
  {"feature":"moderation","url":"http://localhost:9080/api/ai/moderation/check","method":"POST","headers":{"Authorization":"Bearer REPLACE"},"body":{"contentType":"BLOG","text":"Món đậu hũ này rất ngon."}}
]
```

The script labels the first request per feature `cold_request` and later requests `warm_request`. For detailed measured benchmarks, see `ai-inference/benchmark/reports/PERFORMANCE_REPORT.md` and `ai-inference/benchmark/reports/QUALITY_EVALUATION.md`.
