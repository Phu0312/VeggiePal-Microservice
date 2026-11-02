# Self-hosted AI setup

The four text features use one llama.cpp server. Video transcription and extraction still use Groq and require `GROQ_API_KEY`.

## Model

Download [Qwen2.5-1.5B-Instruct-GGUF](https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF), file `qwen2.5-1.5b-instruct-q4_k_m.gguf` (about 1.12 GB, Apache 2.0). From `backend` in PowerShell:

```powershell
New-Item -ItemType Directory -Force ai-inference/models
curl.exe -L --fail --output ai-inference/models/qwen2.5-1.5b-instruct-q4_k_m.gguf https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf
```

Check the downloaded file size and its SHA-256 checksum against the model repository before use. Model weights stay outside Git.

## GPU deployment

For a fresh deployment, set the usual backend `.env` values, then from `backend`:

```powershell
docker compose up -d mysql
docker compose -f ai-inference/compose.local-ai.yml up -d
curl.exe http://localhost:8088/health
docker compose build ai-service
docker compose up -d
```

The first command creates `veggiepal-prm-backend` if it does not exist. The backend Compose project owns this network and the inference Compose project joins it as an external network. Docker resolves `llama` on that network. The main Compose file sets `AI_LOCAL_BASE_URL=http://llama:8080/v1`, pins all four text providers to `local`, and passes the `AI_LOCAL_MODEL` alias used by llama.cpp. A Spring Boot process started directly on Windows uses `http://localhost:8088/v1`. Start ai-service from its directory with `./mvnw.cmd spring-boot:run`. The API gateway remains on host port 9080.

For an existing stack, inspect the network before restarting only the AI container:

```powershell
docker inspect veggiepal-prm-ai-service veggiepal-local-ai-llama-1 --format '{{.Name}} {{json .NetworkSettings.Networks}}'
docker compose config --quiet
docker compose -f ai-inference/compose.local-ai.yml config --quiet
docker compose build ai-service
docker compose up -d --no-deps --force-recreate ai-service
docker compose ps ai-service
```

The backend network survives container recreation. After both Compose projects have been removed, `docker network rm veggiepal-prm-backend` removes the unused network.

The default is 2,048 context tokens, one slot, batch size 256 and 16 GPU layers. Adjust `LLAMA_GPU_LAYERS` after checking free VRAM with `nvidia-smi`; lower the layer count if startup or generation runs out of memory. Q4_K_M weights are about 1.12 GB, but the runtime also needs KV cache, compute buffers and driver memory. The default context can be too small for long meal-plan prompts. Increase `LLAMA_CTX_SIZE` only after checking memory, or reduce prompt size.

## CPU fallback

```powershell
docker compose -f ai-inference/compose.local-ai.yml -f ai-inference/compose.cpu.yml up -d
```

The CPU overlay selects the `server` image and zero GPU layers. Check `docker compose -f ai-inference/compose.local-ai.yml -f ai-inference/compose.cpu.yml config` before startup. CPU inference latency is hardware dependent.

## Provider selection

`AI_CHAT_PROVIDER`, `AI_MEAL_PROVIDER`, `AI_RECOMMENDATION_PROVIDER` and `AI_MODERATION_PROVIDER` default to `local`. Setting one explicitly to `groq` routes only that feature to Groq. A local failure never triggers a Groq request. Video always calls `GroqClient`; it does not read these feature switches. The configured timeouts are `AI_LOCAL_CONNECT_TIMEOUT=10s` and `AI_LOCAL_READ_TIMEOUT=120s`.

The Docker stack pins these four switches to `local`; `.env` cannot override them inside its AI container. Both Compose projects read the same `AI_LOCAL_MODEL` alias. Check effective values with `docker compose exec ai-service printenv AI_LOCAL_BASE_URL AI_LOCAL_MODEL AI_CHAT_PROVIDER AI_MEAL_PROVIDER AI_RECOMMENDATION_PROVIDER AI_MODERATION_PROVIDER`.

## Feature smoke tests

Obtain a valid JWT through `POST http://localhost:9080/api/auth/login` with `{"email":"<account email>","password":"<account password>"}`. The token is returned as `result.accessToken`. Then send the existing chat DTO through the gateway:

```powershell
$token = '<access token returned by login>'
$body = @{ message = 'Gợi ý một bữa ăn chay giàu protein bằng tiếng Việt.' } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri 'http://localhost:9080/api/ai/chat' -Headers @{ Authorization = "Bearer $token" } -ContentType 'application/json; charset=utf-8' -Body ([System.Text.Encoding]::UTF8.GetBytes($body))
docker compose logs --tail 100 ai-service
docker compose -f ai-inference/compose.local-ai.yml logs --tail 100 llama
```

The request has `message` and optional `conversationId` fields. A successful response contains `result.answer`, `result.conversationId`, and `result.remainingRequests`. Check the llama.cpp logs and the AI usage log's model value to confirm local routing. `docker compose exec ai-service curl --fail --silent --show-error http://llama:8080/health` checks connectivity from the AI container.

Exercise the four text features with a valid account and running dependencies: chat with a Vietnamese nutrition question; meal planning with a complete profile, allergens, and available recipes; recommendations backed by recipe and blog candidates with allergy filtering; moderation with normal, violating, and ambiguous content, plus unavailable inference to check manual review. The latter cases use the existing policies and request DTOs.

Use a valid JWT in `$token` and the gateway host port 9080. Guest chat first needs `POST /api/ai/chat/guest-sessions`, then `POST /api/ai/chat/guest`. Signed-in endpoints are `POST /api/ai/chat`, `POST /api/ai/meal-plans`, `GET /api/ai/recommendations?interest=đậu`, and `POST /api/ai/moderation/check`. Request DTOs are in the corresponding controller and DTO classes. Meal planning also requires recipe and nutrition services and a complete user profile. Moderation uses the existing BLOG, VIDEO and COMMENT content types. Run `./mvnw.cmd test` from `ai-service` for automated checks.
