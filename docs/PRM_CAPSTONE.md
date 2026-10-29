# CAPSTONE PROJECT FINAL REPORT (REPORT 7)

**PROJECT: VEGGIEPAL - A COMPREHENSIVE DIGITAL ECOSYSTEM SUPPORTING 100% VEGAN LIFESTYLE**

- Course Code: PRM393
- Institution: FPT University
- Academic Year: 2025 - 2026

---

## TABLE OF CONTENTS

- Acknowledgement
- Definitions and Acronyms
- I. Project Introduction
  1. Overview
  2. Product Background
  3. Existing Systems & Competitive Analysis
  4. Business Opportunity
  5. Software Product Vision
  6. Project Scope & Limitations
- II. Project Management Plan
  1. Overview & Estimation
  2. Management Approach & Process
  3. Project Deliverables & RACI
  4. Configuration & Source Code Management
- III. Software Requirement Specification (SRS)
  1. Product Overview
  2. User Requirements & Actors
  3. Functional Requirements (FR Matrix)
  4. Non-Functional Requirements
  5. Requirement Appendix & Business Rules
- IV. Software Design Description (SDD)
  1. System Design & Architecture
  2. Database Design (Database-per-Service)
  3. Detailed Design & Sequence Specifications
  4. API Design
- V. Software Testing Documentation
  1. Scope & Test Strategy
  2. Test Environment & Supporting Tools
  3. Test Inventory
  4. Quality Controls Built Into the Design
- VI. Release Package & User Guides
  1. Deliverable Package
  2. System Requirements & Installation Instructions
  3. User Manual & Core Workflows
  4. CI/CD Deployment Process
- VII. Appendix
  1. References
  2. Project Metrics Summary
  3. Results Achieved & Future Development

---

## ACKNOWLEDGEMENT

We would like to express our deepest gratitude to our project supervisor and the lecturers of FPT University for their continuous guidance, technical critiques, and invaluable feedback throughout the development of the VeggiePal project. We also thank our team members for their dedication, collaboration, and discipline in applying modern software engineering practices, microservices architecture, and automated CI/CD to turn this project into an operational platform.

---

## DEFINITIONS AND ACRONYMS

| Acronym / Term | Definition |
|---|---|
| API | Application Programming Interface |
| BMI | Body Mass Index |
| BMR | Basal Metabolic Rate (minimal daily calories needed at rest) |
| CI / CD | Continuous Integration / Continuous Deployment |
| CORS | Cross-Origin Resource Sharing |
| ERD | Entity Relationship Diagram |
| FR / NFR | Functional Requirement / Non-Functional Requirement |
| GPS | Global Positioning System |
| Groq | Cloud inference provider hosting the LLM and speech-to-text models used by ai-service |
| JWT | JSON Web Token (RFC 7519) |
| LLM | Large Language Model |
| PayOS | Payment gateway integrating Vietnamese banking QR code (VietQR) |
| SDD | Software Design Description |
| SRS | Software Requirement Specification |
| ST_Distance_Sphere | MySQL function used by location-service to calculate spherical distance between two coordinates |
| TDEE | Total Daily Energy Expenditure |

---

## I. PROJECT INTRODUCTION

### 1. Overview

#### 1.1. Project Information

- **Project Title:** VeggiePal - Digital Ecosystem Supporting 100% Vegan Lifestyle
- **Project Code:** PRM393_VeggiePal
- **Platform Targets:** Backend microservices (Spring Boot, Java 21), cross-platform mobile app (Flutter), web application (React / Vite)
- **Repository:** Single Git repository (monorepo) containing `/backend`, `/frontend` and `/mobile`

#### 1.2. Project Team

| Full Name | Role | Email | MSSV |
|---|---|---|---|
| Nguyen Xuân Huy | Lecturer |  |  |
| Lê Gia Hưng | Leader | legiahung86@gmail.com | SE192147 |
| Trương Hoàng Phú | Member | hoangphulk2005@gmail.com | SE192049 |
| Phạm Gia Huy | Member | phamgiahuy2707@gmail.com | SE192043 |
| Diệp Khai | Member | aicungduoc49@gmail.com | SE193097 |

### 2. Product Background

Veganism and plant-based nutrition are being adopted rapidly worldwide and in Vietnam, driven by health awareness, environmental concerns and ethical values. Despite this momentum, vegan practitioners face daily hurdles:

1. **Nutritional deficiencies:** Inadequately planned plant-based diets can cause shortages of vitamin B12, bioavailable iron, zinc, essential amino acids and omega-3.
2. **Food allergies:** Heavy reliance on nuts, soy products and wheat gluten creates allergy risks without automated ingredient exclusion.
3. **Information fragmentation:** Mainstream map services do not distinguish pure vegan establishments from vegetarian restaurants serving dairy and eggs.
4. **Lack of a verified community:** Social media recipes often contain hidden animal-derived components (for example gelatin or fish-sauce derivatives).

VeggiePal addresses these challenges through personal health profiling, AI-assisted meal planning, restaurant discovery, a moderated community, and domestic subscription payments.

### 3. Existing Systems & Competitive Analysis

| Evaluation Dimension | HappyCow | MyFitnessPal | Generic Social Networks | VeggiePal |
|---|---|---|---|---|
| Vegan specialization | High (places only) | Low (all food types) | Unmoderated | Vegan-dedicated ecosystem |
| Allergy-aware meal planner | No | Generic calorie counter | No | 7-day plan generated from the user's allergen profile; candidate recipes containing a declared allergen are excluded |
| Available-ingredient input | No | No | No | Optional list of ingredients on hand; recipes that match more of them are ranked first |
| AI nutrition assistant | No | Limited | No | Groq-hosted LLM assistant with server-side quota control |
| Community moderation | Manual reviews | User forums | Keyword filters only | LLM-based moderation check with an admin review queue |
| Integrated local payments | No (foreign subscription) | Credit card only | None | VietQR payments through PayOS |

### 4. Business Opportunity

The plant-based food market in Southeast Asia is growing steadily. By consolidating allergen-aware meal planning, recipe browsing, community blogging, video recipe extraction and a restaurant locator into one microservices backend with a freemium subscription model (FREE / PLUS / PRO, paid through PayOS), VeggiePal targets a high-retention niche audience.

### 5. Software Product Vision

> "To provide every individual practicing or transitioning to a plant-based lifestyle with an intelligent, trustworthy, and comprehensive digital companion that safeguards nutritional adequacy, eliminates allergen hazards, and connects a verified vegan community."

### 6. Project Scope & Limitations

#### 6.1. Major Features (In Scope)

- Stateless authentication and authorization with JWT, opaque refresh-token rotation and revocation, Google sign-in, and 6-digit email OTP password reset and email verification.
- Health profiling: height/weight history with BMI, BMR/TDEE-based nutrition targets, and allergen declarations.
- Social community: blogs, videos, multilevel nested comments and up/down voting on both blogs and videos, and image upload.
- AI-assisted 7-day meal plan (breakfast, lunch and dinner for each day, 21 meals) based on nutrition targets, declared allergens and optional available ingredients, with version history and restoration.
- Recipe catalog with per-serving nutrition calculation, image upload and popular/liked ranking; restaurant keyword search and nearby search using MySQL `ST_Distance_Sphere`.
- AI-driven video recipe extraction: audio extraction with FFmpeg, transcription, and structured recipe extraction.
- AI-assisted content moderation with an administrator review queue.
- Domestic payment processing and subscription management through PayOS VietQR.

#### 6.2. Limitations & Exclusions (Out of Scope)

- The system does not sell or deliver groceries; it provides recipe and ingredient information.
- Barcode scanning is not provided.
- Message streaming and event brokers (Kafka and similar) are not used; they are earmarked for possible future scaling.
- AI features depend on the external Groq cloud API; no AI model is hosted locally.

---

## II. PROJECT MANAGEMENT PLAN

### 1. Overview & Estimation

The project was executed across 15 academic weeks using Scrum-inspired iterations. The work was organised into six work packages:

| Work package | Content |
|---|---|
| 1 | Requirement engineering, domain modelling, initial SRS / SPMP documentation |
| 2 | Core backend foundation, database schemas, Docker containerization, API gateway |
| 3 | Domain services: Identity, Nutrition, Blog, Recipe, Location |
| 4 | AI service integration, LLM-based meal planning, video processing, PayOS payment service |
| 5 | Client applications: React web and Flutter mobile; backend test suites |
| 6 | GitHub Actions CI/CD automation, Docker Compose deployment, final documentation |

