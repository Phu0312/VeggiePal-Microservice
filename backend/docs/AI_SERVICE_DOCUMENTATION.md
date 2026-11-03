# AI service

The AI service exposes chat, meal planning, recommendations, and text moderation. All four call `LocalAiClient`, which sends OpenAI-compatible `POST /v1/chat/completions` requests to one local llama.cpp server running Qwen2.5-1.5B-Instruct. There is no commercial inference provider or provider selection setting.

## Configuration

| Property | Environment variable | Default |
|---|---|---|
| `ai.local.base-url` | `AI_LOCAL_BASE_URL` | `http://llama:8080/v1` |
| `ai.local.model` | `AI_LOCAL_MODEL` | `qwen2.5-1.5b-instruct` |
| `ai.local.connect-timeout` | `AI_LOCAL_CONNECT_TIMEOUT` | `10s` |
| `ai.local.read-timeout` | `AI_LOCAL_READ_TIMEOUT` | `120s` |

The Docker AI service uses `http://llama:8080/v1` on the private Compose network. For a host process, set `AI_LOCAL_BASE_URL=http://127.0.0.1:8088/v1`. The host port is bound to loopback. Model weights are local and are not committed.

## Public API

Requests enter through the gateway on port 9080 with `/api` before the service path. Existing JWT rules and request/response DTOs remain in the controllers.

| Feature | Service path | Behavior |
|---|---|---|
| Guest chat | `POST /ai/chat/guest-sessions`, `POST /ai/chat/guest` | Guest session, IP quota, local reply |
| Member chat | `POST /ai/chat`, `GET /ai/chat/conversations`, `GET/DELETE /ai/chat/conversations/{id}` | JWT, history, quota, persistence |
| Meal planning | `POST /ai/meal-plans` and existing plan edit, version, favorite, nutrition target and quota routes | Local model proposes real recipe IDs; Java validates vegan, allergen and nutrition constraints |
| Recommendations | `GET /ai/recommendations` | Ranks fetched blog and recipe candidates, validates returned IDs and filters recipe allergens |
| Moderation | `POST /ai/moderation/check`, admin review routes under `/ai/admin/moderation` | Stores decisions and queues uncertain or failed classifications for manual review |
| Usage | `GET /ai/quotas/me`, admin monitoring routes under `/ai/admin/monitoring` | Existing quotas, token counts, latency and model accounting |

Video transcription and video recipe extraction endpoints have been removed. Existing database records and migration history are retained.

## Failure behavior

When llama.cpp is unavailable, the local client raises error 6004 with HTTP 503 and a generic user-facing message. Chat, meal planning and recommendations do not call another provider. Meal planning can use its deterministic planner for invalid or incomplete generated output; it returns 503 when the local inference server is unavailable. Moderation records `REVIEW_REQUIRED` for failed inference and never approves by default. Usage failures remain logged.

## Local checks

Run `docker compose --env-file .env.example config --quiet` and `docker compose -f ai-inference/compose.local-ai.yml config --quiet` from `backend`. Start the local stack using `SELF_HOSTED_AI_SETUP.md`; then run `ai-service/./mvnw.cmd test` and exercise the four existing gateway routes with valid credentials and application data. No VPS or cloud deployment is part of the local setup.
