# VeggiePal Backend Demo Completion Plan

## Current State Summary

### Existing Services
| Service | Port | Status |
|---------|------|--------|
| api-gateway | 8080 | Working |
| identity-service | 8081 | Working |
| nutrition-service | 8082 | Working |
| blog-service | 8083 | Working |

### Technology Stack
- Java 21, Spring Boot 4.1.1
- MySQL 8.4 (Docker, host port 3307)
- MinIO for file storage (S3-compatible)
- Spring Cloud Gateway (WebMVC)
- JWT (HS256, jjwt library)
- Lombok, MapStruct
- SpringDoc OpenAPI

### Databases
- `veggiepal_identity` - manual creation required
- `veggiepal_nutrition` - auto-created via `createDatabaseIfNotExist`
- `veggiepal_blog` - auto-created via `createDatabaseIfNotExist`

---

## FR Requirements Audit

| Requirement | Current Status | Existing Implementation | Missing Work | Service | Demo Priority |
|-------------|---------------|------------------------|--------------|---------|---------------|
| **FR-01 Authentication** | IMPLEMENTED | Register, Login, JWT, BCrypt | Block login for BLOCKED users, admin user management | identity-service | P0 |
| **FR-02 Guest public content** | PARTIAL | Public blog listing/search exists | Guest AI chatbot trial (3 questions) | nutrition-service (new AI module) | P0 |
| **FR-03 User content management** | IMPLEMENTED | Full Blog CRUD with ownership | None critical | blog-service | P0 |
| **FR-04 Comments/Voting** | IMPLEMENTED | Comments (polymorphic), Votes (toggle) | None critical | blog-service | P0 |
| **FR-05 Search/Recommendations** | PARTIAL | Blog search + related blogs | Unified search, video/recipe search | blog-service, gateway | P1 |
| **FR-06 AI Meal Planner** | MISSING | Health records, allergies exist | Recipes, ingredients, meal plan generation, save/replace | nutrition-service | P0 |
| **FR-07 AI Chatbot** | MISSING | None | Full chatbot with conversations, local AI provider | nutrition-service | P0 |
| **FR-08 Video Summarization** | MISSING | None | Video module + summary with local provider | New video module or nutrition-service | P0 |
| **FR-09 Nearby Restaurants** | MISSING | None | Restaurant entity, Haversine, seed data | nutrition-service | P0 |
| **FR-10 Admin management** | PARTIAL | Admin can delete/ban blogs | User list, user status, admin content views | identity-service | P0 |
| **FR-11 Category management** | IMPLEMENTED | Full Admin CRUD + tree | None critical | blog-service | P0 |
| **FR-12 Content moderation** | PARTIAL | Interface + auto-approve stub | Keyword-based demo moderation, moderation cases, admin review | blog-service | P0 |

---

## Port Migration Plan

| Component | Current Port | New Port |
|-----------|-------------|----------|
| MySQL Docker (host) | 3307 | 53306 |
| API Gateway | 8080 | 18080 |
| Identity Service | 8081 | 18081 |
| Nutrition Service | 8082 | 18082 |
| Blog Service | 8083 | 18083 |
| MinIO API | 9000 | 19000 |
| MinIO Console | 9001 | 19001 |

---

## Implementation Plan (P0 items in order)

### Phase 1: Port Migration & Infrastructure
1. Update docker-compose.yml (MySQL port 53306, MinIO 19000/19001, named volumes)
2. Update all application.properties/yaml with new ports (env-driven)
3. Update gateway routes

### Phase 2: Identity Service Additions
4. Block login for BLOCKED/INACTIVE users
5. Admin user list, user detail, user status management
6. Seed admin + demo users via data.sql

### Phase 3: Moderation Enhancement (blog-service)
7. Replace auto-approve with keyword-based demo moderation
8. Add moderation case entity + persistence
9. Admin moderation endpoints (queue, approve, reject)

### Phase 4: Nutrition Service - Recipes, Ingredients, Meal Planner
10. Recipe entity + seeded data (15+ vegan recipes)
11. User Ingredients CRUD
12. Meal Plan Generator (rule-based, 7-day)
13. Meal Plan save/retrieve/replace-meal

### Phase 5: AI Chatbot
14. Conversation + Message entities
15. Guest quota tracking
16. Local demo AI chat provider
17. Chat endpoints (guest + authenticated)

### Phase 6: Video Module (in blog-service)
18. Video entity (reuse blog-service patterns, TargetType.VIDEO already exists)
19. Video CRUD with ownership
20. Video summary with local demo provider

### Phase 7: Restaurant Module (in nutrition-service)
21. Restaurant entity + seed data (6+)
22. Haversine distance calculation
23. Nearby search endpoint

### Phase 8: Admin Enhancements
24. AI operation logging
25. AI monitoring endpoints (logs, metrics)

### Phase 9: Gateway & Swagger
26. Add routes for all new endpoints
27. Verify Swagger aggregation

### Phase 10: Seed Data & Documentation
28. Complete seed data across all services
29. Postman collection
30. Demo documentation (README, Demo Script, Traceability, Architecture)