### 2. Management Approach & Process

The team combined an iterative Scrum-style workflow with GitFlow-style branching:

- `main`: release branch.
- `dev`: integration branch; every push and pull request targeting `dev` or `main` triggers the GitHub Actions workflow.
- `feat/*`: feature branches merged into `dev` through pull requests.

**Figure II.1. Scrum sprint lifecycle and GitFlow workflow**

```mermaid
flowchart LR
    A["Requirements<br/>(task sheet + SRS)"] --> B["Sprint planning"]
    B --> C["Develop on<br/>feat/* branch"]
    C --> D["Pull request<br/>+ CI (build, test)"]
    D --> E{"CI green and<br/>review approved?"}
    E -- "No" --> C
    E -- "Yes" --> F["Merge into dev"]
    F --> G["Release: merge dev into main"]
    G --> H["Deploy with Docker Compose<br/>(self-hosted runner)"]
```

*Figure II.1 shows one iteration: requirements are planned into a sprint, implemented on a feature branch, validated by a pull request with CI, merged into `dev`, and released from `main`. A failed CI run or review sends the work back to the feature branch.*

**Figure II.2. Branching model**

```mermaid
gitGraph
    commit id: "initial"
    branch dev
    checkout dev
    commit id: "backend base"
    branch "feat/service"
    checkout "feat/service"
    commit id: "implement"
    commit id: "tests"
    checkout dev
    merge "feat/service" id: "PR + CI"
    branch "feat/client"
    checkout "feat/client"
    commit id: "UI"
    checkout dev
    merge "feat/client" id: "PR + CI 2"
    checkout main
    merge dev id: "release" tag: "release"
```

*Figure II.2 shows the branch model: feature branches are merged into `dev` after pull-request checks, and `dev` is merged into `main` for a release.*

### 3. Project Deliverables & RACI Matrix

| Deliverable Item | Backend Eng. | AI Eng. | Mobile Dev. | QA / Web |
|---|---|---|---|---|
| SRS Document (Report 3) | Responsible | Accountable | Consulted | Informed |
| System Design Document (Report 4) | Accountable | Responsible | Consulted | Informed |
| Backend microservices & Docker Compose | Accountable | Responsible | Informed | Consulted |
| AI integration and validation logic | Consulted | Accountable | Informed | Responsible |
| Automated test suites | Accountable | Responsible | Consulted | Responsible |
| Flutter mobile application | Informed | Informed | Accountable | Consulted |
| React web application (user features and admin) | Informed | Informed | Consulted | Accountable |
| Final Project Report (Report 7) | Accountable | Responsible | Responsible | Responsible |

### 4. Configuration & Source Code Management

- **Repository hosting:** GitHub.
- **CI/CD platform:** GitHub Actions (`.github/workflows/ci-cd.yml`).
- **Cloud assets:** Cloudinary stores user avatars, blog thumbnails, recipe images and uploaded videos.
- **Local tunnel:** An Ngrok container tunnels public traffic to `api-gateway:8080` so that PayOS can deliver webhooks to the local deployment. Its inspector UI is published on host port 5041.
- **Secrets:** Stored in `backend/.env` (not committed; template in `backend/.env.example`) or in the `BACKEND_ENV_FILE` repository secret for the deploy job.

---

## III. SOFTWARE REQUIREMENT SPECIFICATION (SRS)

### 1. Product Overview

VeggiePal is a REST-based, API-first microservices platform. The React web application and the Flutter mobile application reach all backend capabilities through a single Spring Cloud Gateway. Services communicate with each other through synchronous REST calls; no event broker is used.

### 2. User Requirements & Actors

Authorization has two roles (`USER`, `ADMIN`) plus unauthenticated guests. Subscription plans (FREE / PLUS / PRO) are not roles; they only define usage quotas.

| Actor | Core responsibilities and privileges |
|---|---|
| Guest | Browse public blogs, videos, recipes (including popular recipes) and the restaurant map/search; create a guest session to try the AI chatbot (3 chat requests per day per IP) |
| USER | Maintain health records and allergens; generate, edit and restore meal-plan versions; inspect remaining AI quotas; use the AI chatbot; publish recipes, blogs, comments, votes and likes; process videos; buy a subscription |
| ADMIN | Manage user accounts (search, lock/unlock status, role assignment), moderate flagged content, take down blogs/videos, manage categories and ingredients, view AI monitoring and payment statistics |
| Subscription plan (FREE / PLUS / PRO) | Defines per-user quotas for AI chat, meal plans and video processing |

**Figure III.1. VeggiePal actors and use cases**

```mermaid
flowchart LR
    G(["Guest"])
    U(["USER"])
    A(["ADMIN"])
    PS(["PayOS"])

    subgraph SYS["VeggiePal system"]
        direction TB
        UC1["Browse blogs and restaurant map"]
        UC2["Guest AI chat (session + daily limit)"]
        UC3["Register / login / Google sign-in"]
        UC4["Manage health record and allergens"]
        UC5["Generate and edit 7-day meal plan"]
        UC6["AI nutrition chat (plan quota)"]
        UC7["Write blogs, comment, vote"]
        UC8["Extract recipe from video"]
        UC9["Buy PLUS / PRO subscription"]
        UC10["Manage users, moderate content and manage categories"]
        UC11["View AI monitoring and payment statistics"]
    end

    G --> UC1
    G --> UC2
    G --> UC3
    U --> UC1
    U --> UC4
    U --> UC5
    U --> UC6
    U --> UC7
    U --> UC8
    U --> UC9
    A --> UC10
    A --> UC11
    UC9 --- PS
```

*Figure III.1 shows what each actor can do. Guests can browse and try the chatbot in a limited way and may register. USER covers the personal features. ADMIN covers moderation and operational dashboards. PayOS is the external system that confirms payments for the subscription use case.*

### 3. Functional Requirements (FR Matrix)

