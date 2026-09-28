# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

VeggiePal backend: Spring Boot microservices (Java 21, Spring Boot 4.1.1). There is **no parent/aggregator POM**. The architecture consists of **8 independent, single-responsibility microservices** plus **1 API Gateway**:
1. `identity-service` (Port 18081, DB `veggiepal_identity`): User Auth, Profile Management & Admin Users
2. `nutrition-service` (Port 18082, DB `veggiepal_nutrition`): Health Records, BMI calculation & Allergens
3. `blog-service` (Port 18083, DB `veggiepal_blog`): Community Blog Posts, Categories, Comments & Votes
4. `meal-service` (Port 18084, DB `veggiepal_meal`): Vegan Recipes, Pantry Ingredients & 7-Day Meal Plan Generator
5. `ai-service` (Port 18085, DB `veggiepal_ai`): AI Nutrition Chatbot (Guest trial & Auth), AI Operations Logging & Admin Metrics
6. `restaurant-service` (Port 18086, DB `veggiepal_restaurant`): Vegan Restaurants Catalog & Haversine GPS Nearby Search
7. `video-service` (Port 18087, DB `veggiepal_video`): Cooking Videos Catalog & AI Video Summarization
8. `moderation-service` (Port 18088, DB `veggiepal_moderation`): Keyword Filter Engine & Admin Moderation Review Queue
9. `api-gateway` (Port 18080): Unified Routing & Aggregated Swagger UI

Each service is a separate Maven project with its own wrapper, so run Maven commands from inside the service directory. Only `api-gateway` uses `application.yaml`; every other service uses `application.properties`.

## Workflow and skills

Four skill families are installed for this project. Pick by situation — do not load all four for every task. They are local plugins; a session without one simply skips that step.

| Situation | Skill |
|---|---|
| Starting a spec or feature, or any change in behaviour | `superpowers:brainstorming` — design and the user's approval before any code |
| Spec approved and the work has several steps | `superpowers:writing-plans`, then `superpowers:subagent-driven-development` to execute it |
| Writing production code | `superpowers:test-driven-development` |
| A bug, a failing test, unexpected behaviour | `superpowers:systematic-debugging` before proposing a fix |
| About to say "done", commit or push | `superpowers:verification-before-completion` — run the commands and read the output |
| Feature finished | `superpowers:requesting-code-review`, then `superpowers:finishing-a-development-branch` |
| "Have we solved this before?", or resuming work from an earlier session | `claude-mem:mem-search` |
| Finding a function, class or call site without reading whole files | `claude-mem:smart-explore` |
| Architecture or cross-service questions ("what touches X", "how does Y reach Z") | `graphify` — `graphify query "..."` when `graphify-out/` exists. Building the graph costs an extraction pass, so run `/graphify` for a spec that spans several services, and use `smart-explore` for a one-off lookup |
| Deciding how much to build, or a design or diff that feels heavy | `ponytail` in `lite` mode (`/ponytail lite`). `ponytail:ponytail-review` on a diff, `ponytail:ponytail-audit` on the repo |

**Starting a spec:**
1. `claude-mem:mem-search` for earlier work and decisions in that area.
2. Read the team task sheet rows for the feature (Google Sheet "PHÂN CHIA TASK", tab `TASK`). Its BUSINESS RULE column is the contract the frontend builds against and wins where it differs from the SRS. blog-service was designed from the SRS alone, and six rules had to be reworked after the fact.
3. Map the code the spec touches: `graphify query` if the graph exists, otherwise `smart-explore`.
4. `superpowers:brainstorming` → spec in `docs/superpowers/specs/` → the user approves it.
5. `superpowers:writing-plans` → plan in `docs/superpowers/plans/`.

**How they fit together:**
- **superpowers owns the process; ponytail only shapes the solution.** ponytail's "never stall on an answer you can default" does not override brainstorming's approval gate, TDD, verification, or the `BlogServiceIntegrationTests` gate below. Use it to cut scope and speculative abstractions, never to skip a step.
- **`lite`, not ponytail's default `full`.** Features here are fixed by the task sheet and graded against it; `full` questions whether a task needs to exist at all, which is the wrong question for a required feature. `lite` builds what is asked and names the lazier alternative in one line.
- **Plan and execute with superpowers, not claude-mem's `make-plan` / `do`.** Both pipelines exist; specs and plans in this repo live under `docs/superpowers/`, so use one.

