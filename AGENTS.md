# AGENTS.md

Rules for any AI coding agent working in this repository (backend, frontend, mobile).

## Files agents must not edit

These files are maintained by the team by hand. Do not edit, rewrite, reformat, rename or delete them, even when a code change seems to affect them, and do not apply the "keep the report in sync" rules below to them:

- [docs/requirement_1.md](docs/requirement_1.md) - course requirement (project scope, deliverables, grading).
- [docs/requirement_2.md](docs/requirement_2.md) - course requirement for Task 2 (database, DevOps/CI/CD, self-hosted AI model, experiments).
- [docs/ho_so_trien_khai_ai_veggiepal.md](docs/ho_so_trien_khai_ai_veggiepal.md) - the team's self-hosted AI deployment dossier.

If a code change makes one of them out of date, or you find a mistake in one, report it to the user in your reply and leave the file as it is. Only edit them when the user explicitly asks for that specific file in the current request.

## Keep the capstone report in sync with the code

The final report is [docs/PRM_CAPSTONE.md](docs/PRM_CAPSTONE.md). It is graded against the code, so it must describe what the code does today, not what was planned.

**Whenever you change code, update the report in the same piece of work (same branch, same commit or PR).** Do it before saying the task is done. If a change needs no report update, say so in one line in your final message.

### What to update, by type of change

| If you change... | Update these report sections |
|---|---|
| A REST endpoint (path, method, request/response DTO, auth rule) in any service or in the gateway routes | III.3 FR matrix (if behaviour changes), IV.1 service table (gateway routes), IV.4 API table, the relevant sequence figure |
| An entity, table, column, enum or Flyway migration | IV.2 table list, the matching ERD (Figures IV.3a-e), Project Metrics (table count) |
| A new service, port, container, or `docker-compose.yml` change | IV.1 service table and Figure IV.1, Figure IV.2, VI.1 deliverables, VI.2 install steps, `.env.example` variable list, Project Metrics |
| Meal planning, chat, moderation, video, quotas (ai-service) | FR-02, FR-06 to FR-08, FR-10, business rules BR-02, BR-03, BR-06, Figure IV.5, workflows VI.3 |
| Plans, prices, quotas, PayOS flow (payment-service) | FR-12, BR-05, BR-06, Figure IV.6, Figure VI.4 and the plan table in VI.3.4 |
| Login, JWT, roles, status handling (identity-service) | FR-01, actors table III.2, NFR Security, Figure IV.4 |
| Blog, comments, votes, categories (blog-service) | FR-03, FR-04, FR-09, Figure IV.3b, IV.4 API table |
| Restaurant search (location-service) | FR-05, Figure VI.3 |
| A test is added, removed or a test class changes | V.3 test inventory and Project Metrics (see "Counting tests") |
| `.github/workflows/ci-cd.yml` | VI.4 CI/CD process table and Figure VI.5 |
| A new user-visible feature in the web or Flutter client | III.3 FR matrix, VI.3 user workflows, III.2 actors if permissions change |
| A feature is removed or found not to exist | Remove or correct it everywhere it is mentioned (search the report for its name) |

### Rules for editing the report

1. **Verify against the code before writing.** Open the controller, entity, config or workflow you are describing. Do not copy a number, path, field name or behaviour from memory or from the old report text.
2. **Never invent evidence.** Do not write pass rates, latencies, coverage, benchmark figures, defect lists or "verified" claims unless you ran the command in this session and saw the output. If something is unknown, leave it out or describe it as not measured; do not fill it with a plausible number.
3. **Describe the current branch.** If a feature exists only on another branch, do not document it as implemented.
4. **Keep the structure.** The section numbering (I-VII) follows the course template. Add sub-sections inside it; do not renumber top-level sections. Keep the table of contents links valid when you add or rename a heading.
5. **Figures:** every figure is a Mermaid block followed by an italic caption that explains it. Name them `Figure <section>.<n>` and keep the numbering unique and in order. If you add a figure, add it to the right section; if you remove a feature, redraw or remove the figures that show it. Keep diagrams truthful: arrows are real calls, not decoration.
6. **Cross-references stay consistent.** The same fact appears in several places (plan quotas, ports, service list, table counts, test counts, guest limits). After changing it, search `docs/PRM_CAPSTONE.md` for the old value and fix every occurrence.
7. **Placeholders:** do not add new "to be inserted" or "not verified" notes to the report body. Report open items to the user in your reply instead.
8. **Tone:** plain English, present tense, no marketing claims.

### Counting tests

The report lists the number of test classes and test methods per service. After touching tests, recount instead of editing by hand:

```bash
# test methods per service (from the repository root)
for s in api-gateway identity-service nutrition-service blog-service recipe-service location-service ai-service payment-service; do
  echo "$s $(grep -rhoE '@(Test|ParameterizedTest|RepeatedTest)\b' backend/$s/src/test --include=*.java | wc -l)"
done
# test classes: *Test*.java files under each backend/<service>/src/test
```

Update the V.3 table, its total, and the metrics table. Only claim tests *pass* if you ran `mvn test` for that service in this session and saw it succeed.

### Facts that must match the code (quick checklist)

Check these when relevant; they are the values most likely to drift:

- Ports: gateway 8080 (host 9080), identity 8081, nutrition 8082, blog 8083, recipe 8084, location 8085, ai 8086, payment 8087, MySQL host 4307, Ngrok inspector host 5041.
- Plans and quotas in `PlanCatalogInitializer` (payment-service); guest limits in `ai-service` `application.properties`.
- Security: BCrypt cost in identity `SecurityConfig`, JWT algorithm and lifetime in identity `JwtService`.
- Gateway routes in `backend/api-gateway/src/main/resources/application.properties`.
- Database schemas and tables: entities (`@Table`) and `backend/ai-service/src/main/resources/db/migration`.
- Environment variables: `backend/.env.example`.
- CI jobs: `.github/workflows/ci-cd.yml`.

### Team and metadata

The project team table (I.1.2) is maintained by the team. Do not change names, student IDs, emails or the lecturer unless the user asks.

## Working in this repository

- Backend conventions, commands and gotchas: `backend/CLAUDE.md`. Frontend conventions: `frontend/CLAUDE.md`. Follow them when editing those areas.
- Each backend service is an independent Maven project (no parent POM); run Maven from inside the service directory.
- Do not commit secrets. `.env` files stay local; only `.env.example` is tracked.
- Commit only when the user asks. When you do, include the report change in the same commit as the code change it documents.
