# VeggiePal backend

Eight independent Maven modules provide the API gateway and seven domain services. Each module has its own `pom.xml`; run Maven inside that module. All modules except payment-service include a Maven wrapper.

| Module | Internal port | Main responsibility |
|---|---:|---|
| api-gateway | 8080 | Routes and aggregated Swagger UI |
| identity-service | 8081 | Accounts, JWT, OTP, profiles, badges |
| nutrition-service | 8082 | Health records, allergies, food diary, daily tracking |
| blog-service | 8083 | Blogs, videos, comments, community challenge |
| recipe-service | 8084 | Recipes and ingredients |
| location-service | 8085 | Restaurant search |
| ai-service | 8086 | Chat, meal plans, moderation, video processing |
| payment-service | 8087 | Plans, subscriptions and PayOS orders |

## Start

Copy `.env.example` to `.env` and set the required secrets. Do not commit `.env`. Run `docker compose up --build` from this directory for the container stack. The gateway is published on `localhost:9080`, MySQL on `localhost:4307`, and the ngrok inspector on `localhost:5041`. Swagger UI is at `http://localhost:9080/swagger-ui.html`.

`docker-compose.infra.yml` is an **alternative host development mode**: it runs MySQL and ngrok while the gateway and services run directly on the host. Both Compose files use the same project and container names; stop one mode before starting the other. In host mode ngrok reaches the gateway at `host.docker.internal:8080`; in full Compose it reaches `api-gateway:8080` and clients use host port 9080.

For host development, run `docker compose -f docker-compose.infra.yml up -d` and start each service from its module directory with `.\mvnw.cmd spring-boot:run` (Windows) or `./mvnw spring-boot:run`. Configure `.env` service URLs to use localhost ports 8081–8087. The database host port is 4307.

## API and tests

The gateway routes `/api/auth`, `/api/users`, `/api/nutrition`, `/api/blogs`, `/api/videos`, `/api/categories`, `/api/comments`, `/api/recipes`, `/api/ingredients`, `/api/restaurants`, `/api/ai`, `/api/payments`, and `/api/subscriptions` to their owning services. See each module's OpenAPI document and [the capstone report](../docs/PRM_CAPSTONE.md) for the current contract.

Run `.\mvnw.cmd test` from modules with a wrapper (or `./mvnw test` on Unix); run `mvn test` in payment-service. Some integration tests need MySQL. See [CLAUDE.md](CLAUDE.md) for service-specific test commands and database notes. When `MAIL_HOST` is empty, OTP logging is available only with the `dev` Spring profile; other profiles require SMTP.