## Commands

```bash
# Start MySQL (host 3307, root/12345) and MinIO (API 19000, console 19001, minioadmin/minioadmin).
# minio-init creates the public-read buckets veggiepal-avatars, veggiepal-blog-thumbnails, veggiepal-videos.
docker compose up -d

# Run services (from their directory; on Windows use mvnw.cmd or Git Bash)
cd identity-service && ./mvnw spring-boot:run    # :18081
cd nutrition-service && ./mvnw spring-boot:run   # :18082
cd blog-service && ./mvnw spring-boot:run        # :18083
cd meal-service && ./mvnw spring-boot:run        # :18084
cd ai-service && ./mvnw spring-boot:run          # :18085
cd restaurant-service && ./mvnw spring-boot:run  # :18086
cd video-service && ./mvnw spring-boot:run       # :18087
cd moderation-service && ./mvnw spring-boot:run  # :18088
cd api-gateway && ./mvnw spring-boot:run         # :18080

# Build / test (run inside any service)
./mvnw clean test-compile -DskipTests
./mvnw test
```

**Database gotchas:**
- `docker-compose.yml` mounts `./db-init` which runs `01-create-databases.sql` to initialize all 8 databases: `veggiepal_identity`, `veggiepal_nutrition`, `veggiepal_blog`, `veggiepal_meal`, `veggiepal_ai`, `veggiepal_restaurant`, `veggiepal_video`, `veggiepal_moderation`.
- Tables come from Hibernate `ddl-auto=update`; there are no migrations.
- Catalogs seed on start:
  - `nutrition-service`: seeds allergens from `data.sql`.
  - `meal-service`: seeds 18 vegan recipes from `data.sql`.
  - `restaurant-service`: seeds 6 vegan restaurants with GPS coords from `data.sql`.
- `minio-init` creates three public-read buckets: `veggiepal-avatars`, `veggiepal-blog-thumbnails`, `veggiepal-videos`.

## Architecture

### Request flow through the gateway

`api-gateway` uses **Spring Cloud Gateway Server WebMVC** (servlet-based, not the reactive WebFlux gateway). Routes are defined in `api-gateway/src/main/resources/application.yaml`, and downstream URIs are hardcoded `localhost` ports (no service discovery):

- `/api/auth/**`, `/api/users/**`, `/api/admin/users/**` → identity-service (18081)
- `/api/nutrition/health-records/**`, `/api/nutrition/allergies/**` → nutrition-service (18082)
- `/api/blogs/**`, `/api/categories/**`, `/api/comments/**` → blog-service (18083)
- `/api/nutrition/recipes/**`, `/api/nutrition/me/ingredients/**`, `/api/nutrition/meal-plans/**`, `/api/meal/**` → meal-service (18084)
- `/api/ai/**`, `/api/admin/ai/**` → ai-service (18085)
- `/api/restaurants/**` → restaurant-service (18086)
- `/api/videos/**` → video-service (18087)
- `/api/admin/moderation/**`, `/api/moderation/**` → moderation-service (18088)

- Do not set `spring.servlet.multipart.*` in api-gateway: the gateway disables multipart parsing on its own so file uploads stream through to the service.
- Controllers in a service map paths **without** the `/api` prefix (handled by `StripPrefix=1`), and security matchers use the un-prefixed paths.
- CORS is configured **only** in the gateway (`CorsConfig`, allowing `http://localhost:*` with credentials). The frontend must go through the gateway.

### Swagger aggregation

The gateway serves a combined Swagger UI at `http://localhost:18080/swagger-ui.html`. The pieces fit together like this:
1. Gateway routes `/<service-name>/v3/api-docs/**` with `StripPrefix=1` forward to each service's `/v3/api-docs`.
2. Entries under `springdoc.swagger-ui.urls` in `api-gateway/src/main/resources/application.yaml` point at each service.
3. Each service's `OpenApiConfig` sets the server URL to `/api`, so "Try it out" requests go back through the gateway.

### identity-service conventions

