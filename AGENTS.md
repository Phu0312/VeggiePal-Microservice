# AGENTS.md

Rules for any AI coding agent working in this repository (backend, frontend, mobile).

## Files agents must not edit

These files are maintained by the team by hand. Do not edit, rewrite, reformat, rename or delete them, even when a code change seems to affect them, and do not apply the "keep the report in sync" rules below to them:

- [docs/requirement_1.md](docs/requirement_1.md) - course requirement (project scope, deliverables, grading).
- [docs/requirement_2.md](docs/requirement_2.md) - course requirement for Task 2 (database, DevOps/CI/CD, self-hosted AI model, experiments).
- [docs/ho_so_trien_khai_ai_veggiepal.md](docs/ho_so_trien_khai_ai_veggiepal.md) - the team's self-hosted AI deployment dossier.
- [docs/template.md](docs/template.md) - the lecturer's Report 7 template (an example report of another project). It defines the structure of our report; it is not documentation of this code.

If a code change makes one of them out of date, or you find a mistake in one, report it to the user in your reply and leave the file as it is. Only edit them when the user explicitly asks for that specific file in the current request.

## Keep the final report in sync with the code

The final report (Report 7) is [docs/REPORT7_FINAL_PROJECT_REPORT.md](docs/REPORT7_FINAL_PROJECT_REPORT.md). It is the only report; `docs/PRM_CAPSTONE.md` was removed and must not be recreated. The report is graded against the code, so it must describe what the code does today, not what was planned.

**Whenever you change code, update the report in the same piece of work (same branch, same commit or PR).** Do it before saying the task is done. If a change needs no report update, say so in one line in your final message.

### What to update, by type of change

Section numbers refer to the report (`I` to `VII`, then the numbered sections inside, for example `IV.4.3` is chapter IV, section 4, sub-section 3).

| If you change... | Update these report sections |
|---|---|
| A REST endpoint (path, method, request/response DTO, auth rule) in any service or in the gateway routes | III.3 FR table (if behaviour changes) and the matching feature section III.3.2 to III.3.8, IV.1.1 component table (gateway routes), IV.3 API table, the relevant sequence figure in IV.4 |
| An entity, table, column, enum or Flyway migration | IV.2 schema table, the matching ERD figure, table description table, 3NF exceptions (IV.2.1), seed data (IV.2.3), III.3.1.5 entity table and conceptual ERD, VII.3.1 metrics (table count) |
| A new service, port, container, or `docker-compose.yml` change | IV.1.1 component table and the architecture and Docker figures, IV.1.2 package diagrams, VI.1 deliverables, VI.2 installation, the `.env.example` variable list, VII.3.1 metrics |
| Meal planning, chat, moderation, video, quotas, AI provider or model (ai-service, `backend/ai-inference/`) | FR-02, FR-06 to FR-08, FR-10, business rules BR-02, BR-03, BR-06, BR-09 to BR-11, III.3.5, IV.4.2, IV.4.4, IV.4.5 and the AI safeguards table, VI.3.3, risks (II.1.3), limitations (I.6.2), system requirements (VI.2.1), external interfaces (III.4.1) |
| Plans, prices, quotas, PayOS flow (payment-service) | FR-12, BR-05, BR-06, III.3.7 and the payment order state figure, IV.4.3, the plans table in VI.3.3, business opportunity (I.4) |
| Login, JWT, roles, status handling (identity-service) | FR-01, actors table (III.2.1), III.3.2, quality attributes (III.4.2), IV.4.1 |
| Blog, comments, votes, categories (blog-service) | FR-03, FR-04, FR-09, III.3.6 and the blog state figure, the blog ERD figure, IV.3 API table |
| Restaurant search (location-service) | FR-05, III.3.4.2, VI.3.3 |
| A scheduled job, worker or other background function | III.3.1.4 non-screen functions table |
| A test is added, removed or a test class changes | V.4 suites table, V.5.1 results, II.1.2 objectives, VII.3.1 metrics (see "Counting tests") |
| `.github/workflows/ci-cd.yml` | V.5.3 CI/CD table and figure, II.2.2 |
| A new user-visible feature, screen or route in the web or Flutter client | III.3 FR table, the matching feature section, III.3.1.1 screen flows, III.3.1.2 screen tables, III.3.1.3 authorization table, IV.1.2 client package table, VI.3 user manual |
| A feature or external provider is removed, replaced or found not to exist | Remove or correct it everywhere it is mentioned (search the report for its name), including figures |