| Req ID | Feature | Responsible service | Description & acceptance criteria |
|---|---|---|---|
| FR-01 | Account & Auth | identity-service | Profile extras: saved favorites (`/users/me/favorites`) and green badges (`/users/me/badges`, derived from profile/email state plus unlocked badges). Registration with BCrypt-hashed passwords (cost 10); newly registered accounts start `ACTIVE` (`emailVerified = false`) and receive a 6-digit email verification OTP (`/auth/send-verification`, `/auth/verify-email`); 6-digit email OTP password recovery (`/auth/forgot-password`, `/auth/verify-otp`, `/auth/reset-password`); login and Google sign-in verify that the account is `ACTIVE` (rejecting `BLOCKED` or non-active accounts with HTTP 403 / error 1021) and issue an HS256 JWT (claims `userId`, `role`, valid 24 hours) together with an opaque refresh token (SHA-256 hashed in `refresh_tokens`, rotated via `/auth/refresh` and revoked on `/auth/logout` or password change); profile update, password change and avatar upload to Cloudinary; each account carries a status (`PENDING`, `ACTIVE`, `INACTIVE`, `BLOCKED`) and a role (`USER`, `ADMIN`). |
| FR-02 | Guest trial usage | ai-service, api-gateway | Public blog and map browsing without login. A guest creates a session with `POST /ai/chat/guest-sessions` (valid 24 hours, at most 3 sessions per IP per day) and sends the returned `guestSession` with each guest chat request. Guest chat is limited to 3 requests per day per IP; when the quota is exceeded the API returns error 6003 with HTTP 429. |
| FR-03 | Blog publishing | blog-service | Markdown blog creation with Cloudinary thumbnail, update, submit for review, and status workflow `DRAFT`, `PENDING`, `PUBLISHED`, `REJECTED`, `BANNED` (admin takedown). Category binding is required. |
| FR-04 | Comments & votes | blog-service | Community extras: leaderboard ranked by published posts and likes, author follow/unfollow (`user_follows`), trending topics from category counts, community stats, video channels (`/videos/channels`), a 7-day check-in challenge persisted in `user_challenges`, and per-video nutrition facts (`/videos/{id}/nutrition`). Multilevel comments (parent/child) with pagination on blogs and videos; one vote per user per target (`+1` / `-1` / `0`) enforced by a unique constraint on both blogs and videos; `blogs.vote_score` and `videos.vote_score` are updated with atomic SQL increments. |
| FR-05 | Recipe & restaurant search | recipe-service, location-service | Recipe browsing, keyword search, Cloudinary recipe image upload, per-serving nutrition calculation (`kcal`, `protein`, `carbs`, `fat`, `fiber` converted across weight, volume, spoon and piece units), recipe likes and popular ranking (`/recipes/popular`, `sort=popular`); ingredient catalog; restaurant keyword search (`/restaurants`, `/restaurants/search`) and nearby GPS search within a requested radius (with optional `keyword` and `veganOnly` filters), ordered by distance computed by MySQL `ST_Distance_Sphere`. |
| FR-06 | 7-day meal planner | ai-service (uses nutrition, recipe, identity) | Generates a 7-day plan with exactly breakfast, lunch and dinner each day. Inputs: the user's allergens and latest health record, a nutrition target (supplied or computed from BMR/TDEE and goal type), preferences, and optional available ingredients. Recipes containing a declared allergen are excluded before generation; recipes matching more available ingredients are ranked first; the LLM proposes the plan from real recipe IDs and the server validates and enriches it. If the LLM call fails, a deterministic planner builds the plan instead. Plans can be edited, replaced per meal, versioned, restored from any historical version (`POST /ai/meal-plans/{id}/versions/{version}/restore`) and favorited; daily food diary, water and exercise tracking and a combined "today" nutrition summary are served by nutrition-service (`/nutrition/me/food-logs`, `/water`, `/daily-activity`, `/daily-summary`); remaining monthly meal-plan and AI quotas are exposed via `GET /ai/meal-plans/quota` and `GET /ai/quotas/me`. |
| FR-07 | AI nutrition chatbot | ai-service | Conversational assistant for plant-based nutrition, with stored conversations and message history for signed-in users and a daily chat quota set by the subscription plan. |
| FR-08 | Video recipe extraction | ai-service, blog-service | Asynchronous video jobs: FFmpeg/FFprobe extract the audio track, a speech-to-text model transcribes it, and an LLM extracts ingredients, steps and nutrition highlights as structured JSON. Default limits: 100 MB and 30 minutes per video. Quota is reserved per job and refunded when a job fails. |
| FR-09 | Category management | blog-service | Two-level category tree (parent/child) of types `FOOD_TYPE` and `RECIPE_TYPE`, managed by administrators. |
| FR-10 | Content moderation | ai-service, blog-service | Content is checked through `POST /ai/moderation/check` (LLM-based, looking for profanity and animal-derived content); results are stored as moderation cases and flagged items appear in an admin review queue (`/ai/admin/moderation`). If the LLM provider or moderation service is temporarily unavailable, submissions fall back to `REVIEW_REQUIRED` (`PENDING`) for manual review instead of failing with 503. |
| FR-11 | Admin operations | identity-service, ai-service, payment-service, blog-service, recipe-service | User administration (`/admin/users`: search/filter, lock/unlock status, role assignment); AI monitoring (usage logs, token consumption, latency, model information); payment summary, statistics, revenue and order listing; moderation queue; category and ingredient management. |
| FR-12 | Payment & subscription quotas | payment-service | PayOS VietQR checkout creates an order and payment link; a signed PayOS webhook marks the order paid and activates the subscription. Plans: FREE (0 VND), PLUS (29,000 VND / 30 days), PRO (59,000 VND / 30 days). Quotas: chat per day 5 / 20 / 50, meal plans per month 2 / 8 / 20, videos per month 0 / 3 / 8. |

### 4. Non-Functional Requirements (NFR)

1. **Performance & scalability:** Services are stateless (JWT), so they can be replicated behind the gateway. List endpoints are paginated and frequent queries are covered by database indexes (for example blog status/publish date, comment target). AI response time depends on the Groq API; ai-service applies a 5-second connect timeout and a 45-second read timeout with limited retries.
2. **Security:** Passwords are hashed with BCrypt (cost 10), and OTP codes and opaque refresh tokens are stored as SHA-256 hashes. JWTs are signed with HS256 and validated by every service as an OAuth2 resource server; refresh tokens are rotated on `/auth/refresh` and revoked on `/auth/logout` or password changes. Inter-service calls that must not be public (for example subscription lookup) use an internal service token. PayOS webhooks are accepted only after signature verification. CORS is configured only at the gateway. Uploaded images are validated by content type and magic bytes. Secrets are supplied through environment variables.
3. **Availability & resilience:** Each service runs in its own container with an HTTP health check, and Docker Compose starts them in dependency order. ai-service falls back to FREE-plan quotas if the payment service cannot be reached, falls back to a deterministic planner if the LLM call fails, and queues moderated content as `REVIEW_REQUIRED` (`PENDING`) when LLM moderation is unavailable.
4. **Data integrity:** Database-per-service isolation with no cross-database foreign keys; user identifiers are stored as plain IDs. Unique constraints protect votes, recipe likes, refresh-token hashes, allergen selections, plan codes and payment order codes. Payment orders are updated under a row lock, and `vote_score` / `like_count` counters are updated with atomic SQL statements.
5. **Maintainability:** Layered code per service (controller, service, repository, DTO/mapper), consistent response envelope and error codes, OpenAPI documentation per service aggregated at the gateway.
6. **Portability:** The entire backend starts with a single Docker Compose command.

### 5. Requirement Appendix & Business Rules

- **BR-01 (Plant-based catalog):** The ingredient and recipe catalog contains plant-based content; each ingredient carries a `vegan` flag and an `allergen` flag.
- **BR-02 (Strict allergen exclusion):** A recipe is excluded from the candidate list for meal planning if it contains an ingredient matching the user's declared allergens. The generated plan is validated again on the server.
- **BR-03 (Guest limits):** A guest session lasts 24 hours; one IP can create at most 3 sessions per day and send at most 3 guest chat requests per day.
- **BR-04 (Content ownership):** Only the author or an administrator may edit or remove content.
- **BR-05 (Idempotent webhook execution):** A payment order that is already `PAID` or `CANCELLED` is not changed or credited again when a duplicate webhook arrives; the amount in the webhook must match the order amount.
- **BR-06 (Quota by plan):** Chat, meal-plan and video usage are limited by the user's active subscription; an expired or unavailable subscription is treated as FREE.

---

## IV. SOFTWARE DESIGN DESCRIPTION (SDD)

### 1. System Design & Architecture

VeggiePal uses a REST-based microservices architecture: seven business services and one API gateway. Clients call only the gateway. Services call each other synchronously through REST where needed, and no message broker is used.

| Service | Container port | Gateway routes | Responsibility |
|---|---|---|---|
| api-gateway | 8080 (host 9080) | — | Routing, CORS, aggregated Swagger UI |
| identity-service | 8081 | `/api/auth/**`, `/api/users/**`, `/api/admin/users/**` | Accounts, login, OTP password reset & email verification, refresh tokens, profile, user administration |
| nutrition-service | 8082 | `/api/nutrition/**` | Health records, BMI, allergen catalog and user allergens |
| blog-service | 8083 | `/api/blogs/**`, `/api/categories/**`, `/api/comments/**`, `/api/videos/**` | Blogs, videos, categories, comments, votes |
| recipe-service | 8084 | `/api/recipes/**`, `/api/ingredients/**` | Recipes (per-serving nutrition, image upload, likes & popular), ingredients, steps |
| location-service | 8085 | `/api/restaurants/**` | Restaurant data, keyword search and nearby search |
| ai-service | 8086 | `/api/ai/**`, `/ai/**` | Chatbot, meal plans, video extraction, moderation, quotas, monitoring |
| payment-service | 8087 | `/api/payments/**`, `/api/subscriptions/**`, `/api/admin/payments/**` | Plans, PayOS orders and webhook, subscriptions, admin payment statistics |

**Figure IV.1. REST-based microservices architecture**