- **Layering:** `controller` → `service` → `repository` (Spring Data JPA). `mapper` holds MapStruct interfaces (`componentModel = "spring"`), and `dto/request` and `dto/response` hold the DTOs.
- **Dependency injection style:** `@RequiredArgsConstructor` + `@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)` with fields declared bare (Lombok adds `private final`).
- **Response envelope:** every endpoint returns `ApiResponse<T>` (`code` defaults to `1000` on success, plus `message` and `result`; null fields are omitted).
- **Errors:** throw `new AppException(ErrorCode.X)`. `GlobalExceptionHandler` maps it to `ApiResponse` using the enum's code and HTTP status. Add new cases to the `ErrorCode` enum.
- **Validation messages are `ErrorCode` enum names**, e.g. `@NotBlank(message = "EMAIL_REQUIRED")`. The handler resolves them with `ErrorCode.valueOf(...)`, and an unknown name falls back to `INVALID_KEY`. A `{min}` placeholder in the enum message is filled from the constraint's `min` attribute. The handler only looks at the first field error.
- **MapStruct + Lombok:** both annotation processors are listed in `maven-compiler-plugin` (Lombok first). When mapping a request DTO onto an entity, explicitly `@Mapping(target = ..., ignore = true)` any fields the service sets itself (see `UserMapper`).
- Emails are normalized with `trim().toLowerCase()` before lookup or storage.
- **Error code ranges:** shared codes keep the same number in every service (1001, 1008, 1009, 1018 `INVALID_REQUEST`, 9999); identity-service uses 10xx, nutrition-service uses 20xx.
- **Avatar storage:** `FileStorageService` (S3 API via AWS SDK v2; MinIO locally). Configured with `storage.s3.*` / `S3_*` env vars. Uploads are validated by content type **and** magic bytes (`ImageTypeDetector`).
- **Controller slice tests:** `@WebMvcTest(X.class)` + `@Import({SecurityConfig.class, JwtConfig.class, SecurityExceptionHandler.class})` + `@MockitoBean` for the service; authenticate with `SecurityMockMvcRequestPostProcessors.jwt().jwt(t -> t.claim("userId", 7L))`.

### nutrition-service

Same conventions as identity-service, under package `com.veggiepal.nutrition` (its shared classes are copies, not a shared module). Controllers map `/nutrition/**`. It owns health records (height/weight history; BMI is computed server-side with HALF_UP to 1 decimal) and allergies (seeded `allergens` catalog + `user_allergies`). It stores `userId` from the JWT and never calls identity-service.

### blog-service

Same conventions as identity-service, under package `com.veggiepal.blog` (shared classes are copies, not a shared module). Controllers map `/blogs/**`, `/categories/**`, `/comments/**`. It owns blogs, the category tree, comments and votes, and stores only `author_id` from the JWT — the frontend resolves display names through identity-service's `GET /users/batch`.