### Rules for editing the report

1. **Verify against the code before writing.** Open the controller, entity, config or workflow you are describing. Do not copy a number, path, field name or behaviour from memory or from the old report text.
2. **Never invent evidence.** Do not write pass rates, latencies, coverage, benchmark figures, defect lists, effort figures or "verified" claims unless you ran the command in this session and saw the output. If something is unknown, leave it out or describe it as not measured; do not fill it with a plausible number. Table V.5.1 may show "Pass" only for modules whose tests you ran.
3. **Describe the current branch.** If a feature exists only on another branch, do not document it as implemented.
4. **Keep the structure.** The chapters I-VII, their numbered sections and their titles follow [docs/template.md](docs/template.md). Add sub-sections inside them; do not renumber or rename top-level sections or drop a template section. Keep the table of contents links valid when you add or rename a heading.
5. **Figures and tables use one continuous numbering** (`Figure 1`, `Figure 2`, ... and `Table 1`, `Table 2`, ...), as in the template.
   - A table caption is the line `##### Table N: Title` above the table. A figure is a Mermaid block followed by the line `*Figure N: Title*` and a "Reading the diagram" paragraph that explains it.
   - When you add or remove a figure or table, renumber every later caption, every textual reference ("Figure 12", "Table 30") and the **List of Figures** and **List of Tables** near the top, and add or remove the matching entry. Add or remove the entry in the **Table of Contents** when you add or remove a heading of level 2 to 4.
   - If you add a figure, put it in the right section; if you remove a feature, redraw or remove the figures that show it. Keep diagrams truthful: arrows are real calls, not decoration.
   - Check the numbering before you finish (each command must print nothing):

     ```bash
     R=docs/REPORT7_FINAL_PROJECT_REPORT.md
     grep -oE '^##### Table [0-9]+' $R | grep -oE '[0-9]+' | awk '$1!=NR{print "table gap at",NR,"found",$1}'
     grep -oE '^\*Figure [0-9]+' $R | grep -oE '[0-9]+' | awk '$1!=NR{print "figure gap at",NR,"found",$1}'
     ```
6. **Cross-references stay consistent.** The same fact appears in several places (plan quotas, ports, service list, table counts, test counts, guest limits, AI provider). After changing it, search `docs/REPORT7_FINAL_PROJECT_REPORT.md` for the old value and fix every occurrence.
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

Update the V.4 suites table, its total, V.5.1 and the metrics table (VII.3.1). The report counts annotations; parameterized tests run more than once, so Maven can report a higher number (say so when you quote a run). Only claim tests *pass* if you ran `mvn test` for that service in this session and saw it succeed; identity, nutrition, blog and location tests need a MySQL 8.4 instance. If an IDE compiled the project, run `mvn clean test` to avoid stale classes.

### Facts that must match the code (quick checklist)

Check these when relevant; they are the values most likely to drift:

- Ports: gateway 8080 (host 9080), identity 8081, nutrition 8082, blog 8083, recipe 8084, location 8085, ai 8086, payment 8087, MySQL host 4307, Ngrok inspector host 5041.
- Plans and quotas in `PlanCatalogInitializer` (payment-service); guest limits in `ai-service` `application.properties`.
- AI provider and model settings in `ai-service` `application.properties`, `backend/.env.example` and `backend/ai-inference/`.
- Security: BCrypt cost in identity `SecurityConfig`, JWT algorithm and lifetime in identity `JwtService`.
- Gateway routes in `backend/api-gateway/src/main/resources/application.properties`.
- Database schemas and tables: entities (`@Table`) and `backend/ai-service/src/main/resources/db/migration`; seed data in each `data.sql`.
- Environment variables: `backend/.env.example`.
- CI jobs: `.github/workflows/ci-cd.yml`.
- Web routes: `frontend/src/app/routes.jsx`; mobile screens: `mobile/lib/features/*/presentation` and `mobile/lib/navigation`.

### Team and metadata

The cover page and the project team table (I.1.2) are maintained by the team. Do not change names, student IDs, e-mails, group or the lecturer unless the user asks.

## Working in this repository

- Backend conventions, commands and gotchas: `backend/CLAUDE.md`. Frontend conventions: `frontend/CLAUDE.md`. Follow them when editing those areas.
- Each backend service is an independent Maven project (no parent POM); run Maven from inside the service directory.
- Do not commit secrets. `.env` files stay local; only `.env.example` is tracked.
- Commit only when the user asks. When you do, include the report change in the same commit as the code change it documents.