```mermaid
flowchart TB
    subgraph CL["Clients"]
        WEB["React web app"]
        MOB["Flutter mobile app"]
    end

    GW["Spring Cloud Gateway<br/>host port 9080"]
    WEB --> GW
    MOB --> GW

    subgraph SV["Business services"]
        ID["identity-service :8081"]
        NU["nutrition-service :8082"]
        BL["blog-service :8083"]
        RE["recipe-service :8084"]
        LO["location-service :8085"]
        AI["ai-service :8086"]
        PA["payment-service :8087"]
    end

    GW --> ID
    GW --> NU
    GW --> BL
    GW --> RE
    GW --> LO
    GW --> AI
    GW --> PA

    subgraph DB["MySQL 8.4 - one schema per service"]
        D1[("veggiepal_identity")]
        D2[("veggiepal_nutrition")]
        D3[("veggiepal_blog")]
        D4[("veggiepal_recipe")]
        D5[("veggiepal_location")]
        D6[("veggiepal_ai")]
        D7[("veggiepal_payment")]
    end

    ID --> D1
    NU --> D2
    BL --> D3
    RE --> D4
    LO --> D5
    AI --> D6
    PA --> D7

    AI -. "health, allergens" .-> NU
    AI -. "recipes" .-> RE
    AI -. "profile" .-> ID
    AI -. "subscription quotas" .-> PA
    BL -. "moderation check" .-> AI

    subgraph EX["External providers"]
        GQ["Groq (LLM, speech-to-text)"]
        CD["Cloudinary (images, videos)"]
        GO["Google (ID token verification)"]
        PO["PayOS (VietQR payments)"]
    end

    AI --> GQ
    ID --> CD
    BL --> CD
    RE --> CD
    ID --> GO
    PA --> PO
    PO -. "webhook" .-> GW
```

*Figure IV.1 shows that every client request enters through the gateway, which fans out to seven independent services. Each service owns exactly one MySQL schema. Dotted arrows are synchronous REST calls between services (ai-service reads nutrition, recipe, identity and payment data; blog-service asks ai-service to check content). External providers are reached directly by the service that needs them; PayOS reaches the system by sending a webhook to the gateway.*

**Figure IV.2. Docker networking and infrastructure**

```mermaid
flowchart LR
    subgraph HOST["Host machine"]
        BR["Browser / mobile app"]
        P1["localhost:9080"]
        P2["127.0.0.1:4307"]
        P3["127.0.0.1:5041"]
    end

    subgraph NET["Docker network: backend (project veggiepal-prm)"]
        GW["api-gateway :8080"]
        SVC["identity, nutrition, blog, recipe,<br/>location, ai, payment services"]
        MY[("mysql 8.4 :3306")]
        NG["ngrok container"]
    end

    INET(("Internet"))
    PAYOS["PayOS"]

    BR --> P1 --> GW
    GW --> SVC
    SVC --> MY
    P2 --> MY
    P3 --> NG
    NG -- "tunnel target api-gateway:8080" --> GW
    PAYOS -- "webhook" --> INET --> NG
```

*Figure IV.2 shows the container network. Only three ports are published to the host: 9080 (gateway), 4307 (MySQL, bound to 127.0.0.1) and 5041 (Ngrok inspector, bound to 127.0.0.1). All other services are reachable only inside the Docker network. The Ngrok container forwards public traffic, such as the PayOS webhook, to `api-gateway:8080`.*

### 2. Database Design (Database-per-Service)

Each microservice owns its private schema on MySQL 8.4. The AI schema is created by Flyway migrations V1–V7 and validated by Hibernate (`ddl-auto=validate`); the other services let Hibernate update the schema (`ddl-auto=update`) and seed reference data with `data.sql`.

| Schema | Tables |
|---|---|
| `veggiepal_identity` | `users`, `user_otps`, `refresh_tokens`, `user_favorites`, `user_badges` |
| `veggiepal_nutrition` | `allergens`, `user_allergies`, `health_records`, `food_logs`, `daily_wellness_logs` |
| `veggiepal_blog` | `categories`, `blogs`, `videos`, `comments`, `content_votes`, `user_follows`, `user_challenges` |
| `veggiepal_recipe` | `recipes`, `ingredients`, `recipe_ingredients`, `recipe_steps`, `recipe_likes` |
| `veggiepal_location` | `vegetarian_restaurants` |
| `veggiepal_ai` | `ai_meal_plans`, `ai_meal_plan_versions`, `ai_meal_plan_favorites`, `ai_conversations`, `ai_chat_messages`, `ai_guest_sessions`, `ai_daily_quotas`, `ai_usage_logs`, `ai_moderation_cases`, `ai_video_jobs` |
| `veggiepal_payment` | `subscription_plans`, `user_subscriptions`, `payment_orders` |

**Figure IV.3. Database-per-service overview and logical references**

```mermaid
flowchart LR
    U[("identity<br/>users, user_otps, refresh_tokens,<br/>user_favorites, user_badges")]
    N[("nutrition<br/>allergens, user_allergies, health_records,<br/>food_logs, daily_wellness_logs")]
    B[("blog<br/>categories, blogs, videos, comments,<br/>content_votes, user_follows, user_challenges")]
    R[("recipe<br/>recipes, ingredients, steps,<br/>recipe_ingredients, recipe_likes")]
    L[("location<br/>vegetarian_restaurants")]
    A[("ai<br/>meal plans, chat, quotas,<br/>usage, moderation, video jobs")]
    P[("payment<br/>subscription_plans,<br/>user_subscriptions, payment_orders")]

    N -. "user_id" .-> U
    B -. "author_id / user_id" .-> U
    R -. "user_id" .-> U
    A -. "user_id" .-> U
    P -. "user_id" .-> U
    A -. "external_content_id" .-> B
    A -. "source_video_id" .-> B
```

*Figure IV.3 shows the seven independent schemas. Dotted lines are logical references stored as plain numeric IDs (mostly the user ID from the JWT); they are not database foreign keys, which keeps every service independently deployable. Real foreign keys exist only inside a schema and are shown in Figures IV.3a–IV.3e.*

**Figure IV.3a. ERD of identity and nutrition schemas**

```mermaid
erDiagram
    USERS {
        bigint id PK
        varchar email UK
        varchar password_hash
        varchar full_name
        varchar phone
        varchar avatar_url
        date date_of_birth
        enum gender
        enum activity_level
        enum role
        enum status
        boolean email_verified
        datetime created_at
        datetime updated_at
    }
    USER_OTPS {
        bigint id PK
        bigint user_id
        varchar email
        enum purpose
        varchar code_hash
        varchar reset_token
        int attempts
        boolean used
        datetime expires_at
        datetime created_at
    }
    REFRESH_TOKENS {
        bigint id PK
        bigint user_id
        varchar token_hash UK
        boolean revoked
        datetime expires_at
        datetime created_at
        datetime revoked_at
    }
    USER_FAVORITES {
        bigint id PK
        bigint user_id
        enum target_type
        bigint target_id
        varchar title
        varchar image_url
        datetime created_at
    }
    USER_BADGES {
        bigint id PK
        bigint user_id
        enum badge_code
        datetime earned_at
    }
    FOOD_LOGS {
        bigint id PK
        bigint user_id
        date log_date
        enum meal_type
        varchar food_name
        bigint recipe_id
        int calories
        decimal protein_g
        decimal carbs_g
        decimal fat_g
        decimal fiber_g
    }
    DAILY_WELLNESS_LOGS {
        bigint id PK
        bigint user_id
        date log_date
        int water_ml
        int water_target_ml
        int exercise_minutes
        int steps
        int calories_burned
    }
    ALLERGENS {
        bigint id PK
        varchar code UK
        varchar name
        enum category
    }
    USER_ALLERGIES {
        bigint id PK
        bigint user_id
        bigint allergen_id FK
        datetime created_at
    }
    HEALTH_RECORDS {
        bigint id PK
        bigint user_id
        decimal height_cm
        decimal weight_kg
        decimal bmi
        datetime recorded_at
    }
    USERS ||--o{ USER_OTPS : "user_id"
    USERS ||--o{ REFRESH_TOKENS : "user_id"
    ALLERGENS ||--o{ USER_ALLERGIES : "allergen_id"
```

*Figure IV.3a: `users`, `user_otps` (hashed 6-digit OTPs for password reset and email verification) and `refresh_tokens` (SHA-256-hashed opaque refresh tokens for rotation and revocation) belong to identity-service. In nutrition-service, a user's allergen choices are rows in `user_allergies` pointing to the seeded `allergens` catalog; health records form a history of height, weight and BMI per user. `user_favorites` and `user_badges` hold profile collections and unlocked badges; nutrition-service also keeps the food diary (`food_logs`) and daily water/exercise tracking (`daily_wellness_logs`). `user_id` across these tables refers to `users.id` logically rather than through cross-table foreign keys.*

**Figure IV.3b. ERD of the blog schema**

