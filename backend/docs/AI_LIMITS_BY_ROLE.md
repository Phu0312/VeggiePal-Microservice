# AI limits by role

The four AI features use local Qwen2.5-1.5B-Instruct through llama.cpp. No commercial AI key or remote inference provider is configured. Quotas are enforced by the AI service before inference and usage is recorded with token counts, model and latency.

## Production quotas

| User | Chat | Meal plans | Other AI features |
|---|---:|---:|---|
| Guest | 3 requests per IP per day, after creating a guest session | Requires sign in | Requires sign in |
| FREE | 5 per day | 2 per calendar month | Text token budget applies |
| PLUS | 20 per day | 8 per calendar month | Text token budget applies |
| PRO | 50 per day | 20 per calendar month | Text token budget applies |

Guest sessions last 24 hours and are limited to 3 sessions per IP per day. The default daily text token budget is 50,000 tokens. `GET /ai/quotas/me` returns the current member's chat and meal plan balances. The subscription plan values come from payment-service's `PlanCatalogInitializer`; if its lookup fails, the AI service applies FREE limits. The optional local test quota mode has separate feature request and token limits and is disabled by default.

## Failure policy

Quota exhaustion is error 6003 (HTTP 429). Unavailable local inference is error 6004 (HTTP 503) with a generic response. Chat, meal planning and recommendations have no remote provider fallback. Moderation failures become `REVIEW_REQUIRED` and wait for administrator review. Meal planning may use its deterministic planner for invalid generated content, but an unavailable local inference server returns 503.

Video transcription and video recipe extraction quotas and endpoints have been removed; historical database records and migrations remain intact.

See `ai-service/src/main/resources/application.properties`, `SELF_HOSTED_AI_SETUP.md`, and `docs/PRM_CAPSTONE.md` for current settings and workflows.