- **Comments and votes are polymorphic** (`target_type` + `target_id`) so videos slot in without a migration. `TargetType.VIDEO` and `CommentStatus.PENDING` already exist in the enums for the same reason — `ddl-auto=update` cannot add an ENUM constant later.
- **`SecurityConfig.PUBLIC_ENDPOINTS` here is method-aware** and its path variables are constrained to digits (`/blogs/{id:[0-9]+}`). Without the digits, `/blogs/me` matches `/blogs/{id}`, becomes public, loses its bearer token and then 401s forever. `SecurityConfigTest` guards this.
- **`blogs.vote_score` is denormalized**, kept in sync inside the vote transaction with `UPDATE blogs SET vote_score = vote_score + :delta`. The delta is just `new value - old value`, treating "no vote" as 0.
- **Voting is `POST /blogs/{id}/vote` and toggles**: the same value a second time takes the vote back (the task sheet's heart button sends `1` on every click), the opposite value switches it. It is POST, not PUT, because it is not idempotent. `DELETE /blogs/{id}/vote` still removes explicitly.
- Admin has no separate controller: ownership checks widen to `ROLE_ADMIN` on blog and comment `PUT`/`DELETE`. **An admin deleting someone else's blog bans it** (`ContentStatus.BANNED`) rather than removing the row: hidden from every public read, still listed in the owner's `GET /blogs/me`. `BANNED` is terminal — `updateBlog` refuses it, because editing re-runs moderation and would otherwise let the owner lift the ban. An owner deleting their own post is a real delete.
- **Category names are unique across the whole tree**, not per parent, enforced by the service and by `uk_categories_name`. The column is `utf8mb4_0900_as_ci` on purpose: MySQL's default `ai_ci` ignores diacritics, so "Che", "Chè" and "Chế" would collide both in the lookup and in the index.

### meal-service (Port 18084, DB `veggiepal_meal`)

Package `com.veggiepal.meal`. Manages recipes, pantry ingredients (`user_ingredients`), and 7-day meal plan generation (`meal_plans`).
- Dual-mapped endpoints for 100% backward compatibility: `/nutrition/recipes/**` & `/meal/recipes/**`, `/nutrition/me/ingredients/**` & `/meal/me/ingredients/**`, `/nutrition/meal-plans/**` & `/meal/meal-plans/**`.
- Seeds 18 vegan recipes from `data.sql`.
- Communicates with `nutrition-service` via REST (`http://localhost:18082/nutrition/allergies/user/{userId}`) to exclude user allergens during meal plan generation.

### ai-service (Port 18085, DB `veggiepal_ai`)

Package `com.veggiepal.ai`. Manages AI Nutrition Chatbot (`/ai/chat/**`) and Admin AI Operations Monitoring (`/admin/ai/**`).
- Guest AI trial support (`POST /ai/chat/guest` with `X-Guest-Id` header) with 3-question quota enforcement.
- Authenticated multi-turn chat sessions (`ChatConversation`, `ChatMessage`).
- AI operations logging (`ai_operation_logs`) and metrics (`GET /admin/ai/metrics`).

### restaurant-service (Port 18086, DB `veggiepal_restaurant`)

Package `com.veggiepal.restaurant`. Manages vegan restaurants catalog (`/restaurants/**`).
- Seeds 6 vegan restaurants across Hanoi, Da Nang, and Ho Chi Minh City from `data.sql`.
- Haversine GPS distance calculation for `/restaurants/nearby` with radius filter and tag compatibility ranking.

### video-service (Port 18087, DB `veggiepal_video`)

Package `com.veggiepal.video`. Manages cooking videos catalog and AI summarization (`/videos/**`).
- CRUD for vegan cooking videos with difficulty levels and durations.
- AI Video Summarization (`POST /videos/{id}/summarize`) extracting dish summary, key ingredients, steps, and nutrition highlights.

### moderation-service (Port 18088, DB `veggiepal_moderation`)

Package `com.veggiepal.moderation`. Manages automated content filtering and admin review queue (`/admin/moderation/**`, `/moderation/check`).
- Rule-based keyword filtering engine detecting profanity, prohibited terms, and non-vegan ingredients (meat, fish, poultry).
- Admin moderation review queue (`GET /admin/moderation/queue`, `POST /admin/moderation/{id}/review`).

### Auth (JWT)

- identity-service issues tokens in `JwtService`: HS256 (explicit), subject = email, claims `userId` and `role`, 24h expiry.
- Every service validates tokens as an OAuth2 Resource Server (`JwtConfig` builds a `NimbusJwtDecoder` with the same secret and HS256). The secret is `jwt.secret=${JWT_SECRET:...}` and must be identical in every service.
- `SecurityConfig.PUBLIC_ENDPOINTS` is the single list used for both `permitAll` and a `BearerTokenResolver` that ignores the Authorization header on public paths. Without it, a stale token would make `/auth/login` return 401.
- 401/403 are written by `SecurityExceptionHandler` as `ApiResponse` (1008/1009), because filter-chain errors never reach `@ControllerAdvice`.
- Controllers take `@Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt` and call `CurrentUser.id(jwt)`. Never take the user id from the body or the path.
- Tokens stay valid until they expire (no revocation, even after a password change).
- **`@PreAuthorize` trap:** a method-security denial (`AuthorizationDeniedException`, a subclass of `AccessDeniedException`) is thrown by the AOP proxy *while the handler is being invoked*, not in the filter chain, so the catch-all `@ExceptionHandler(Exception.class)` in `GlobalExceptionHandler` catches it first and turns a 403 into a 500. blog-service (the first service to use `@PreAuthorize`, on `CategoryController`) works around this with an `@ExceptionHandler(AccessDeniedException.class)` that just rethrows, letting it propagate to `SecurityExceptionHandler`. identity-service and nutrition-service have the same catch-all and no such handler — the moment either adds `@PreAuthorize`, add this rethrow-handler first.
- A missing required query parameter (`MissingServletRequestParameterException`) maps to 400/`INVALID_REQUEST` in identity-service and blog-service's exception handlers, not the 500 a plain catch-all would give it.