```mermaid
erDiagram
    CATEGORIES {
        bigint id PK
        bigint parent_id FK
        enum type
        varchar name UK
        smallint display_order
        boolean is_active
    }
    BLOGS {
        bigint id PK
        bigint author_id
        bigint category_id FK
        varchar title
        longtext content
        varchar thumbnail_url
        enum status
        int view_count
        int vote_score
        datetime published_at
    }
    VIDEOS {
        bigint id PK
        bigint author_id
        bigint category_id FK
        varchar title
        text description
        enum source_type
        varchar video_url
        int vote_score
        int calories
        decimal protein_g
        decimal carbs_g
        decimal fat_g
        decimal fiber_g
        text ingredients_text
        varchar thumbnail_url
        enum status
        int view_count
        datetime published_at
    }
    COMMENTS {
        bigint id PK
        bigint author_id
        enum target_type
        bigint target_id
        bigint parent_comment_id FK
        text content
        enum status
    }
    USER_FOLLOWS {
        bigint id PK
        bigint follower_id
        bigint followee_id
        datetime created_at
    }
    USER_CHALLENGES {
        bigint id PK
        bigint user_id UK
        varchar check_in_dates
        date completed_at
    }
    CONTENT_VOTES {
        bigint id PK
        bigint user_id
        enum target_type
        bigint target_id
        int value
    }
    CATEGORIES ||--o{ CATEGORIES : "parent_id"
    CATEGORIES ||--o{ BLOGS : "category_id"
    CATEGORIES ||--o{ VIDEOS : "category_id"
    COMMENTS ||--o{ COMMENTS : "parent_comment_id"
```

*Figure IV.3b: Categories form a two-level tree and every blog or video belongs to one category. Both `blogs` and `videos` carry a denormalized `vote_score` updated atomically; `videos` also stores optional nutrition facts and an ingredients list, and `user_follows` / `user_challenges` back author follows and the 7-day challenge. Comments and votes are polymorphic: `target_type` (BLOG or VIDEO) and `target_id` identify the content, so no foreign key is declared; comments reference their parent comment for nested replies. A unique constraint on votes allows one vote per user per target.*

**Figure IV.3c. ERD of the recipe and location schemas**

```mermaid
erDiagram
    RECIPES {
        bigint id PK
        bigint user_id
        varchar title
        varchar description
        varchar image_url
        int servings
        int prep_time
        int cook_time
        int like_count
        enum status
        datetime published_at
    }
    INGREDIENTS {
        bigint id PK
        varchar name
        varchar normalized_name
        decimal calories_per_100g
        decimal protein_per_100g
        decimal carbs_per_100g
        decimal fat_per_100g
        decimal fiber_per_100g
        varchar description
        boolean vegan
        boolean allergen
        varchar image_url
        boolean active
    }
    RECIPE_INGREDIENTS {
        bigint id PK
        bigint recipe_id FK
        bigint ingredient_id FK
        decimal quantity
        varchar unit
        varchar note
    }
    RECIPE_STEPS {
        bigint id PK
        bigint recipe_id FK
        int step_number
        varchar instruction
    }
    RECIPE_LIKES {
        bigint id PK
        bigint user_id
        bigint recipe_id
        datetime created_at
    }
    VEGETARIAN_RESTAURANTS {
        bigint id PK
        varchar name
        varchar address
        double latitude
        double longitude
        varchar phone_number
        double rating
        boolean is_vegan_only
        varchar image_url
    }
    RECIPES ||--o{ RECIPE_INGREDIENTS : "recipe_id"
    INGREDIENTS ||--o{ RECIPE_INGREDIENTS : "ingredient_id"
    RECIPES ||--o{ RECIPE_STEPS : "recipe_id"
    RECIPES ||--o{ RECIPE_LIKES : "recipe_id"
```

*Figure IV.3c: `recipe_ingredients` is the associative table that gives each recipe its ingredients with quantity and unit (used together with `ingredients.*_per_100g` to compute per-serving nutrition), `recipe_steps` stores ordered cooking steps, and `recipe_likes` records per-user likes (unique on `user_id, recipe_id`) paired with the denormalized `recipes.like_count`. `vegetarian_restaurants` is a standalone table in location-service; its name, address, vegan flag and coordinates feed keyword search and `ST_Distance_Sphere` nearby search.*

**Figure IV.3d. ERD of the AI schema**

```mermaid
erDiagram
    AI_MEAL_PLANS {
        bigint id PK
        bigint user_id
        varchar name
        varchar goal
        varchar goal_type
        longtext plan_json
        int version
        datetime created_at
        datetime updated_at
    }
    AI_MEAL_PLAN_VERSIONS {
        bigint id PK
        bigint meal_plan_id FK
        int version
        varchar name
        varchar goal
        longtext plan_json
        varchar change_summary
        datetime created_at
    }
    AI_MEAL_PLAN_FAVORITES {
        bigint id PK
        bigint user_id
        bigint meal_plan_id FK
        datetime created_at
    }
    AI_CONVERSATIONS {
        bigint id PK
        bigint user_id
        varchar title
        datetime created_at
        datetime updated_at
    }
    AI_CHAT_MESSAGES {
        bigint id PK
        bigint conversation_id FK
        varchar principal_key
        varchar role
        text content
        int prompt_tokens
        int completion_tokens
        datetime created_at
    }
    AI_GUEST_SESSIONS {
        varchar id PK
        varchar ip_hash
        datetime created_at
        datetime expires_at
    }
    AI_DAILY_QUOTAS {
        bigint id PK
        varchar principal_key
        varchar feature
        date usage_date
        int request_count
        bigint input_tokens
        bigint output_tokens
    }
    AI_USAGE_LOGS {
        bigint id PK
        bigint user_id
        varchar principal_key
        varchar feature
        varchar model
        varchar status
        int prompt_tokens
        int completion_tokens
        bigint latency_ms
        datetime created_at
    }
    AI_MODERATION_CASES {
        bigint id PK
        varchar content_type
        bigint external_content_id
        bigint author_id
        text content_text
        varchar decision
        varchar categories
        varchar reason
        decimal confidence
        bigint reviewed_by
        datetime reviewed_at
        datetime created_at
    }
    AI_VIDEO_JOBS {
        bigint id PK
        bigint user_id
        bigint source_video_id
        varchar status
        varchar original_filename
        longtext transcript
        longtext extraction_json
        boolean quota_reserved
        boolean quota_refunded
        date quota_period_date
        datetime created_at
        datetime updated_at
    }
    AI_MEAL_PLANS ||--o{ AI_MEAL_PLAN_VERSIONS : "meal_plan_id"
    AI_MEAL_PLANS ||--o{ AI_MEAL_PLAN_FAVORITES : "meal_plan_id"
    AI_CONVERSATIONS ||--o{ AI_CHAT_MESSAGES : "conversation_id"
```

*Figure IV.3d: A meal plan keeps its current JSON and a history of versions, and users can favorite plans (one favorite per user and plan). Conversations own their chat messages. `ai_guest_sessions` stores only a hash of the guest's IP address. `ai_daily_quotas` is unique per (principal, feature, date) and enforces usage limits; `ai_usage_logs` records every AI call with its token counts and latency for admin monitoring. Moderation cases and video jobs reference content by ID only.*

**Figure IV.3e. ERD of the payment schema**

```mermaid
erDiagram
    SUBSCRIPTION_PLANS {
        bigint id PK
        enum code UK
        bigint price
        int duration_days
        int chat_per_day
        int meal_plans_per_month
        int videos_per_month
        boolean active
    }
    USER_SUBSCRIPTIONS {
        bigint id PK
        bigint user_id UK
        bigint plan_id FK
        instant started_at
        instant expires_at
        instant updated_at
        bigint version
    }
    PAYMENT_ORDERS {
        bigint id PK
        bigint order_code UK
        bigint user_id
        bigint plan_id FK
        bigint amount
        enum status
        varchar payment_link_id
        varchar checkout_url
        varchar qr_code
        varchar payment_reference
        instant expired_at
        instant created_at
        instant paid_at
        bigint version
    }
    SUBSCRIPTION_PLANS ||--o{ USER_SUBSCRIPTIONS : "plan_id"
    SUBSCRIPTION_PLANS ||--o{ PAYMENT_ORDERS : "plan_id"
```

*Figure IV.3e: The plan catalog (FREE, PLUS, PRO) holds price, duration and quotas. Each user has at most one current subscription row, and every checkout creates a payment order tied to a plan. The `version` columns provide optimistic locking.*

### 3. Detailed Design & Sequence Specifications

#### 3.1. Authentication & Token Verification Flow

**Figure IV.4. Login and JWT issuance sequence**

```mermaid
sequenceDiagram
    autonumber
    actor C as Client
    participant GW as API Gateway
    participant ID as identity-service
    participant DB as veggiepal_identity
    participant S as Any other service

    C->>GW: POST /api/auth/login (email, password)
    GW->>ID: POST /auth/login
    ID->>DB: find user by normalized email
    DB-->>ID: user row
    ID->>ID: BCrypt verify password (cost 10)
    ID->>ID: verify user status is ACTIVE
    ID->>ID: sign JWT HS256 (userId, role, 24 h)
    ID->>DB: save SHA-256 hash of opaque refresh token
    ID-->>GW: JWT, refreshToken and user info
    GW-->>C: JWT, refreshToken and user info
    C->>GW: GET /api/... with Authorization Bearer token
    GW->>S: forward request
    S->>S: validate signature and expiry with shared secret
    S-->>C: response (401 if token invalid)
```

*Figure IV.4 shows the login sequence. Identity-service verifies the password hash and confirms that the account status is `ACTIVE` (rejecting locked or inactive accounts with HTTP 403), then signs a 24-hour HS256 JWT carrying `userId` and `role` and issues an opaque refresh token stored as a SHA-256 hash in `refresh_tokens` (rotatable via `POST /api/auth/refresh` and revocable via `POST /api/auth/logout`). Every later request carries the JWT as a Bearer header; each service validates the signature locally with the shared secret, so no service has to call identity-service for authentication. Google sign-in follows the same pattern, except identity-service verifies a Google ID token (including `email_verified`) instead of a password before checking status and issuing its own JWT and refresh token.*

#### 3.2. AI 7-Day Allergen-Safe Meal Plan Generation Flow

1. The client sends `POST /api/ai/meal-plans` with a Bearer token (public gateway path; the service route is `/ai/meal-plans`).
2. ai-service calls recipe-service for the recipe list and calls nutrition-service with the user's token to read the user's allergens and latest health record.
3. If the request has no daily nutrition target, ai-service computes one from the user's profile and health record (BMR/TDEE adjusted by the goal type: weight loss, muscle gain or maintenance) and validates it.
4. ai-service reserves one meal-plan unit from the user's monthly quota (plan limits are read from payment-service; an unavailable lookup is treated as the FREE plan).
5. The validator removes every recipe that contains a declared allergen and ranks the remaining recipes so that those matching more of the user's available ingredients come first.
6. ai-service asks the Groq LLM (default model `openai/gpt-oss-20b`) to build a plan from these real recipe IDs. If the call fails, a deterministic planner is used instead.
7. The validator checks and enriches the plan: exactly seven days with breakfast, lunch and dinner, only allowed recipe IDs, allergen safety, and calories scaled toward the daily meal budgets.
8. The plan is stored in `ai_meal_plans` and returned to the client; later edits create new versions.

**Figure IV.5. Meal plan generation sequence**

```mermaid
sequenceDiagram
    autonumber
    actor C as Client
    participant GW as API Gateway
    participant AI as ai-service
    participant NU as nutrition-service
    participant RE as recipe-service
    participant PA as payment-service
    participant GQ as Groq LLM
    participant DB as veggiepal_ai

    C->>GW: POST /api/ai/meal-plans (JWT, goal, preferences, ingredients)
    GW->>AI: POST /ai/meal-plans
    AI->>RE: GET /recipes (size 200)
    RE-->>AI: recipes with ingredients
    AI->>NU: GET /nutrition/me/allergies
    NU-->>AI: allergens
    AI->>NU: GET /nutrition/me/health-records/latest
    NU-->>AI: latest height, weight, BMI
    AI->>AI: resolve daily nutrition target (BMR / TDEE and goal)
    AI->>PA: GET /internal/subscriptions/{userId} (internal token)
    PA-->>AI: plan quotas
    AI->>DB: reserve monthly meal-plan quota
    AI->>AI: exclude allergen recipes, rank by available ingredients
    AI->>GQ: prompt with safe recipes and constraints
    alt LLM answered
        GQ-->>AI: candidate plan JSON
    else LLM failed
        AI->>AI: deterministic planner builds the plan
    end
    AI->>AI: validate 7 days x 3 meals, allergens, calorie budgets
    AI->>DB: save plan in ai_meal_plans
    AI-->>C: meal plan response
```

*Figure IV.5 shows how the plan is produced. ai-service gathers data from three services, reserves quota, filters unsafe recipes before the LLM sees them, lets the LLM choose among real recipes only, and validates the result again on the server. When the LLM is unavailable the deterministic planner still produces a valid plan.*

#### 3.3. PayOS Asynchronous Webhook Payment Processing Flow

**Figure IV.6. PayOS webhook processing**

```mermaid
sequenceDiagram
    autonumber
    actor C as Client
    participant GW as API Gateway
    participant PA as payment-service
    participant PO as PayOS
    participant DB as veggiepal_payment
    participant B as Banking app

    C->>GW: POST /api/payments/checkout (planCode)
    GW->>PA: POST /payments/checkout
    PA->>DB: reuse pending order or create PENDING order
    PA->>PO: create payment link
    PO-->>PA: checkout URL and VietQR data
    PA-->>C: order with QR code
    C->>B: scan VietQR and pay
    B->>PO: bank transfer
    PO->>GW: POST /api/payments/webhook/payos (signed)
    GW->>PA: POST /payments/webhook/payos
    PA->>PA: verify webhook signature
    PA->>DB: lock order by order code
    alt order not found, PAID or CANCELLED
        PA-->>PO: acknowledge without changes
    else amount or payment link mismatch
        PA-->>PO: reject (error)
    else valid pending order
        PA->>DB: set order PAID and paid_at
        PA->>DB: activate or extend user subscription
        PA-->>PO: success
    end
    C->>GW: GET /api/subscriptions/me
    GW-->>C: active plan and quotas
```

*Figure IV.6 shows the payment flow. A checkout creates a pending order and a VietQR code. After the bank transfer, PayOS calls the webhook through the Ngrok tunnel. payment-service verifies the signature, locks the order row, rejects mismatching amounts, and ignores orders that are already paid or cancelled, so a duplicate webhook cannot grant a subscription twice.*

### 4. API Design

All clients use the gateway at `http://localhost:9080`; the aggregated Swagger UI is at `http://localhost:9080/swagger-ui.html`. Services answer with a common envelope (`code`, `message`, `result`) and use enum-based error codes grouped per service. Protected endpoints require `Authorization: Bearer <JWT>`.

| Group | Examples (gateway path) | Access |
|---|---|---|
| Identity | `/api/auth/register`, `/api/auth/login`, `/api/auth/google`, `/api/auth/forgot-password`, `/api/auth/verify-otp`, `/api/auth/reset-password`, `/api/auth/send-verification`, `/api/auth/verify-email`, `/api/auth/refresh`, `/api/auth/logout`, `/api/users/me` (profile, password, avatar), `/api/users/me/favorites`, `/api/users/me/badges`, `/api/users/batch`, `/api/admin/users/**` | Public for auth/OTP/refresh/batch; JWT for `/api/users/me`; ADMIN for `/api/admin/users/**` |
| Nutrition | `/api/nutrition/me/allergies`, `/api/nutrition/me/health-records/**`, `/api/nutrition/me/food-logs`, `/api/nutrition/me/daily-activity`, `/api/nutrition/me/water`, `/api/nutrition/me/daily-summary`, allergen catalog | JWT |
| Blog and community | `/api/blogs/**` (including `/community/leaderboard`, `/community/trending-topics`, `/community/stats`, `/authors/{id}/follow`, `/me/following`, `/challenge/me`, `/challenge/check-in`), `/api/categories/**`, `/api/comments/**`, `/api/videos/**` (including `/channels`, `/{id}/nutrition`, `/{id}/vote`, `/me/votes`) | Public reads of published content, community stats and video channels; JWT to write/vote/follow/check in; ADMIN for categories and takedowns |
| Recipes | `/api/recipes/**` (`/popular`, `/{id}/image`, `/images`, `/{id}/like`, `/me/likes`), `/api/ingredients/**` | Public reads of recipe list/popular/detail and ingredients; JWT for recipe authoring, image upload and likes; ADMIN for ingredient changes |
| Restaurants | `/api/restaurants`, `/api/restaurants/search`, `/api/restaurants/nearby` (`keyword`, `veganOnly`, `lat`, `lng`, `radiusKm`) | Public |
| AI chat | `/api/ai/chat/guest-sessions`, guest chat, member chat, conversations | Guest session or JWT |
| AI meal plans & quotas | `POST /api/ai/meal-plans`, `GET /api/ai/meal-plans`, `/quota`, `GET /api/ai/quotas/me`, `/nutrition-target`, `/favorites`, `/{id}/versions`, `/{id}/versions/{version}/restore`, `/{id}/preview-edit`, `/{id}/edit`, `/{id}/replace` | JWT |
| AI video | `POST /api/ai/videos/process` (multipart), job status endpoints | JWT |
| AI moderation and monitoring | `/api/ai/moderation/check`, `/ai/admin/moderation`, `/ai/admin/monitoring/**` | Service call / ADMIN |
| Payments | `GET /api/payments/plans`, `POST /api/payments/checkout`, `/api/payments/orders/{id}`, `/history`, `GET /api/subscriptions/me`, `POST /api/payments/webhook/payos`, `/api/admin/payments/**` | JWT; ADMIN for `/api/admin/payments/**`; webhook is public but signature-verified |
| Internal | `/internal/subscriptions/{userId}` (not routed through the gateway) | Internal service token |

Request and response schemas, status codes and examples for every endpoint are published in Swagger UI, generated from the OpenAPI definitions of each service.

---

## V. SOFTWARE TESTING DOCUMENTATION

### 1. Scope & Test Strategy

- **Unit tests:** business logic such as BMI calculation (nutrition-service), BMR/TDEE target calculation (ai-service `NutritionTargetCalculator`), allergen detection and meal-plan validation, and quota handling.
- **Controller slice tests:** `@WebMvcTest` with MockMvc and Spring Security Test to check routing, validation, authentication (JWT) and authorization per endpoint.
- **Integration tests:** repository and service tests against a database; several services have a `contextLoads`/integration test that needs a real MySQL.
- **CI automation:** GitHub Actions runs `mvn test` for every backend service on each push and pull request to `dev` or `main`.

### 2. Test Environment & Supporting Tools

- **Frameworks:** JUnit 5, Mockito, Spring Security Test, AssertJ.
- **Execution engine:** Maven Surefire on OpenJDK 21 (Temurin in CI).
- **Databases in tests:** ai-service, payment-service and recipe-service tests run on in-memory H2 in MySQL mode. identity-service, nutrition-service, blog-service and location-service use a MySQL 8.4 instance; in CI it is a service container on port 3307. Testcontainers is not used.
- **CI runners:** GitHub-hosted `ubuntu-latest` for build, test, Docker build and compose validation; a self-hosted Windows x64 runner for deployment.

### 3. Test Inventory

The repository contains 106 test classes with 712 test methods (counted from `@Test`, `@ParameterizedTest` and `@RepeatedTest` annotations in source).

| No. | Service | Test methods | Primary test focus |
|---|---|---|---|
| 1 | blog-service | 259 | Blogs, videos, comments, votes, categories, moderation fallback, security |
| 2 | ai-service | 212 | Meal planning, version restore, validation, quota endpoints, chat, video jobs, moderation |
| 3 | identity-service | 102 | Registration, login, OTP password reset & email verification, refresh tokens, admin users, profile |
| 4 | nutrition-service | 47 | Health records, BMI, allergen mapping |
| 5 | recipe-service | 38 | Recipe CRUD, per-serving nutrition, image upload, likes & popular, ingredient data and units |
| 6 | payment-service | 26 | PayOS signature, webhook handling, subscriptions |
| 7 | location-service | 19 | Restaurant keyword search, vegan filter and nearby distance search |
| 8 | api-gateway | 9 | Routing rules (including admin routes) and Swagger aggregation |
| | **Total** | **712** | |

The result of each test run is recorded by the "Run tests" step of the `maven` job in GitHub Actions (see Figure VI.5).

### 4. Quality Controls Built Into the Design

| Risk | Control in the implementation |
|---|---|
| Concurrent votes corrupting the vote score | Unique constraint per (user, target) and an atomic SQL update of `vote_score` |
| Duplicate payment webhooks granting a subscription twice | Row lock on the order, early return for `PAID` / `CANCELLED` orders, amount and payment-link checks, optimistic `version` columns |
| Allergen exposure in AI meal plans | Allergen recipes removed before the LLM call, and the generated plan is validated again on the server |
| LLM outage or malformed output | Deterministic planner fallback and structural validation of every plan |
| Guest abuse of the free chatbot | Hashed-IP guest sessions, session TTL, per-IP session cap and a daily chat quota |
| Quota lost when a video job fails | Quota reservation flags on the job and automatic refund |
| Unsafe image uploads | Content-type and magic-byte validation before uploading to Cloudinary |

---

## VI. RELEASE PACKAGE & USER GUIDES

### 1. Deliverable Package

| Deliverable | Path in repository | Description |
|---|---|---|
| Backend source code | `/backend` | 7 Spring Boot business services + 1 API gateway, each with its own Dockerfile |
| Web frontend | `/frontend` | React 19, Vite, Tailwind CSS web application |
| Mobile application | `/mobile` | Flutter cross-platform client application |
| Database provisioning | `/backend/docker-compose.yml` | Starts an empty MySQL 8.4; Flyway (ai-service) and Hibernate create the schemas and `data.sql` seeds reference data |
| CI/CD pipeline | `/.github/workflows/ci-cd.yml` | Backend Maven matrix, Docker build, Compose validation, deployment to a self-hosted runner |
| API documentation | `http://localhost:9080/swagger-ui.html` | Aggregated OpenAPI / Swagger specification |

### 2. System Requirements & Installation Instructions

#### 2.1. System Requirements

- **Operating system:** Windows 10/11 64-bit, macOS, or Ubuntu 22.04 LTS.
- **Hardware:** at least 8 GB RAM, 4-core CPU and 20 GB free disk space. No local AI model is hosted; AI features need internet access and a `GROQ_API_KEY`.
- **Software:** Docker Desktop (Docker Compose v2+), Git, OpenJDK 21 (only for running services outside Docker), Node.js (web frontend), and a Flutter SDK compatible with the Dart constraint `^3.13.2` in `mobile/pubspec.yaml`.

#### 2.2. Installation Instructions

1. Clone the repository:

   ```bash
   git clone https://github.com/Phu0312/VeggiePal-Microservice.git
   cd VeggiePal-Microservice
   ```

2. Create the environment file and fill it in:

   ```bash
   cp backend/.env.example backend/.env
   ```

   Required for the stack to start: `DB_PASSWORD`, `JWT_SECRET`, `NGROK_AUTHTOKEN`. Needed for the related features: `INTERNAL_SERVICE_TOKEN`, `GROQ_API_KEY` (AI), `CLOUDINARY_*` (images and videos), `GOOGLE_CLIENT_ID` (Google sign-in), `MAIL_*` (SMTP delivery for OTP emails; falls back to application logs when `MAIL_HOST` is omitted in local development) and the `PAYOS_*` credentials (payments).

3. Start the whole backend with Docker Compose:

   ```bash
   cd backend
   docker compose --project-name veggiepal-prm up -d --build --wait
   ```

4. Open the system endpoints:

   | Endpoint | Address |
   |---|---|
   | API gateway and Swagger UI | http://localhost:9080/swagger-ui.html |
   | MySQL | 127.0.0.1:4307 |
   | Ngrok inspector | http://localhost:5041 |

5. Register the PayOS webhook as `https://<ngrok-domain>/api/payments/webhook/payos`.

6. Run the clients: `cd frontend && npm install && npm run dev` for the web app, and `cd mobile && flutter pub get && flutter run` for the mobile app.

### 3. User Manual & Core Workflows

#### 3.1. Workflow 1: Registration, Login & Allergen Setup

1. Open the VeggiePal application.
2. Register with email and password, or sign in with Google.
3. Open Profile > Health Profile and enter height (cm) and weight (kg).
4. Select all personal allergens (for example soybeans, peanuts, wheat gluten, mushrooms).

**Figure VI.1. Registration and health profile workflow**

```mermaid
flowchart TD
    A["Open app"] --> B{"Account?"}
    B -- "New" --> C["Register with email / password<br/>or Google sign-in"]
    B -- "Existing" --> D["Login"]
    C --> E["JWT stored on device"]
    D --> E
    E --> F["Profile > Health Profile"]
    F --> G["Enter height and weight<br/>(BMI computed by server)"]
    G --> H["Select allergens"]
    H --> I["Saved in nutrition-service"]
```

*Figure VI.1 shows the first-use workflow: authenticate, store the token, then enter body measurements and allergens, which later drive meal planning.*

#### 3.2. Workflow 2: Generating a 7-Day Personalized Meal Plan

1. Navigate to Menu Planner > Generate Plan.
2. Select a goal (weight loss, muscle gain or maintenance) and optionally list preferences and ingredients you have on hand.
3. The system computes the nutrition target, excludes recipes containing your allergens, and shows a plan with breakfast, lunch and dinner for seven days.
4. Open any recipe to see its ingredient quantities, per-serving nutrition and cooking steps. Plans can be edited, a single meal can be replaced, historical versions can be restored, and plans can be favorited.

**Figure VI.2. Meal plan workflow**

```mermaid
flowchart TD
    A["Menu Planner > Generate Plan"] --> B["Choose goal<br/>weight loss / muscle gain / maintenance"]
    B --> C["Optional: preferences and<br/>ingredients on hand"]
    C --> D["Submit"]
    D --> E{"Monthly plan quota left?"}
    E -- "No" --> F["Show quota exceeded<br/>offer PLUS / PRO upgrade"]
    E -- "Yes" --> G["Server filters allergens,<br/>builds and validates plan"]
    G --> H["Weekly schedule: 7 days x<br/>breakfast, lunch, dinner"]
    H --> I["Open recipe: ingredients and steps"]
    H --> J["Replace a meal / edit / favorite"]
```

*Figure VI.2 shows the planner workflow, including the quota check that can send the user to the subscription screen.*

#### 3.3. Workflow 3: Finding Nearby Vegan Restaurants via GPS

1. Open the Places / Map tab and allow location access.
2. The app asks location-service for restaurants matching an optional keyword or vegan-only filter, or within the chosen radius around the user's coordinates.
3. Results are ordered by distance, which is computed by MySQL `ST_Distance_Sphere`, together with their rating and a vegan-only flag.

**Figure VI.3. Nearby restaurant discovery workflow**

```mermaid
sequenceDiagram
    autonumber
    actor U as User
    participant APP as Mobile / Web app
    participant GW as API Gateway
    participant LO as location-service
    participant DB as veggiepal_location

    U->>APP: open Places tab, allow location
    APP->>GW: GET /api/restaurants/nearby (lat, lng, radius)
    GW->>LO: forward request
    LO->>DB: select within radius, order by ST_Distance_Sphere
    DB-->>LO: restaurants with distance in meters
    LO-->>APP: restaurants with distanceKm
    APP-->>U: map markers and list sorted by distance
```

*Figure VI.3 shows that the client sends its coordinates and radius, the database computes the spherical distance, and the app renders the results sorted by proximity.*

#### 3.4. Workflow 4: Upgrading to a PLUS or PRO Subscription via VietQR PayOS

1. Navigate to Profile > Subscription.
2. Select PLUS or PRO and choose to pay with PayOS.
3. Scan the dynamic VietQR code with any Vietnamese banking app.
4. After PayOS confirms the payment through the webhook, the subscription is activated for 30 days.

| Plan | Price | Chat per day | Meal plans per month | Videos per month |
|---|---|---|---|---|
| FREE | 0 VND | 5 | 2 | 0 |
| PLUS | 29,000 VND / 30 days | 20 | 8 | 3 |
| PRO | 59,000 VND / 30 days | 50 | 20 | 8 |

**Figure VI.4. PayOS subscription workflow**

```mermaid
flowchart TD
    A["Profile > Subscription"] --> B["Choose PLUS or PRO"]
    B --> C["Create checkout (payment-service)"]
    C --> D["Show VietQR code"]
    D --> E["User pays in banking app"]
    E --> F["PayOS sends signed webhook"]
    F --> G{"Signature, amount,<br/>order state valid?"}
    G -- "No" --> H["Webhook rejected or ignored"]
    G -- "Yes" --> I["Order PAID,<br/>subscription activated"]
    I --> J["App reads /api/subscriptions/me<br/>and shows new quotas"]
```

*Figure VI.4 shows the paying workflow from plan selection to activation. The subscription changes only after the signed webhook has been verified.*

### 4. CI/CD Deployment Process

The workflow `.github/workflows/ci-cd.yml` is named "VeggiePal CI/CD" and runs on every push and pull request to `dev` and `main`.

| Job | Runs on | What it does |
|---|---|---|
| `maven` | ubuntu-latest, matrix of 8 modules (api-gateway, identity, nutrition, blog, recipe, location, ai, payment) | Starts a MySQL 8.4 service container, sets up Java 21 with Maven cache, restores dependencies, runs `mvn test`, builds the Spring Boot package |
| `docker` | ubuntu-latest, same matrix, after `maven` | Builds the Docker image of each module from its Dockerfile |
| `compose-check` | ubuntu-latest, after `maven` | Validates the resolved Docker Compose configuration |
| `deploy` | self-hosted Windows x64 runner, only on push to `dev` or `main`, after `docker` and `compose-check` | Writes `.env` from the `BACKEND_ENV_FILE` secret, runs `docker compose up -d --build --wait`, then checks that every container is running and healthy; prints logs and fails otherwise |

**Figure VI.5. CI/CD pipeline**

```mermaid
flowchart LR
    T["Push or pull request<br/>to dev / main"] --> M

    subgraph M["maven job (matrix, 8 modules)"]
        M1["Restore dependencies"] --> M2["mvn test"] --> M3["mvn package"]
    end

    M --> D["docker job (matrix)<br/>build image per module"]
    M --> C["compose-check job<br/>docker compose config"]
    D --> P
    C --> P

    subgraph P["deploy job (push only, self-hosted Windows runner)"]
        P1["Prepare .env"] --> P2["docker compose up -d --build --wait"] --> P3["Verify containers running and healthy"]
    end
```

*Figure VI.5 shows the pipeline stages. Test and package run in parallel for every backend module; Docker image builds and Compose validation run next; deployment to the local runner runs only for pushes to `dev` or `main`. The pipeline currently covers the backend only; the web and mobile clients are built and run manually.*

---

## VII. APPENDIX

### 1. References

1. Dietary Guidelines for Americans, U.S. Department of Agriculture (USDA) - guidance on vegetarian eating patterns.
2. Spring Cloud Gateway Reference Documentation, VMware Tanzu.
3. Flutter documentation, Google Developers.
4. MySQL 8.4 Reference Manual - spatial function `ST_Distance_Sphere`.
5. RFC 7519 - JSON Web Token (JWT), Internet Engineering Task Force (IETF).
6. PayOS developer documentation - payment link creation and webhook verification.
7. Groq API documentation - chat completions and speech-to-text.

### 2. Project Metrics Summary

| Metric | Value |
|---|---|
| Backend modules | 8 (7 business services + 1 API gateway) |
| Database schemas | 7 isolated MySQL schemas |
| Database tables | 36 |
| Test classes / test methods | 106 / 712 |
| Subscription plans | 3 (FREE, PLUS, PRO) |
| CI jobs | `maven` and `docker` (matrix of 8 modules each), `compose-check`, `deploy` |
| Published host ports | 9080 (gateway), 4307 (MySQL), 5041 (Ngrok inspector) |
| Client applications | React web app, Flutter mobile app |

### 3. Results Achieved & Future Development

#### 3.1. Results Achieved

- A complete microservices backend (7 services and a gateway) that starts with one Docker Compose command and exposes aggregated Swagger documentation.
- Secure authentication with BCrypt, HS256 JWT validation in every service, opaque refresh-token rotation and revocation, 6-digit email OTP password recovery and email verification, and Google sign-in.
- Allergen-aware AI meal planning with server-side validation and a fallback planner; AI chatbot, video recipe extraction and moderation backed by Groq.
- A community module with nested comments, voting and administrator moderation.
- A domestic payment flow with PayOS VietQR, signed and idempotent webhook processing, and plan-based quotas.
- An automated GitHub Actions pipeline that tests, packages, builds images, validates Compose and deploys to a local runner.

#### 3.2. Future Development

- **Quality:** archive Surefire reports from CI, add JaCoCo to measure code coverage (target at least 60%), and add reproducible load tests for the gateway and the AI endpoints.
- **CI/CD:** add build and lint steps for the React and Flutter projects, and publish test reports as workflow artifacts.
- **Resilience and observability:** add retry and circuit-breaker policies and monitoring for the external Groq, Cloudinary, Google and PayOS dependencies.
- **Scalability:** introduce asynchronous messaging only if measured throughput requires it, for example for video processing and moderation.
- **Product:** richer nutrition analysis (micronutrient tracking), more recipe and restaurant data, and push notifications.
