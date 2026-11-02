# TRƯỜNG ĐẠI HỌC FPT / FPT UNIVERSITY
## MINISTRY OF EDUCATION AND TRAINING

**STARS RATED FOR EXCELLENCE 2012**  
**Ho Chi Minh City, November 2026**

---

### Final Project Report (Report 7)
# Lens: Photography Booking Marketplace
**Web Applications, Customer and Creator Mobile Apps, Backend Services**

* **Group Name:** Group 3 - Lens Project Team
* **Group Members:**
  * Đỗ Nguyễn Nhĩ Anh – SE194580 (Leader, Backend Developer, DevOps)
  * Nguyễn Nhật Trường – SE193452 (Backend Developer)
  * Nguyễn Phúc Thịnh – SE193641 (Frontend Developer)
  * Nguyễn Như Lâm Dũng – SE193281 (Mobile Developer)
* **Supervisor:** Nguyễn Xuân Huy (HuyNX23)
* **Ext Supervisor:** $N/A$
* **Course / Class:** PRM393 - Mobile Programming / SE1923
* **Source Code:** [github.com/LensExe](https://github.com/LensExe) (6 repositories)

---

## Table of Contents

- [I. Project Introduction](#i-project-introduction)
  - [1. Overview](#1-overview)
    - [1.1 Project Information](#11-project-information)
    - [1.2 Project Team](#12-project-team)
  - [2. Product Background](#2-product-background)
  - [3. Existing Systems](#3-existing-systems)
  - [4. Business Opportunity](#4-business-opportunity)
  - [5. Software Product Vision](#5-software-product-vision)
  - [6. Project Scope & Limitations](#6-project-scope--limitations)
    - [6.1 Major Features](#61-major-features)
    - [6.2 Limitations and Exclusions](#62-limitations-and-exclusions)
- [II. Project Management Plan](#ii-project-management-plan)
  - [1. Overview](#1-overview-1)
    - [1.1 Scope & Estimation](#11-scope--estimation)
    - [1.2 Project Objectives](#12-project-objectives)
    - [1.3 Project Risks](#13-project-risks)
  - [2. Management Approach](#2-management-approach)
    - [2.1 Project Process](#21-project-process)
    - [2.2 Quality Management](#22-quality-management)
    - [2.3 Training Plan](#23-training-plan)
  - [3. Master Schedule](#3-master-schedule)
  - [4. Responsibility Assignments](#4-responsibility-assignments)
  - [5. Project Communications](#5-project-communications)
  - [6. Configuration Management](#6-configuration-management)
    - [6.1 Document Management](#61-document-management)
    - [6.2 Source Code Management](#62-source-code-management)
    - [6.3 Tools & Infrastructures](#63-tools--infrastructures)
- [III. Software Requirement Specification](#iii-software-requirement-specification)
  - [1. Product Overview](#1-product-overview)
  - [2. User Requirements](#2-user-requirements)
    - [2.1 Actors](#21-actors)
    - [2.2 Use Cases](#22-use-cases)
  - [3. Functional Requirements](#3-functional-requirements)
    - [3.1 System Functional Overview](#31-system-functional-overview)
    - [3.2 Account and Authentication](#32-account-and-authentication)
    - [3.3 Discovery and Photographer Profile](#33-discovery-and-photographer-profile)
    - [3.4 Booking](#34-booking)
    - [3.5 Payment and Wallet](#35-payment-and-wallet)
    - [3.6 Delivery and Review](#36-delivery-and-review)
    - [3.7 Report and Dispute](#37-report-and-dispute)
    - [3.8 Chat, AI Assistant and Notifications](#38-chat-ai-assistant-and-notifications)
    - [3.9 Photographer Studio](#39-photographer-studio)
    - [3.10 Administration](#310-administration)
  - [4. Non-Functional Requirements](#4-non-functional-requirements)
    - [4.1 External Interfaces](#41-external-interfaces)
    - [4.2 Quality Attributes](#42-quality-attributes)
  - [5. Requirement Appendix](#5-requirement-appendix)
    - [5.1 Business Rules](#51-business-rules)
    - [5.2 Common Requirements](#52-common-requirements)
    - [5.3 Application Messages List](#53-application-messages-list)
- [IV. Software Design Description](#iv-software-design-description)
  - [1. System Design](#1-system-design)
    - [1.1 System Architecture](#11-system-architecture)
    - [1.2 Package Diagram](#12-package-diagram)
  - [2. Database Design](#2-database-design)
    - [2.1 Normalisation (1NF, 2NF, 3NF)](#21-normalisation-1nf-2nf-3nf)
    - [2.2 Table Descriptions](#22-table-descriptions)
    - [2.3 Seed Data](#23-seed-data)
  - [3. API Design](#3-api-design)
  - [4. Detailed Design](#4-detailed-design)
    - [4.1 Authentication and Session](#41-authentication-and-session)
    - [4.2 Booking](#42-booking)
    - [4.3 Payment and Wallet](#43-payment-and-wallet)
    - [4.4 Delivery and Confirm Receipt](#44-delivery-and-confirm-receipt)
    - [4.5 Report and Dispute](#45-report-and-dispute)
    - [4.6 Photographer Application and Verification](#46-photographer-application-and-verification)
    - [4.7 AI Auto-Reply with a Self-Hosted LLM](#47-ai-auto-reply-with-a-self-hosted-llm)
- [V. Software Testing Documentation](#v-software-testing-documentation)
  - [1. Scope of Testing](#1-scope-of-testing)
  - [2. Test Strategy](#2-test-strategy)
    - [2.1 Testing Types](#21-testing-types)
    - [2.2 Test Levels](#22-test-levels)
    - [2.3 Supporting Tools](#23-supporting-tools)
  - [3. Test Plan](#3-test-plan)
    - [3.1 Human Resources](#31-human-resources)
    - [3.2 Test Environment](#32-test-environment)
    - [3.3 Test Milestones](#33-test-milestones)
  - [4. Test Cases](#4-test-cases)
  - [5. Test Reports](#5-test-reports)
    - [5.1 Execution Results](#51-execution-results)
    - [5.2 Code Coverage](#52-code-coverage)
    - [5.3 Continuous Integration](#53-continuous-integration)
- [VI. Release Package & User Guides](#vi-release-package--user-guides)
  - [1. Deliverable Package](#1-deliverable-package)
  - [2. Installation Guides](#2-installation-guides)
    - [2.1 System Requirements](#21-system-requirements)
    - [2.2 Installation Instruction](#22-installation-instruction)
  - [3. User Manual](#3-user-manual)
    - [3.1 Overview](#31-overview-2)
    - [3.2 Guest](#32-guest)
    - [3.3 Customer](#33-customer)
    - [3.4 Photographer](#34-photographer)
    - [3.5 Administrator](#35-administrator)
- [VII. Appendix](#vii-appendix)
  - [1. Glossary](#1-glossary)
  - [2. References](#2-references)

---

## List of Figures

* **Figure 1:** Context diagram of the Lens platform
* **Figure 2:** Overall use case diagram of the Lens platform
* **Figure 3:** Screen flow of the Customer App
* **Figure 4:** Screen flow of the Creator App
* **Figure 5:** Screen flow of the web applications (Landing, Portal, Admin)
* **Figure 6:** Conceptual entity relationship diagram
* **Figure 7:** Creator App - photographer application form
* **Figure 8:** Portal - login screen
* **Figure 9:** Admin web application - login screen
* **Figure 10:** Portal - profile settings
* **Figure 11:** Landing page (lens.id.vn)
* **Figure 12:** Portal - browse photographers
* **Figure 13:** Portal - photographer profile
* **Figure 14:** State diagram of a booking
* **Figure 15:** Portal - booking form, step 1 (package and schedule)
* **Figure 16:** Portal - customer bookings
* **Figure 17:** Portal - wallet
* **Figure 18:** Portal - customer reviews
* **Figure 19:** Portal - messages
* **Figure 20:** System architecture of the Lens platform
* **Figure 21:** Package diagram of the backend (lens-be)
* **Figure 22:** Package diagram of the mobile applications and the web monorepo
* **Figure 23:** Database diagram - identity and photographer domain
* **Figure 24:** Database diagram - booking, media and feedback domain
* **Figure 25:** Database diagram - payment, wallet and subscription domain
* **Figure 26:** Database diagram - AI database and system tables
* **Figure 27:** Swagger UI of the deployed Core API (api.lens.id.vn/docs)
* **Figure 28:** Sequence diagram - log in and token refresh
* **Figure 29:** Class diagram of the booking feature
* **Figure 30:** Sequence diagram - book a photo session
* **Figure 31:** Sequence diagram - photographer accepts or rejects a booking
* **Figure 32:** Class diagram of the payment and wallet feature
* **Figure 33:** Sequence diagram - pay the deposit with VietQR
* **Figure 34:** Sequence diagram - deliver the gallery and confirm receipt
* **Figure 35:** Class diagram of the report and moderation feature
* **Figure 36:** Sequence diagram - report a booking issue and admin resolution
* **Figure 37:** Sequence diagram - photographer application and verification
* **Figure 38:** Sequence diagram - AI auto-reply with retrieval-augmented generation
* **Figure 39:** CI/CD pipeline (GitHub Actions $\rightarrow$ GHCR $\rightarrow$ Portainer)
* **Figure 40:** GitHub Actions run history of LensExe/lens-be
* **Figure 41:** Customer App - Discover tab
* **Figure 42:** Customer App - photographer profile
* **Figure 43:** Customer App - packages and introduction
* **Figure 44:** Customer App - booking wizard, step 1
* **Figure 45:** Customer App - bookings with status tabs
* **Figure 46:** Customer App - booking detail
* **Figure 47:** Portal - customer overview
* **Figure 48:** Customer App - conversations
* **Figure 49:** Customer App - chat with a photographer
* **Figure 50:** Customer App - notification centre
* **Figure 51:** Customer App - overview
* **Figure 52:** Customer App - account and settings
* **Figure 53:** Customer App - wallet
* **Figure 54:** Creator App - login screen

---

## List of Tables

* **Table 1:** Definitions and acronyms
* **Table 2:** Project information
* **Table 3:** Source code repositories
* **Table 4:** Project team
* **Table 5:** Comparison with existing ways to book a photographer
* **Table 6:** Major features by client
* **Table 7:** Scope and effort estimation
* **Table 8:** Project objectives and target metrics
* **Table 9:** Project risks and responses
* **Table 10:** Training plan
* **Table 11:** Master schedule
* **Table 12:** Responsibility assignment matrix
* **Table 13:** Communication plan
* **Table 14:** Tools and infrastructure
* **Table 15:** System actors
* **Table 16:** Use case descriptions
* **Table 17:** Screen descriptions - Customer App
* **Table 18:** Screen descriptions - Creator App
* **Table 19:** Screen descriptions - Landing page and Portal
* **Table 20:** Screen descriptions - Admin web application
* **Table 21:** Screen and activity authorization
* **Table 22:** Non-screen functions (background jobs and services)
* **Table 23:** Entity descriptions
* **Table 24:** Software interfaces
* **Table 25:** Business rules
* **Table 26:** Common requirements
* **Table 27:** Application messages
* **Table 28:** Architecture components
* **Table 29:** Backend package descriptions
* **Table 30:** Client package descriptions
* **Table 31:** Intentional exceptions to 3NF
* **Table 32:** Table descriptions - identity and photographer
* **Table 33:** Table descriptions - booking, media and feedback
* **Table 34:** Table descriptions - payment, wallet and subscription
* **Table 35:** Table descriptions - AI database (lens_ai)
* **Table 36:** API operations by module
* **Table 37:** Class specifications - booking feature
* **Table 38:** Class specifications - payment and wallet feature
* **Table 39:** Class specifications - report and moderation feature
* **Table 40:** AI safeguards
* **Table 41:** Testing types
* **Table 42:** Test types per test level
* **Table 43:** Test supporting tools
* **Table 44:** Testing roles
* **Table 45:** Test environment
* **Table 46:** Test milestones
* **Table 47:** Automated test suites
* **Table 48:** Selected Core API unit test cases
* **Table 49:** Selected Core API integration test cases (real PostgreSQL, Redis, MinIO)
* **Table 50:** Selected Customer App test cases
* **Table 51:** Selected Creator App test cases
* **Table 52:** Chat Service test cases
* **Table 53:** Test execution results
* **Table 54:** Code coverage
* **Table 55:** GitHub Actions workflow runs per repository
* **Table 56:** Deliverable package
* **Table 57:** System requirements
* **Table 58:** Glossary

---

## Acknowledgement

We would like to thank our lecturer, Mr. Nguyễn Xuân Huy (HuyNX23), for his guidance throughout the PRM393 - Mobile Programming course. His questions about how each part of a system really works in code, how it is tested and how it behaves under load shaped many of the design decisions described in this report.

We also thank FPT University for the learning environment, and the friends, freelance photographers and fellow students who tried early versions of Lens and gave us honest feedback about booking a photo shoot in practice.

This report describes the complete Lens platform built by Group 3: the web applications, the customer and creator mobile applications, and the backend services that support them.

---

## Definitions and Acronyms

The following table defines the abbreviations used in this report and in the Lens source code.

##### Table 1: Definitions and acronyms

| Acronym | Definition |
| :--- | :--- |
| AI | Artificial Intelligence |
| API | Application Programming Interface |
| BR | Business Rule |
| CI/CD | Continuous Integration / Continuous Delivery |
| CQRS | Command Query Responsibility Segregation |
| CSRF | Cross-Site Request Forgery |
| DB | Database |
| DTO | Data Transfer Object |
| ERD | Entity Relationship Diagram |
| FK/PK/UQ | Foreign Key / Primary Key / Unique constraint |
| GHCR | GitHub Container Registry |
| JWT | JSON Web Token |
| LLM | Large Language Model |
| NF | Normal Form (1NF, 2NF, 3NF) |
| OIDC | OpenID Connect |
| ORM | Object Relational Mapping |
| OTP | One-Time Password |
| RAG | Retrieval-Augmented Generation |
| REST | Representational State Transfer |
| S3 | Simple Storage Service (object storage API, implemented by MinIO) |
| SDD | Software Design Description |
| SPA | Single-Page Application |
| SRS | Software Requirement Specification |
| TTL | Time To Live |
| UC | Use Case |
| VIP | Paid photographer subscription plan with extra storage and visibility |
| VietQR | Vietnamese QR bank-transfer standard used by PayOS and SePay |

---

## I. Project Introduction

Lens is a two-sided marketplace that connects customers who need photography services with independent photographers in Vietnam. A customer discovers photographers, compares portfolios and packages, books a time slot, pays a deposit by VietQR, receives the delivered photos inside the platform and finally reviews the service. A photographer manages a public profile, packages, a working calendar, booking requests, photo delivery, a wallet and an optional AI assistant that answers customers while the photographer is offline. An administrator verifies photographers, follows bookings and payments, processes refunds and withdrawals, and resolves reports.

The platform is delivered through four clients - a landing page, a web portal, an admin web application and two Flutter mobile applications that all use the same set of backend services. This chapter introduces the project, its background and its scope.

### 1. Overview

#### 1.1 Project Information

##### Table 2: Project information

| Item | Value |
| :--- | :--- |
| Project name | Lens - Photography Booking Marketplace |
| Project code | LENS |
| Course / class | PRM393 - Mobile Programming, class SE1923, Fall 2026 |
| Group | Group 3 - Lens Project Team (4 members) |
| Lecturer | Nguyễn Xuân Huy (HuyNX23) |
| Clients | Landing page `lens.id.vn`, Portal `app.lens.id.vn`, Admin `admin.lens.id.vn`, Customer App (Android/iOS), Creator App (Android/iOS) |
| Backend services | Core API and AI Worker (NestJS), Chat Service (Go), Notification Service (NestJS) |
| Public API | `https://api.lens.id.vn/api/v1`, Swagger UI at `https://api.lens.id.vn/docs` (154 operations) |
| Source code | GitHub organisation `LensExe`, six repositories (Table 3) |
| Project duration | 08 September 2026 - 02 November 2026 |

##### Table 3: Source code repositories

| Repository | Content |
| :--- | :--- |
| `github.com/LensExe/lens-be` | Core API and AI Worker (NestJS, TypeScript) |
| `github.com/LensExe/Lens-web` | Landing page, Portal and Admin web applications (React, Vite) |
| `github.com/LensExe/lens-mobile` | Customer mobile application (Flutter) |
| `github.com/LensExe/lens-creator-mobile` | Creator (photographer) mobile application (Flutter) |
| `github.com/LensExe/lens-chat-service` | Chat Service (Go, Gin, MongoDB) |
| `github.com/LensExe/lens-notification-service` | Notification Service (NestJS, MongoDB, Socket.IO) |

#### 1.2 Project Team

##### Table 4: Project team

| # | Full name | Student code | Role in the project |
| :-: | :--- | :-: | :--- |
| 1 | Đỗ Nguyễn Nhĩ Anh | SE194580 | Leader, Backend Developer, DevOps |
| 2 | Nguyễn Nhật Trường | SE193452 | Backend Developer |
| 3 | Nguyễn Phúc Thịnh | SE193641 | Frontend Developer |
| 4 | Nguyễn Như Lâm Dũng | SE193281 | Mobile Developer |

Stakeholders outside the team are the lecturer (evaluator), customers and photographers (end users), the platform administrator, and the external service providers: Keycloak and Google for identity, PayOS and SePay for payments, an S3-compatible object store for photos, and Mailgun/SendGrid for e-mail.

### 2. Product Background

In Vietnam most photography jobs are still arranged through Facebook groups, Instagram and Zalo chats. A customer scrolls through many posts, messages several photographers to ask for prices and free dates, transfers a deposit to a personal bank account and then waits for a Google Drive link with the photos. Nothing in that flow protects either side: double bookings happen, deposits are hard to recover, photos are shared through public links and there is no reliable review history.

Photographers face the opposite problem. They answer the same questions about prices, locations and delivery times many times a day, keep their schedule in a notebook or a spreadsheet, chase customers for the remaining payment and have no simple way to show a verified track record. Lens moves the whole journey - discovery, booking, payment, delivery, review and dispute - into one platform in which the server is the single source of truth for availability, money and photo access.

### 3. Existing Systems

##### Table 5: Comparison with existing ways to book a photographer

| System | Strengths | Weaknesses addressed by Lens |
| :--- | :--- | :--- |
| Facebook / Instagram groups | Large audience, free to post, rich portfolios | No structured prices or calendar, no protected payment, no verified reviews |
| Zalo / Messenger | Fast negotiation and familiar to everyone | Agreements are lost in chat; no booking record, status or deadline |
| Pixieset, ShootProof (international) | Professional galleries and client proofing | Photographer-side tools only; not localised for VND and VietQR; no marketplace |
| Local studio websites | Brand presentation and fixed price lists | One studio only; booking by phone or form; no escrow or dispute handling |
| Google Calendar and bank transfer | Free and familiar tools | Manual and error-prone; no overlap protection, no escrow, no delivery tracking |

### 4. Business Opportunity

Demand for graduation, couple, pre-wedding, event and product photography is high among students and young professionals, while supply is fragmented across thousands of freelancers. A platform that guarantees that (1) a slot cannot be double-booked, (2) the deposit is held safely until the job is done, (3) photos are delivered privately and (4) reviews come only from real bookings removes the main sources of distrust between the two sides.

Lens earns revenue in two ways that are already implemented: a commission on each completed booking, whose percentage depends on the photographer rank (`ranks.commission_percent`), and VIP subscription plans for photographers (`photographer_plans`) that add storage and visibility. Running the AI assistant on a self-hosted model keeps the marginal cost of automated replies close to zero.

### 5. Software Product Vision

For customers who want a trustworthy photographer and for photographers who want a predictable business, Lens is a photography booking marketplace available on the web and on mobile that turns a photo shoot into a guided and protected transaction, from the first search to the delivered photos. Unlike social networks and chat groups, Lens checks availability on the server, keeps every payment in escrow until the job is done, delivers photos through private links and lets a self-hosted AI assistant answer routine questions when the photographer is offline.

### 6. Project Scope & Limitations

#### 6.1 Major Features

##### Table 6: Major features by client

| Client/service | Major features |
| :--- | :--- |
| Landing page | Product introduction, featured photographers, call-to-action to the portal. |
| Portal (web) | **Customer workspace:** browse photographers, profile, booking form, deposit and payment, bookings, gallery, reviews.<br>**Photographer studio:** dashboard, booking management, availability, portfolio, packages, storage (VIP), achievements, AI assistant.<br>**Shared:** messages, wallet, settings. |
| Admin (web) | Overview dashboard, users, photographer approvals and application review, bookings, finance (refunds and withdrawals), reports and disputes, quality (ranks and AI), storage, system notifications. |
| Customer App | Discovery with filters, photographer detail, 3-step booking wizard, VietQR or wallet payment, bookings with timeline, cancellation, delivered gallery, confirm receipt, reviews, report an issue with evidence, chat with AI auto-reply badge, notifications, wallet, settings. |
| Creator App | Registration with a photographer application, dashboard, booking requests (accept, reject, start, complete), gallery upload and publish, packages, working calendar, portfolio, chat, AI assistant settings, achievements, VIP storage, wallet, settings. |
| Core API and AI Worker | Identity (Keycloak), photographers, calendar, booking lifecycle, payment and escrow, wallet, refunds, media, delivery, reviews, reports and moderation, subscriptions, ranks and badges, scheduled jobs, transactional outbox, AI auto-reply with a local LLM. |
| Chat Service | Direct conversations between a customer and a photographer, message history in MongoDB, chat events to Kafka, internal API for AI replies. |
| Notification Service | Consumes domain events from Kafka, stores notifications, pushes them in real time through Socket.IO and sends transactional e-mails. |

#### 6.2 Limitations and Exclusions

* Mobile push notifications (FCM/APNs) are not used; notifications are delivered in real time through Socket.IO while an application is open and are listed in the notification centre afterwards.
* Deep links are not configured in the mobile applications, so a completed VietQR payment is detected through a socket event, a refresh when the application resumes or the "check status" action.
* Only one payment provider is active at a time (PayOS or SePay), selected by configuration; both use VietQR bank transfer in VND. Card and e-wallet payments are not supported.
* The AI assistant answers in Vietnamese and only about the photographer's own profile, packages and FAQ; complaints, payments and booking changes are always handed off to the photographer.
* The platform targets Vietnam: one currency (VND), one time zone (UTC+7) and a Vietnamese user interface.

---

## II. Project Management Plan

This chapter describes how the team planned, organised and controlled the work on the six Lens repositories: scope and estimation, objectives, risks, process, schedule, responsibilities, communication and configuration management.

### 1. Overview

#### 1.1 Scope & Estimation

Each work package was classified as Simple, Medium or Complex and estimated in man-days (one man-day is six hours of focused work). Table 7 lists the estimate per component.

##### Table 7: Scope and effort estimation

| # | Work package | Main deliverables | Complexity | Effort (man-day) |
| :-: | :--- | :--- | :-: | :-: |
| 1 | Identity and access | Keycloak realm and roles, register, login, refresh, Google login, OTP password reset, global JWT guard | Medium | 6 |
| 2 | Photographer domain | Profile, application and verification, packages, portfolio, ranks, badges, ratings, discovery with cache | Medium | 8 |
| 3 | Calendar and booking lifecycle | Availability, offline slots, row locking, state machine, history, booking jobs | Complex | 12 |
| 4 | Payment, escrow and wallet | PayOS/SePay adapters, payment intents, webhooks, escrow, ledger, refunds, withdrawals | Complex | 12 |
| 5 | Media and delivery | Presigned upload/download, variants queue, gallery publish, storage quota | Medium | 6 |
| 6 | Reviews, reports and moderation | Reviews and replies, reports with evidence, admin resolution, account suspension | Medium | 5 |
| 7 | Subscriptions (VIP) | Plans, plan snapshot, payment activation, expiry job | Simple | 3 |
| 8 | AI Worker | Kafka consumer, BullMQ queue, Ollama client, pgvector knowledge base, safeguards | Complex | 8 |
| 9 | Chat Service | Go service, MongoDB, direct channels, outbox to Kafka, internal AI reply API | Medium | 5 |
| 10 | Notification Service | Kafka consumers, MongoDB, Socket.IO gateway, e-mail templates and queue | Medium | 5 |
| 11 | Web applications | Landing page, Portal (customer and photographer), Admin, shared UI package | Complex | 18 |
| 12 | Customer App | All customer screens, session handling, payment and realtime integration | Complex | 16 |
| 13 | Creator App | All photographer screens, gallery upload, calendar, AI assistant settings | Complex | 14 |
| 14 | DevOps | Dockerfiles, Compose stacks, Kong and Caddy, GitHub Actions, GHCR, Portainer | Medium | 7 |
| 15 | Testing and documentation | Unit, integration, contract and Flutter tests, Swagger, report, slides | Medium | 9 |
| | **Total** | | | **134** |

#### 1.2 Project Objectives

The overall objective is to deliver a working marketplace in which a customer can find, book, pay, receive and review a photo shoot, a photographer can run the whole job from a phone or the web, and an administrator can control quality and money - with every business rule enforced on the server. Table 8 gives the measurable targets.

##### Table 8: Project objectives and target metrics

| Area | Target | Result |
| :--- | :--- | :--- |
| Quality - backend | All automated backend tests pass; line coverage $\ge 60\%$ of the code exercised by unit tests | $140/140$ tests pass; 62.83% line coverage |
| Quality - mobile | All Flutter tests of both applications pass | $116/116$ tests pass |
| Quality - services | Chat and Notification Service tests pass in CI | $4/4$ and $34/34$ tests pass |
| Data integrity | No double booking and no duplicated payment effect under concurrent requests | Proved by integration tests on a real PostgreSQL database |
| Delivery | All four clients and services deployed before 02/11/2026 | Deployed under `lens.id.vn`; Android App Bundles built for both apps |
| Effort distribution | Requirements 10%, design 15%, coding 50%, testing 15%, management 10% | Followed approximately |

#### 1.3 Project Risks

##### Table 9: Project risks and responses

| # | Risk | Impact | Response |
| :-: | :--- | :-: | :--- |
| 1 | Two customers book the same slot at the same moment | High | Lock the photographer row (`SELECT ... FOR NO KEY UPDATE`) inside one transaction before checking overlaps; covered by an integration test with parallel requests. |
| 2 | A payment webhook is delivered twice or with a wrong amount | High | Verify the provider signature and the exact amount; insert `(provider, reference)` into `payment_webhooks` with a unique constraint so a replay has no effect. |
| 3 | Paid AI APIs are expensive and send customer data to a third party | High | Run Ollama with small Qwen models on our own Docker host; no external AI API is called. |
| 4 | Private photos leak through guessable links | Medium | Objects are private; short-lived presigned URLs (900 seconds) are issued only after an ownership check. |
| 5 | Six repositories drift apart (API contract changes) | Medium | Swagger generated from code, an OpenAPI contract test and an API tracker file; clients use one envelope format. |
| 6 | Team members new to NestJS, Go or Flutter | Medium | Training plan (Section 2.3), pair programming and architecture documents in each repository. |
| 7 | A single server becomes a bottleneck | Medium | Stateless API behind Kong, background work in queues, advisory locks on cron jobs so more replicas can be added safely. |

### 2. Management Approach

#### 2.1 Project Process

The team used a lightweight Scrum process with two-week iterations. Each iteration started with planning from the backlog and ended with a demonstration of working software on the deployed environment. The backend was split by bounded context (booking, calendar, payment, media, moderation, identity and others), and each client was split by screen group. A feature followed the same path through all repositories:

1. Refine the user story, its acceptance criteria and its business rules.
2. Design the API contract (DTO and Swagger) and the database change (SQL migration).
3. Implement the backend: controller $\rightarrow$ command/query handler $\rightarrow$ use case $\rightarrow$ domain rules, with unit tests.
4. Open a pull request; GitHub Actions runs type checks, tests and Docker image builds.
5. Implement the screens in the web portal and the mobile applications against the deployed API, with tests.
6. Demonstrate at the end of the iteration; defects return to the backlog.

#### 2.2 Quality Management

* **Static checks:** strict TypeScript, ESLint and Prettier in the NestJS and React repositories and the Dart analyzer (`flutter analyze`) in the Flutter applications; Conventional Commits enforced by commitlint in the backend.
* **Layered design:** business rules live in pure `*.domain.ts` classes so they can be tested without a database; Flutter screens never call the HTTP client directly.
* **Automated tests:** backend unit, integration and OpenAPI contract tests; Flutter unit and widget tests in both applications; Jest tests in the Notification Service; Go tests in the Chat Service.
* **Continuous integration:** every push and pull request to the main branch of the backend, web, chat and notification repositories runs a GitHub Actions workflow.
* **Code review:** changes reach the release branch through pull requests reviewed by another member.

#### 2.3 Training Plan

##### Table 10: Training plan

| Topic | Trainees | Method |
| :--- | :--- | :--- |
| NestJS modules, CQRS, TypeORM transactions | Backend | Pair programming on the booking module; architecture guide in `lens-be/docs` |
| Flutter, Riverpod, go_router, Dio interceptors | Mobile | Small spike application, then a shared project structure for both apps |
| React, TanStack Query, Vite | Backend, Mobile | Walk-through of the Lens-web monorepo and its shared UI package |
| Keycloak, OIDC and JWT | All | Internal session with the local Keycloak container and test realm |
| Docker, Kong, GitHub Actions | All | Leader walk-through of the Compose files, gateway configuration and CI workflows |
| Ollama, embeddings and RAG | Backend | Experiments with local models and the AI worker documentation |

### 3. Master Schedule

##### Table 11: Master schedule

| Iteration | Dates | Main results |
| :-: | :-: | :--- |
| 1 | 08/09 - 21/09 | Requirements and architecture; repositories and Docker Compose for PostgreSQL, Redis, MinIO and Keycloak; identity module. |
| 2 | 22/09 - 05/10 | Packages, calendar and booking lifecycle; photographer application; payment module; media queue; subscriptions and refunds; first screens of both mobile applications and of the portal. |
| 3 | 06/10 - 19/10 | GitHub Actions CI/CD for all services; Chat and Notification Services; Kong gateway; AI worker; mobile applications connected to the real API; first Android release builds. |
| 4 | 20/10 - 02/11 | Admin web application; wallet payout destinations; booking reports and disputes in all clients; Swagger through the gateway; full test runs, report and presentation. |

### 4. Responsibility Assignments

##### Table 12: Responsibility assignment matrix

| Work item | Nhĩ Anh | Trường | Dũng | Thịnh |
| :--- | :-: | :-: | :-: | :-: |
| Project management and architecture | **A/R** | S | S | S |
| Core API - identity, payment, wallet, media, moderation, subscriptions | **A/R** | S | | |
| Core API - photographers, calendar, booking, reviews | **A** | **R** | | |
| AI Worker, Chat Service, Notification Service | **A/R** | S | | |
| DevOps: Docker, Kong, Caddy, CI/CD, deployment | **A/R** | | | |
| Web applications (Landing, Portal, Admin) | **A/R** | S | | **R** |
| Customer App | **A** | | **R** | S |
| Creator App | **A** | | **R** | S |
| Backend automated tests and API documentation | **A** | **R** | | |
| Mobile automated tests | **A** | | **R** | S |
| Report and presentation | **A** | S | S | **R** |

*(Legend: **A** = Accountable, **R** = Responsible, **S** = Supporting)*

### 5. Project Communications

##### Table 13: Communication plan

| Channel | Frequency | Purpose |
| :--- | :--- | :--- |
| Zalo group | Daily | Quick questions, blockers, deployment notices |
| Online meeting (Google Meet) | Weekly and at iteration end | Planning, demonstration, retrospective |
| GitHub pull requests | Per change | Code review, CI results, discussion of API changes |
| Class sessions with the lecturer | Weekly | Progress check and feedback |

### 6. Configuration Management

#### 6.1 Document Management

Technical documents are kept next to the code: the backend has an architecture guide, a module breakdown, AI worker, payment and secrets documents in `lens-be/docs`; Lens-web has deployment and design notes; each service has a README with its configuration. Report drafts and slides are kept in the team drive. Every diagram in this report has an editable draw.io source file delivered with the report.

#### 6.2 Source Code Management

* Git on the GitHub organisation `LensExe` with six repositories (Table 3). Each repository has a release branch protected by CI and short-lived feature branches named after the module or screen group.
* The team follows Conventional Commit messages (`feat(wallet): ...`, `fix: ...`); in the backend they are enforced by commitlint.
* Secrets are never committed: runtime environment files are encrypted with SOPS/Age, and the Android signing configuration (`key.properties`) is excluded from Git.
* Database changes are versioned SQL migrations applied by a migration script that records a checksum for every file, separately for the business database and the AI database.

#### 6.3 Tools & Infrastructures

##### Table 14: Tools and infrastructure

| Category | Tools and versions |
| :--- | :--- |
| Core API, AI Worker | Node.js 22, NestJS 12, TypeScript 5.9, TypeORM, `@nestjs/cqrs`, BullMQ, class-validator, Swagger |
| Chat Service | Go, Gin, MongoDB driver, Kafka client |
| Notification Service | Node.js, NestJS 11, MongoDB (Mongoose), KafkaJS, Socket.IO, Mailgun / SendGrid |
| Web applications | pnpm 11, Turborepo, React 19, Vite, TanStack Query, Tailwind CSS, socket.io-client, MSW |
| Mobile applications | Flutter 3.47 (Dart 3.13), `flutter_riverpod` 3, `go_router` 18, `dio` 5, `socket_io_client`, `flutter_secure_storage`, `image_picker` |
| Data | PostgreSQL 16 with pgvector, Redis 7, MinIO (S3 API), Kafka 3.9, MongoDB |
| Identity and edge | Keycloak 24, Kong 3.9, Caddy |
| AI | Ollama with `qwen3.5:2b` (chat) and `qwen3-embedding:0.6b` (embeddings) |
| DevOps | Docker, Docker Compose, Portainer, GitHub Actions, GitHub Container Registry |
| Testing | `node:test`, `flutter_test`, Jest, `go test`, Bruno API collection, Swagger UI |
| Design and documents | draw.io, Microsoft Word |

---

## III. Software Requirement Specification

### 1. Product Overview

Lens is used by four kinds of people through five clients. Guests and customers use the landing page, the web portal and the Customer App; photographers use the Creator App and the photographer studio of the portal; administrators use the admin web application. All clients talk only to the Lens backend over HTTPS (REST and Socket.IO). The backend owns every business rule and every record of time, money and photos. Identity (Keycloak), photo storage (MinIO) and AI inference (Ollama) are self-hosted inside the platform; only Google sign-in, the payment gateway (PayOS or SePay) and the e-mail provider (Mailgun or SendGrid) are external services.

Figure 1 shows the context diagram of the platform.

```
                    +------------------+
                    |   Google OAuth   |
                    +--------+---------+
                             ^
      Google identity        |        Sign-in
        (ID token)           |        redirect
                             v
+------------+      +------------------+      +------------------+
|   Guest    |----->|                  |----->|      Admin       |
+------------+      |                  |      +------------------+
                    |                  |
+------------+      |   Lens Platform  |      +------------------+
|  Customer  |----->|                  |<-----|   Photographer   |
+------------+      | (Web, Apps, BE)  |      +------------------+
                    |                  |
+------------+      |                  |      +------------------+
|  Payment   |<---->|                  |<---->|  Email Service   |
|  Gateway   |      +------------------+      | (Mailgun/SendGrid|
+------------+                                +------------------+
```
*Figure 1: Context diagram of the Lens platform*

Reading the diagram: guests send search filters and receive photographer profiles; customers send bookings, payments, reviews, reports and chat messages and receive booking status, VietQR checkouts, delivered galleries and notifications; photographers send their profile, packages, calendar, booking decisions and photos and receive requests, earnings and AI reply suggestions; administrators send verification and moderation decisions and receive dashboards and queues. Google OAuth receives sign-in redirects and returns the Google identity of the user, the payment gateway receives payment and payout requests and calls back with signed webhooks, and the e-mail service receives OTP and notification e-mails and returns the delivery status.

Main constraints and assumptions: all clients are served under the domain `lens.id.vn` behind Caddy (TLS) and Kong (API gateway); money is stored as integer VND; times are stored as timestamptz and displayed in Vietnam time (UTC+7); the mobile applications run on Android and iOS phones and require a network connection.

### 2. User Requirements

#### 2.1 Actors

##### Table 15: System actors

| # | Actor | Type | Description |
| :-: | :--- | :-: | :--- |
| 1 | Guest | Primary | Unauthenticated visitor of the landing page, the portal or the Customer App. Can register, log in, reset a password, search photographers and view public profiles. |
| 2 | Customer | Primary | Registered user with the Keycloak role `customer`. Inherits every Guest use case and can book, pay, track and cancel bookings, receive photos, review, report issues, chat and manage a wallet. |
| 3 | Photographer | Primary | User with the role `photographer` after an administrator approves the application. Manages profile, portfolio, packages, calendar, booking requests, galleries, AI assistant, VIP plan and wallet through the Creator App or the portal studio. |
| 4 | Admin | Primary | Platform operator with the role `admin`. Verifies photographers, manages users, monitors bookings and payments, processes refunds and withdrawals, and resolves reports through the admin web application. |
| 5 | System | Secondary | Scheduled jobs, the outbox worker and the AI worker that act without a user: expiring requests, releasing escrow, sending events and replying when a photographer is offline. |
| 6 | Payment Gateway | Secondary | PayOS or SePay. Creates VietQR checkouts and calls the signed webhook when money arrives. |

#### 2.2 Use Cases

##### 2.2.1 Overall Use Case Diagram

*Figure 2: Overall use case diagram of the Lens platform* (`uc Lens Platform`)

How to read the diagram: Customer, Photographer and Admin are all generalisations of Guest, so every registered role can also search photographers and view profiles. `«include»` means the base use case always performs the included one: booking a photo session always checks availability. `«extend»` means optional behaviour at an extension point: logging in with Google extends Log In, attaching evidence extends Report Issue, and the AI auto-reply extends Chat when the photographer is offline. The Payment Gateway participates in Pay for Booking and Subscribe VIP Plan; the System actor runs the AI auto-reply.

##### 2.2.2 Use Case Descriptions

##### Table 16: Use case descriptions

| ID | Use case | Actors | Description |
| :--- | :--- | :--- | :--- |
| UC01 | Register Account | Guest | Create a customer account (name, e-mail, password) or a photographer account with an application; the backend creates the Keycloak user and the matching users row. |
| UC02 | Log In | Guest | Exchange e-mail and password for an access token and a refresh token; web clients keep the session in secure cookies, mobile clients in secure storage. |
| UC03 | Log In with Google | Guest | Extends UC02: sign in through Keycloak Google brokering and return to the client with a one-time code. |
| UC04 | Reset Password | Guest | Request a 6-digit OTP by e-mail, verify it and set a new password. |
| UC05 | Search Photographers | Guest | Search verified photographers by keyword, city, style, rating, price and experience, with sorting and paging. |
| UC06 | View Photographer Profile | Guest | View profile, portfolio, packages, rating summary, badges and reviews of a verified photographer. |
| UC07 | Manage Profile | Customer, Photographer | Update personal information and avatar, change password, verify e-mail and choose notification preferences. |
| UC08 | Manage Wallet & Withdraw | Customer, Photographer | View balance, held balance and ledger, save a payout bank account and request a withdrawal. |
| UC09 | Chat | Customer, Photographer | Exchange real-time messages in a direct conversation between a customer and a photographer. |
| UC10 | AI Auto-Reply | System | Extends UC09: when the photographer is offline and the assistant is enabled, the AI worker answers from the photographer's profile, packages and FAQ. |
| UC11 | Pay for Booking | Customer, Payment Gateway | Pay the 30% deposit or the remaining amount by VietQR or from the wallet; the money is held in escrow. |
| UC12 | Book Photo Session | Customer | Choose a package, a date and a free slot, enter contact and location, and send a booking request. |
| UC13 | Check Availability | Customer | Included by UC12: compute free start times from the package duration, offline slots and reserving bookings. |
| UC14 | Track & Cancel Booking | Customer | Follow bookings by status with a timeline; cancel a pending or accepted booking after seeing the refund preview. |
| UC15 | View & Confirm Gallery | Customer | View and download the delivered photos and confirm receipt, which completes the booking. |
| UC16 | Rate & Review | Customer | Rate overall quality, punctuality and attitude (1-5) and comment on a completed booking; edit within 7 days. |
| UC17 | Report Issue | Customer | Report a problem with a booking by choosing one of seven categories and describing it. |
| UC18 | Attach Evidence | Customer | Extends UC17: upload up to five photos as evidence of the issue. |
| UC19 | Manage Portfolio & Packages | Photographer | Create, edit, reorder and delete portfolio albums and service packages. |
| UC20 | Manage Working Calendar | Photographer | Block and unblock time ranges, with a warning when a block overlaps pending requests. |
| UC21 | Handle Booking Requests | Photographer | Accept or reject requests, start the shoot and mark it done. |
| UC22 | Deliver Photo Gallery | Photographer | Upload photos for a booking and publish the gallery to the customer. |
| UC23 | Configure AI Assistant | Photographer | Turn the assistant on or off, maintain FAQ entries and review the AI reply history. |
| UC24 | Subscribe VIP Plan | Photographer, Payment Gateway | Buy a VIP plan for more storage and visibility; the plan is activated when the payment is confirmed. |
| UC25 | Verify Photographers | Admin | Review photographer applications and approve or reject them with a reason. |
| UC26 | Manage Users | Admin | Search users and suspend, unsuspend or ban accounts. |
| UC27 | Monitor Bookings & Payments | Admin | View dashboards, bookings, payments and storage; cancel a booking with a reason when needed. |
| UC28 | Process Refunds & Withdrawals | Admin | Approve, reject, complete or extend the deadline of refund and withdrawal requests. |
| UC29 | Resolve Reports & Disputes | Admin | Review reports with their evidence and resolve, reject or escalate them; hide abusive reviews. |

### 3. Functional Requirements

#### 3.1 System Functional Overview

##### 3.1.1 Screens Flow

* **Figure 3:** Screen flow of the Customer App (Splash $\rightarrow$ Login/Sign Up $\rightarrow$ Bottom Navigation [Discovery, Overview, Bookings, Messages, More] $\rightarrow$ Booking Wizard $\rightarrow$ Checkout $\rightarrow$ Gallery $\rightarrow$ Review)
* **Figure 4:** Screen flow of the Creator App (Splash $\rightarrow$ Login/Sign Up $\rightarrow$ Dashboard $\rightarrow$ Bookings, Packages, Messages, Calendar, AI Assistant, Storage, Wallet, Settings)
* **Figure 5:** Screen flow of the web applications (Landing `lens.id.vn`, Portal `app.lens.id.vn`, Admin `admin.lens.id.vn`)

##### 3.1.2 Screen Descriptions

##### Table 17: Screen descriptions - Customer App

| # | Feature | Screen | Description |
| :-: | :--- | :--- | :--- |
| 1 | Authentication | Splash | Restores the saved session and opens Discovery or Login. |
| 2 | Authentication | Login | E-mail and password login; links to Sign Up and Forgot Password. |
| 3 | Authentication | Sign Up | Customer registration with name, e-mail and password; the role is fixed to customer. |
| 4 | Authentication | Forgot Password | Three steps: send OTP, verify OTP, set a new password. |
| 5 | Discovery | Discovery (Khám phá) | Search box with debounce, photographer cards with rating and starting price, sort selector, paging. |
| 6 | Discovery | Filter sheet | City, styles, minimum rating, price range, experience and sort order. |
| 7 | Discovery | Overview (Tổng quan) | Counters of bookings by state, to-do cards (payments due), nearest shoot and recommendations. |
| 8 | Discovery | Photographer Detail | Cover, verified badge, rating, tags, tabs Portfolio / Packages & About / Reviews, buttons Message and Book. |
| 9 | Booking | Booking Wizard | Step 1 package, date and start time; step 2 contact and location; step 3 summary, deposit and agreement. |
| 10 | Payment | Deposit / Payment | Payment method (VietQR or wallet), QR code with amount and content, status check. |
| 11 | Booking | Bookings (Lịch đặt) | Search, counters and status tabs; each card shows photographer, time, location, package and total. |
| 12 | Booking | Booking Detail | Booking code and status, photographer contact, cost breakdown, escrow note, progress timeline, actions. |
| 13 | Booking | Cancel dialog | Refund preview and mandatory reason before cancelling. |
| 14 | Delivery | Delivery Gallery | Grid of delivered photos, download, confirm receipt. |
| 15 | Feedback | Reviews | Bookings waiting for a review and submitted reviews; create and edit. |
| 16 | Feedback | Report issue sheet | Category, description and up to five evidence photos. |
| 17 | Communication | Messages (Tin nhắn) | Conversation list with last message, time and unread badge. |
| 18 | Communication | Chat Detail | Message thread, input box, AI-reply badge on messages written by the assistant. |
| 19 | Communication | Notification Center | Notifications with type and time, mark one or all as read. |
| 20 | Account | More (Khác) | Account card, links to wallet, reviews, profile, security, notification preferences, help and logout. |
| 21 | Account | Wallet | Available and held balance, wallet history, withdrawal request. |
| 22 | Account | Settings / Email Verification | Profile fields, avatar upload, change password, notification preferences, e-mail OTP. |

##### Table 18: Screen descriptions - Creator App

| # | Feature | Screen | Description |
| :-: | :--- | :--- | :--- |
| 1 | Authentication | Splash | Restores the session and routes to the dashboard or login. |
| 2 | Authentication | Login | E-mail and password, Google sign-in, forgot password. |
| 3 | Authentication | Sign Up (photographer application) | Name, working area, photography styles, e-mail and password; the application waits for admin review. |
| 4 | Authentication | Google callback / Forgot Password | Completes Google sign-in; OTP-based password reset. |
| 5 | Dashboard | Home (Trang chủ) | Verification state, today's and upcoming shoots, pending requests, earnings summary. |
| 6 | Dashboard | Notifications | Booking, payment and system notifications. |
| 7 | Booking | Bookings (Lịch đặt) | Requests and bookings grouped by status. |
| 8 | Booking | Booking Detail | Customer, time, location, package, payment state; actions accept, reject, start and complete. |
| 9 | Delivery | Gallery Upload & Publish | Select photos, upload with progress, publish when the package photo count is reached and the booking is fully paid. |
| 10 | Packages | Packages (Gói chụp) | List of packages with price, duration and status. |
| 11 | Packages | Package Editor | Name, description, price, duration, number of photos, delivery days, features. |
| 12 | Communication | Messages / Chat Detail | Conversations with customers, read receipts, sending messages. |
| 13 | Studio | Working Calendar (Lịch làm việc) | Calendar of bookings and blocked times; add or remove a blocked range. |
| 14 | Studio | Storage (VIP) | Storage usage, VIP plans and subscription history; buy a plan by VietQR. |
| 15 | Studio | Achievements (Thành tựu) | Rank and performance metrics from the backend, badges. |
| 16 | Studio | Portfolio / Public Profile | Edit profile and portfolio albums; preview the public profile seen by customers. |
| 17 | Studio | AI Assistant (Trợ lý AI) | Enable the assistant, manage FAQ entries, view recent AI replies. |
| 18 | Account | Wallet (Ví của tôi) | Balance, held earnings, ledger and withdrawal with validation against the available balance. |
| 19 | Account | Settings (Cài đặt) | Profile, security, notification preferences, logout. |

##### Table 19: Screen descriptions - Landing page and Portal

| # | Feature | Screen | Description |
| :-: | :--- | :--- | :--- |
| 1 | Landing | Home page | Product introduction, featured photographers, call-to-action to the portal. |
| 2 | Public | Browse Photographers | Search and filters with photographer cards (Figure 12). |
| 3 | Public | Photographer Profile | Cover, portfolio, packages, reviews; buttons Book and Message (Figure 13). |
| 4 | Authentication | Login / Sign Up / Google callback | E-mail login, customer or photographer sign-up, Google sign-in. |
| 5 | Customer | Client Overview | Booking counters, upcoming shoots, to-do list, nearest shoot. |
| 6 | Customer | Booking Form | Three steps: package and schedule, location, send request; live price summary. |
| 7 | Customer | My Bookings / Booking Detail | Bookings by status; detail with timeline, payments, cancel, report. |
| 8 | Customer | Deposit / Payment | VietQR checkout for the deposit or the remaining amount. |
| 9 | Customer | Gallery / My Reviews | Delivered photos and confirm receipt; reviews written by the customer. |
| 10 | Photographer | Dashboard | Requests, upcoming shoots, earnings, verification state. |
| 11 | Photographer | Manage Bookings / Booking Detail | Accept, reject, start and complete bookings. |
| 12 | Photographer | Delivery Gallery | Upload and publish the gallery of a booking. |
| 13 | Photographer | Availability | Weekly calendar of bookings and blocked times. |
| 14 | Photographer | Portfolio / Packages | Manage albums and service packages. |
| 15 | Photographer | Storage (VIP) / Achievements | Storage usage and plans; rank, badges and metrics. |
| 16 | Photographer | AI Assistant | Assistant switch, FAQ list and AI reply history. |
| 17 | Shared | Messages | Conversations synchronised from the Chat Service. |
| 18 | Shared | Wallet | Balances, payout account, withdrawal request, ledger. |
| 19 | Shared | Settings | Profile, account and security, notification preferences. |

##### Table 20: Screen descriptions - Admin web application

| # | Feature | Screen | Description |
| :-: | :--- | :--- | :--- |
| 1 | Authentication | Admin Login | Login restricted to accounts with the admin role. |
| 2 | Dashboard | Overview | Key figures (users, bookings, revenue, open reports), charts and work queue. |
| 3 | Users | Users / User Detail | Search users; view detail; suspend, unsuspend or ban. |
| 4 | Photographers | Photographer Approvals | List of applications by verification status. |
| 5 | Photographers | Application Review | Profile, portfolio and documents of an applicant; approve or reject with a reason. |
| 6 | Bookings | Bookings / Booking Detail | All bookings with filters; detail with history and payments; admin cancellation. |
| 7 | Finance | Finance | Payments summary; refund and withdrawal requests with approve, reject, complete and extend deadline. |
| 8 | Moderation | Reports / Report Detail | Reports with category, target and evidence; resolve, reject or escalate. |
| 9 | Quality | Quality | Ranks and commission rates, badges, AI reply statistics, review moderation. |
| 10 | Storage | Storage | Object storage usage by type and by photographer. |
| 11 | Notifications | Send Notifications | Send system announcements to users. |

##### 3.1.3 Screen Authorization

##### Table 21: Screen and activity authorization

| Screen / activity | Guest | Customer | Photographer | Admin |
| :--- | :-: | :-: | :-: | :-: |
| Landing, browse photographers, photographer profile | X | X | X | X |
| Register, log in, reset password | X | | | |
| Profile, settings, e-mail verification | | X (own) | X (own) | X (own) |
| Create booking request | | X | | |
| Bookings list and booking detail | | X (own) | X (own) | X (all) |
| Cancel booking | | X (own) | | X (with reason) |
| Accept, reject, start, complete shoot | | | X (own) | |
| Pay deposit or remaining amount | | X (own) | | |
| Upload and publish gallery | | | X (own) | |
| View gallery and confirm receipt | | X (own) | X (own, view) | |
| Write and edit review / reply to review | | X (own) | X (reply) | X (hide/restore) |
| Report issue | | X (participant) | X (participant) | |
| Chat and notifications | | X | X | X (send system) |
| Wallet, payout account, withdrawal | | X (own) | X (own) | |
| Portfolio, packages, calendar, AI assistant, VIP plan | | | X (own) | |
| Verify photographers, manage users | | | | X |
| Finance: refunds, withdrawals, escrow extension | | | | X |
| Reports, quality (ranks, badges), storage, dashboard | | | | X |

##### 3.1.4 Non-Screen Functions

##### Table 22: Non-screen functions (background jobs and services)

| # | Feature | System function | Description |
| :-: | :--- | :--- | :--- |
| 1 | Booking | `booking-expire-pending` (every 10 min) | Expire pending requests older than 24 hours or whose shoot time has started. |
| 2 | Booking | `booking-cancel-unpaid` (every 10 min) | Cancel accepted bookings whose deposit was not paid before the deadline. |
| 3 | Booking | `booking-auto-complete` (hourly) | Complete shot bookings 7 days after the gallery is published when they are fully paid. |
| 4 | Payment | `payment-checkout-expiry` (every 5 min) | Expire unpaid checkouts and reconcile orders whose status at the provider is uncertain. |
| 5 | Payment | `payment-escrow-release` (every 5 min) | Release escrow to the photographer 72 hours after completion unless a refund request is open. |
| 6 | Payment | `payment-request-sla` (every 15 min) | Remind and escalate refund and withdrawal requests that pass their deadline. |
| 7 | Media | `media-pending-upload-expiry` (every 5 min) | Delete upload slots that were never completed. |
| 8 | Photographer | `photographer-badge` (daily) | Award badges (top rated, punctual, loyal customers) from visible reviews and returning customers. |
| 9 | Subscription | `subscription-expire-due` (every 5 min) | Expire VIP subscriptions at the end of their period. |
| 10 | Platform | Outbox worker (every 2 s) | Publish `outbox_events` to Kafka in batches of 50 with `FOR UPDATE SKIP LOCKED`; dead-letter after 5 failed attempts. |
| 11 | Payment | Webhook endpoint | Verify signature and amount, record the callback once, mark the transaction paid and hold the money in escrow. |
| 12 | Media | Media processing queue (BullMQ) | Create thumbnail and preview variants of uploaded photos (3 attempts with exponential back-off). |
| 13 | AI | AI Worker | Consume chat events, wait 15 seconds, and reply with the local LLM when the photographer is offline. |
| 14 | Chat | Chat outbox relay | Publish conversation events from MongoDB to the Kafka topic `chat.conversation.events.v1`. |
| 15 | Notification | Notification consumer | Consume domain events from Kafka, store notifications in MongoDB and push them through Socket.IO. |
| 16 | Notification | E-mail queue | Render and send OTP, booking and promotion e-mails through Mailgun or SendGrid, with retries. |

##### 3.1.5 Entity Relationship Diagram

*Figure 6: Conceptual entity relationship diagram (Chen notation)*

##### Table 23: Entity descriptions

| # | Entity | Description |
| :-: | :--- | :--- |
| 1 | User | Account linked to Keycloak; has exactly one role profile: Customer, Photographer or Admin. |
| 2 | Customer | Profile of a user who books shoots: preferred styles and location. |
| 3 | Photographer | Profile of a user who sells photography services: bio, styles, location, verification status, availability. |
| 4 | Admin | Profile of a platform operator; approves photographers and resolves reports. |
| 5 | Booking Plan | A package offered by a photographer: price, duration, number of photos, delivery days. |
| 6 | Portfolio | An album of a photographer's work with ordered media items. |
| 7 | Offline Slot | A time range blocked by a photographer. |
| 8 | Booking | An agreement between one customer and one photographer for one plan at one time; has a status history. |
| 9 | Transaction | A movement of money: deposit, remaining payment, subscription, top-up, refund or withdrawal. |
| 10 | Wallet | Balance of a user with an immutable ledger of credits and debits. |
| 11 | Refund Request | A request to return money to a customer or pay out a wallet balance; processed by an admin. |
| 12 | Media | An uploaded object (photo) with its variants; used by portfolios, galleries, avatars and evidence. |
| 13 | Booking Delivery | The gallery delivered for a booking. |
| 14 | Feedback | A review of a completed booking with three ratings, a comment and an optional reply. |
| 15 | Report | A complaint about a booking, user or content, with evidence and a status history. |
| 16 | Photographer Plan / Subscription | VIP plan catalogue and the photographer's subscription to a plan. |
| 17 | Rank / Badge | Reputation catalogues: rank with commission rate; badges awarded to photographers. |
| 18 | AI Settings / Knowledge Item / Reply Suggestion | Assistant configuration, FAQ knowledge with embeddings, and the audit of AI decisions. |

---

### 3.2 Account and Authentication

#### 3.2.1 Register Account (UC01)

* **Trigger:** Portal or Customer App: Login $\rightarrow$ "Sign up". Creator App: Login $\rightarrow$ "Chưa có tài khoản? Đăng ký".
* **Description:** A guest creates an account. Customers register with name, e-mail and password. Photographers also submit an application: working area and photography styles. API: `POST /auth/register`, then `POST /photographers/profile` for a photographer application.
* **Screen layout:** Creator App application form (Figure 7).
* **Function details:** Validation: name required; e-mail in valid format and unique (case-insensitive); password at least 8 characters. Rules: the role is fixed by the client (customer or photographer) and cannot be chosen freely; a photographer starts with `verification_status = pending` and is not visible in search until approved (UC25). Abnormal: 409 when the e-mail already exists; 400 for invalid fields; 429 when the gateway rate limit for authentication routes is exceeded.

#### 3.2.2 Log In and Log In with Google (UC02, UC03)

* **Trigger:** Login screen of any client $\rightarrow$ "Đăng nhập" or "Tiếp tục với Google".
* **Description:** E-mail login: `POST /auth/login` returns access token, refresh token and profile. Google login: `GET /keycloak/google/login` redirects to Keycloak and Google; callback returns to client with code exchanged by `GET /keycloak/google/exchange`. Silent renewal: `POST /auth/refresh`; logout: `POST /auth/logout`.
* **Screen layout:** Portal login (Figure 8), admin login (Figure 9), Creator App login (Figure 54).
* **Function details:** Rules: only users whose status is `active` can call protected endpoints (BR-01); admin application accepts only `admin` role; Creator App accepts only `photographer` role; Customer App redirects photographers away from customer screens. Session handling: when a request receives 401, client performs one shared refresh for all waiting requests and replays only read requests; write requests are never replayed automatically. Abnormal: wrong credentials $\rightarrow$ 401 generic message; suspended or banned account $\rightarrow$ 403; refresh token rejected $\rightarrow$ session cleared, login screen opens with original route kept.

#### 3.2.3 Reset Password (UC04)

* **Trigger:** Login $\rightarrow$ "Quên mật khẩu?".
* **Description:** Three steps: `POST /auth/forgot-password/send-otp` sends 6-digit OTP by e-mail, `POST /auth/forgot-password/verify` checks it and returns short-lived reset token, `POST /auth/forgot-password/reset` sets new password in Keycloak.
* **Screen layout:** Forgot Password screen with three steps: e-mail, OTP, new password and confirmation.
* **Function details:** Rules: OTP is valid for short time, max 5 requests per hour per e-mail. Abnormal: wrong/expired OTP $\rightarrow$ 400; too many requests $\rightarrow$ 429.

#### 3.2.4 Manage Profile (UC07)

* **Trigger:** Settings (Cài đặt) in any client, or More $\rightarrow$ Hồ sơ cá nhân in mobile apps.
* **Description:** Update name, phone, date of birth, gender, city and avatar (`PATCH /users/me`, `PATCH /customers/me` or `PATCH /photographers/me`); change password (`POST /auth/change-password`); verify e-mail by OTP (`POST /auth/email/send-otp`, `/auth/email/verify`); choose notification preferences.
* **Screen layout:** Figure 10 (Portal profile settings).
* **Function details:** Avatar upload uses media flow (presigned URL, max 12 MB, images only). E-mail address change handled by support. Abnormal: invalid field $\rightarrow$ 400; avatar upload incomplete $\rightarrow$ old avatar kept.

---

### 3.3 Discovery and Photographer Profile

#### 3.3.1 Search Photographers (UC05)

* **Trigger:** Landing page CTA (Figure 11), Portal "Khám phá" (Figure 12), Customer App tab "Khám phá".
* **Description:** `GET /photographers` with `q`, `location`, `styles`, `min_rating`, `price_min`, `price_max`, `experience`, `sort`, `limit`, `offset`; `GET /photographers/top-rated` and `/photographers/styles/featured` for landing page; `GET /customers/me/recommendations` for logged-in customers.
* **Function details:** Only verified photographers appear; unavailable photographers ranked last. Search ignores Vietnamese accents in mobile client. Public results cached in Redis. Empty result $\rightarrow$ "Không tìm thấy nhiếp ảnh gia phù hợp" with reset-filter action.

#### 3.3.2 View Photographer Profile (UC06)

* **Trigger:** Tap or click photographer card.
* **Description:** `GET /photographers/{id}` with `/booking-plans`, `/portfolios`, `/reviews`, `/rating-summary` and `/availability`.
* **Screen layout:** Figure 13 (Portal profile: cover, avatar, verified badge, rating, tags, bio, tabs, starting price, action buttons).
* **Function details:** Unverified/banned photographer returns 404. Portfolio images served through signed URLs. "Đặt lịch" button opens booking form for guests only after login.

---

### 3.4 Booking

A booking moves through the state machine in Figure 14.

```
       [Pending] --------(24h no reply / shoot started)--------> [Expired]
           |
           +----(Accept: deposit paid, <24h, slot free)---------> [Accepted]
           |                                                        |
           +----(Reject / Overlapping accepted)-----> [Rejected]     | (Start shoot)
           |                                                        v
           +----(Customer cancels)-----------------------------> [In_Progress]
                                                                    | (Shoot done)
                                                                    v
                                                                 [Shot]
                                                                    | (Confirm receipt / 7 days auto)
                                                                    v
                                                              [Completed]
```
*Figure 14: State diagram of a booking*

#### 3.4.1 Book Photo Session and Check Availability (UC12, UC13)

* **Trigger:** Photographer profile $\rightarrow$ "Đặt lịch" (Portal, Figure 15) or "Đặt lịch ngay" (Customer App).
* **Description:** Step 1: choose package, date, start time (`GET /photographers/{id}/availability`). Step 2: contact name, phone, shoot location. Step 3: review price, 30% deposit, remaining amount, accept terms, send `POST /bookings`.
* **Function details:** Rules BR-03 to BR-08. Server locks photographer row (`SELECT FOR NO KEY UPDATE`), loads overlapping slots/bookings, `Booking.prepare()` validates request and computes price snapshot. Normal: 200 pending booking, history row, `booking.created` event. Abnormal: 409 slot taken; 409 too many open requests; 400 wrong duration; 400 book yourself; 404 unverified.

#### 3.4.2 Track and Cancel Booking (UC14)

* **Trigger:** Customer workspace "Lịch đặt" (Figure 16) or Customer App tab "Lịch đặt"; "Huỷ" on booking.
* **Description:** `GET /bookings`, `GET /bookings/{id}`, `/timeline`. Cancellation: `GET /bookings/{id}/cancellation-preview`, then `POST /bookings/{id}/cancel` with reason.
* **Function details:** Only pending/accepted bookings can be cancelled by customer (BR-02); reason required. Automatic refund request created if deposit paid. Slot released immediately.

#### 3.4.3 Handle Booking Requests (UC21)

* **Trigger:** Creator App "Lịch đặt" $\rightarrow$ Booking Detail, or Portal studio "Manage Bookings".
* **Description:** `POST /bookings/{id}/accept`, `/reject` (with reason), `/start`, `/complete-shoot`.
* **Function details:** Accept requires pending status, request <24h old, shoot not started, deposit paid, no overlapping occupied booking. Accepts one, auto-rejects other pending overlapping requests. Start requires deposit paid.

---

### 3.5 Payment and Wallet

#### 3.5.1 Pay for Booking (UC11)

* **Trigger:** Booking creation or Booking Detail $\rightarrow$ "Thanh toán cọc" / "Thanh toán phần còn lại".
* **Description:** `POST /bookings/{id}/payments/deposit` or `/payments/remaining` with `payment_method` (gateway/wallet) and idempotency key. Creates PayOS/SePay order, returns VietQR (`GET /payments/{id}/qr`). Provider calls `POST /payments/webhooks/{provider}`.
* **Function details:** BR-09 to BR-12. Duplicate request returns existing intent. Webhook signature & exact amount verified, recorded once in `payment_webhooks`. Money held in escrow. Wallet payment immediate if balance sufficient.

#### 3.5.2 Manage Wallet and Withdraw (UC08)

* **Trigger:** Wallet (Ví của tôi) in any client (Figure 17).
* **Description:** `GET /wallet`, `GET /wallet/ledger`, `GET/PUT /wallet/payout-destination`, `POST /wallet/withdrawals`.
* **Function details:** Photographer earnings held until escrow release (BR-13). Withdrawal $\le$ available balance; amount reserved immediately, processed by admin (UC28). Bank details encrypted.

#### 3.5.3 Subscribe VIP Plan (UC24)

* **Trigger:** Creator App / Portal studio $\rightarrow$ Storage (VIP).
* **Description:** `GET /subscriptions/plans`, `GET /subscriptions/me/usage`, `POST /subscriptions` (creates subscription + payment order), `POST /subscriptions/{id}/cancel`.
* **Function details:** Max one live subscription per photographer. Active upon webhook confirmation. Expires at period end (`subscription-expire-due` job). Price/quota snapshotted.

---

### 3.6 Delivery and Review

#### 3.6.1 Deliver Photo Gallery (UC22)

* **Trigger:** Creator App / Portal studio $\rightarrow$ Booking Detail (status `shot`) $\rightarrow$ "Gallery".
* **Description:** `POST /media/upload-url` (presigned PUT), client uploads directly to S3/MinIO, `POST /media/complete-upload`. Then `POST /bookings/{id}/gallery/items` and `POST /bookings/{id}/gallery/publish`.
* **Function details:** Max 100 MB per image; async thumbnails. Requires package photo count reached and full payment. Starts 7-day auto-completion countdown.

#### 3.6.2 View and Confirm Gallery (UC15)

* **Trigger:** Booking Detail $\rightarrow$ "Xem ảnh bàn giao".
* **Description:** `GET /bookings/{id}/gallery` (presigned URLs, 900s TTL), `GET /bookings/{id}/gallery/download`, `POST /bookings/{id}/confirm-receipt`.
* **Function details:** Confirmation completes booking, creates escrow settlement released after 72 hours.

#### 3.6.3 Rate and Review (UC16)

* **Trigger:** Customer workspace "Đánh giá" (Figure 18) or review action on completed booking.
* **Description:** `POST /bookings/{id}/reviews` (rating, punctuality_rating, attitude_rating 1-5, comment), `PATCH /reviews/{id}`, photographer reply `PUT /reviews/{id}/reply`.
* **Function details:** BR-15: 1 review per completed booking, editable within 7 days. Photographer rating recalculated under row lock. Admins can hide abusive reviews.

---

### 3.7 Report and Dispute

#### 3.7.1 Report Issue and Attach Evidence (UC17, UC18)

* **Trigger:** Booking Detail / Gallery $\rightarrow$ "Báo vấn đề".
* **Description:** Upload evidence photos via presigned URLs $\rightarrow$ `POST /bookings/{id}/dispute` (reason, issue_type, evidence_media_ids). General user/content reports use `POST /reports`.
* **Function details:** 7 categories (photo quality, missing deliverables, late delivery, conduct, mismatch, payment/refund, other). Only booking participant can report (BR-16). Writes report, evidence, history in 1 transaction.

#### 3.7.2 Resolve Reports and Disputes (UC29)

* **Trigger:** Admin $\rightarrow$ Reports $\rightarrow$ Report Detail.
* **Description:** `GET /admin/reports/{id}`, `POST /admin/reports/{id}/resolve` (decision, note, actions).
* **Function details:** Resolve, reject, escalate. Triggers refund request or account suspension if required.

---

### 3.8 Chat, AI Assistant and Notifications

#### 3.8.1 Chat and AI Auto-Reply (UC09, UC10)

* **Trigger:** Profile / Booking Detail $\rightarrow$ "Nhắn tin"; Messages (Figure 19).
* **Description:** Direct conversation stored in MongoDB. If photographer is offline and AI enabled, AI Worker answers after 15s delay. Reply marked with AI assistant badge.
* **Function details:** Max 10,000 chars per message. AI context: last 11 messages, top-5 FAQ by vector similarity, max 220 output tokens. Complaints/payments/booking changes handed off to human.

#### 3.8.2 Configure AI Assistant (UC23)

* **Trigger:** Creator App / Portal studio $\rightarrow$ "Trợ lý AI".
* **Description:** `GET/PATCH /photographers/me/ai-assistant`, `GET/POST/PATCH/DELETE /faqs`, `GET /ai-reply-suggestions`.
* **Function details:** FAQs embedded with `qwen3-embedding:0.6b` (1024-dim vector in `lens_ai`).

#### 3.8.3 Notifications

* **Trigger:** Domain events (booking created/accepted/rejected/expired/paid/delivered, etc.).
* **Description:** Transactional outbox $\rightarrow$ Kafka $\rightarrow$ Notification Service $\rightarrow$ Socket.IO (`/notification` namespace) + E-mail queue.

---

### 3.9 Photographer Studio

#### 3.9.1 Manage Portfolio and Packages (UC19)

* **Description:** Packages: `POST /photographers/me/booking-plans`, `PATCH`, `DELETE`. Portfolios: `POST /portfolios`, `/items`, `/items/reorder`, `DELETE`.
* **Function details:** Price 1 - 9,000,000,000,000 VND; delivery 1-365 days. Active bookings prevent package deletion (only deactivation allowed).

#### 3.9.2 Manage Working Calendar (UC20)

* **Description:** `GET /calendar/me`, `POST /calendar/blocked-times`, `DELETE`.
* **Function details:** Blocks cannot overlap occupied bookings or existing blocks. Overlapping pending requests trigger warning & cancellation upon confirmation. Half-open ranges `[from, to)`.

---

### 3.10 Administration

#### 3.10.1 Verify Photographers (UC25)

* **Description:** `GET /admin/photographers?status=pending`, `POST /admin/photographers/{id}/approve`, `/reject`.
* **Function details:** Approval updates status to `verified`, assigns Keycloak `photographer` role. Rejection stores reason.

#### 3.10.2 Manage Users (UC26)

* **Description:** `GET /admin/users`, `POST /admin/users/{id}/suspend`, `/unsuspend`, `/ban`.
* **Function details:** Immediate effect: Keycloak account disabled, token guard rejects next request.

#### 3.10.3 Monitor Bookings and Payments (UC27)

* **Description:** `GET /admin/dashboard`, `/analytics`, `/queue`, `/bookings`, `/payments`, `/storage`; `POST /admin/bookings/{id}/cancel`.

#### 3.10.4 Process Refunds and Withdrawals (UC28)

* **Description:** `GET /admin/refund-requests`, `POST /admin/refund-requests/{id}/approve`, `/reject`, `/complete`, `/extend-deadline`.
* **Function details:** Refunds bounded by total paid amount. Withdrawals debited from reserved wallet funds.

---

## 4. Non-Functional Requirements

### 4.1 External Interfaces

##### Table 24: Software interfaces

| Interface | Specification |
| :--- | :--- |
| Client - API | HTTPS REST JSON under `/api/v1`; Bearer JWT (mobile) or HttpOnly cookies with CSRF token (web); standard response envelope. |
| Realtime | Socket.IO namespace `/notification` at path `/api/v1/socket.io`; chat events from Chat Service. |
| Identity | Keycloak OIDC; RS256 tokens verified against cached JWKS; Google identity brokering. |
| Payment | PayOS or SePay REST API; signed webhooks at `POST /api/v1/payments/webhooks/{provider}`; VND only. |
| Storage | S3 API (MinIO); presigned PUT and GET URLs with TTL of 900 seconds. |
| Messaging | Kafka topics for domain notifications (outbox) and chat events for AI Worker. |
| AI runtime | Ollama HTTP API `/api/embed` and `/api/chat` inside private Docker network. |
| E-mail | Mailgun or SendGrid HTTP API. |

### 4.2 Quality Attributes

* **Usability:** 3-step booking wizard; clear VND formatting (e.g., `300.000 ₫`); Vietnamese error messages.
* **Reliability:** Atomic database transactions; at-least-once outbox delivery; exponential back-off for queues; advisory locks on cron jobs.
* **Performance:** Discovery/profile queries respond $<1\text{s}$ (Redis caching); booking commands $<2\text{s}$; direct object storage upload/download.
* **Security:** Keycloak RS256 JWT validation; rate limiting at Kong gateway; encrypted payout bank details; short-lived presigned URLs (900s).
* **Maintainability:** Modular architecture with CQRS; OpenAPI contract validation; CI/CD pipeline per repository.

---

## 5. Requirement Appendix

### 5.1 Business Rules

##### Table 25: Business rules

| ID | Rule definition |
| :--- | :--- |
| BR-01 | Only a user whose status is `active` can call protected endpoints; suspended or banned users are rejected. |
| BR-02 | A customer can act only on their own resources; a photographer only on bookings, packages and media that belong to them. |
| BR-03 | Only verified and available photographers with an active package can be booked; a user cannot book themselves. |
| BR-04 | A booking must start in the future and last exactly the package duration. |
| BR-05 | A time range is free only if it does not overlap an offline slot or a reserving booking (pending, accepted, in_progress, shot, completed); ranges are half-open `[from, to)`. |
| BR-06 | A customer may keep at most 3 pending requests per photographer and 10 pending requests in total. |
| BR-07 | Price & package terms snapshotted at booking time; deposit is $\lceil 30\% \times \text{total price} \rceil$. |
| BR-08 | Pending request expires after 24 hours or when shoot start time arrives, whichever comes first. |
| BR-09 | Request can be accepted only after deposit paid; remaining amount paid only after deposit. |
| BR-10 | Payment succeeds only after verified provider callback with exact amount; repeated callbacks have no effect. |
| BR-11 | Paid money held in escrow by platform, never transferred directly to photographer upfront. |
| BR-12 | Shoot starts only when deposit paid; booking completed only from `shot`, when fully paid & gallery published. |
| BR-13 | Escrow released 72h after completion (minus rank commission) unless refund request is open. |
| BR-14 | Gallery published only when containing at least the required photo count promised by package. |
| BR-15 | One review per completed booking, editable within 7 days; ratings are integers 1-5. |
| BR-16 | Booking report opened only by a participant; evidence must be uploaded by reporter. |
| BR-17 | Refunds cannot exceed total amount paid for booking; withdrawals cannot exceed available wallet balance. |
| BR-18 | A photographer can have at most one live VIP subscription. |

### 5.2 Common Requirements

##### Table 26: Common requirements

| Topic | Requirement |
| :--- | :--- |
| Identifiers | All primary keys are UUID v4. |
| Time | All timestamps are timestamptz (UTC in database, UTC+7 in clients). |
| Money | All amounts are integer VND (`bigint`), never floating point. |
| Paging | Every list endpoint is paginated with `limit` and `offset` (default 20). |
| Errors | Standard HTTP codes: 400, 401, 403, 404, 409, 429, 503. |
| Idempotency | Idempotency keys used for payments, withdrawals, webhooks. |
| Audit | Append-only history tables for bookings, reports, subscriptions. |

### 5.3 Application Messages List

##### Table 27: Application messages

| # | Type | Context | Content |
| :-: | :--- | :--- | :--- |
| MSG01 | HTTP 409 | Slot overlaps reserving booking | Photographer already has a booking at this time |
| MSG02 | HTTP 409 | Slot overlaps offline slot | Photographer is unavailable at this time |
| MSG03 | HTTP 400 | Wrong duration | Booking length must match plan duration |
| MSG04 | HTTP 409 | Too many pending requests | Too many open requests, wait for answers or cancel some |
| MSG05 | HTTP 400 | Self booking | Cannot book yourself |
| MSG06 | HTTP 409 | Request >24h old | Booking request has expired |
| MSG07 | HTTP 409 | Start shoot without deposit | Deposit must be paid before starting |
| MSG08 | HTTP 409 | Complete without full payment | Full payment and published gallery required |
| MSG09 | HTTP 409 | Pay remaining before deposit | Pay the deposit first |
| MSG10 | HTTP 409 | Change method after intent | Payment method cannot change after an intent was created |
| MSG11 | Toast | Network error | Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng. |
| MSG12 | Redirect | Session expired | Login screen with original route kept for redirection |

---

## IV. Software Design Description

### 1. System Design

#### 1.1 System Architecture

*Figure 20: System architecture of the Lens platform*

```
[ Web & Mobile Clients ]
           |
         (HTTPS / WSS)
           v
       [ Caddy ] (TLS Termination)
           |
           v
        [ Kong ] (API Gateway)
           |
 +---------+---------+-----------------------+
 |                   |                       |
 v                   v                       v
[ Core API ]   [ Chat Service ]   [ Notification Service ]
(NestJS REST)    (Go REST)          (NestJS Socket.IO)
 |     |             |                       |
 |     +-------+     |                       |
 v             v     v                       v
[PostgreSQL] [Redis] [MongoDB]              [Kafka]
(pgvector)     ^                               |
               |                               v
         [ BullMQ Queue ] ------------> [ AI Worker ] -----> [ Ollama LLM ]
```

##### Table 28: Architecture components

| Component | Responsibility |
| :--- | :--- |
| Clients | React 19 web apps (`lens.id.vn`, `app.lens.id.vn`, `admin.lens.id.vn`); Flutter mobile apps (Android/iOS). |
| Edge | Caddy (Reverse proxy / TLS) $\rightarrow$ Kong 3.9 (API gateway, routing, rate-limit, CORS). |
| Core API | NestJS 12, CQRS, TypeORM, 11 bounded contexts, cron jobs, outbox worker. |
| AI Worker | NestJS process, BullMQ, Ollama integration, pgvector RAG queries. |
| Chat Service | Go service, Gin framework, MongoDB storage, Kafka outbox. |
| Notification Service | NestJS 11, MongoDB, Socket.IO gateway, Mailgun/SendGrid email delivery. |
| Storage & Data | PostgreSQL 16 (pgvector), MongoDB, Redis 7, Kafka 3.9, MinIO (S3 object store), Keycloak 24. |
| AI Model | Ollama with `qwen3.5:2b` (Chat LLM) and `qwen3-embedding:0.6b` (Text Embeddings). |

#### 1.2 Package Diagram

*Figure 21: Package diagram of the backend (`lens-be`)*  
*Figure 22: Package diagram of mobile applications (`lib/`) and web monorepo (`packages/ui`, `apps/`)*

##### Table 29: Backend package descriptions

| No | Package | Description |
| :-: | :--- | :--- |
| 1 | `apps/core` | Entry point of HTTP API (`main.ts`). |
| 2 | `apps/ai-worker` | Entry point of AI Worker (Kafka consumer, BullMQ processor). |
| 3 | `src/features/api` | Controllers, DTOs, Keycloak guard, Swagger schemas. |
| 4 | `src/features/workers` | Outbox worker and 9 cron jobs with advisory locks. |
| 5 | `src/modules/*` | 11 Bounded Contexts (booking, payment, calendar, etc.). |
| 6 | `src/shared/*` | Common access checks, TypeORM entities, domain rules, S3/Kafka/PayOS adapters. |

---

### 2. Database Design

* **Database 1:** `lens` (35 PostgreSQL tables for core domain business data).
* **Database 2:** `lens_ai` (3 PostgreSQL tables with `pgvector` extension for AI RAG embeddings).
* **Document Store:** MongoDB (chat conversations, messages, notifications).

#### 2.1 Normalisation (1NF, 2NF, 3NF)

##### Table 31: Intentional exceptions to 3NF

| Column / table | Reason |
| :--- | :--- |
| `bookings.total_amount`, `deposit_amount`, `package_snapshot` | **Price Snapshot:** Agreement terms must not change when photographer updates package later. |
| `subscriptions.price`, `plan_snapshot` | Snapshot of VIP plan pricing and quota at purchase time. |
| `photographer_ratings` | Cached aggregate of ratings/reviews to avoid heavy runtime aggregations. |
| `feedbacks.photographer_id`, `customer_id` | Denormalized to query reviews by photographer directly without joining `bookings`. |
| `wallets.balance`, `frozen_balance` | Running totals of immutable `wallet_ledger` entries. |

#### 2.2 Table Descriptions

* **Figure 23:** Database diagram - Identity and Photographer domain (`users`, `customers`, `photographers`, `admins`, `ranks`, `badges`, `photographer_badges`, `photographer_ratings`, `portfolios`, `booking_plans`, `offline_slots`).
* **Figure 24:** Database diagram - Booking, Media and Feedback domain (`bookings`, `booking_status_history`, `booking_deliveries`, `media`, `media_variants`, `feedbacks`, `reports`, `report_evidences`, `report_status_history`).
* **Figure 25:** Database diagram - Payment, Wallet and Subscription domain (`transactions`, `payment_webhooks`, `payment_escrow_settlements`, `refund_requests`, `refund_request_allocations`, `wallets`, `wallet_ledger`, `wallet_payout_destinations`, `photographer_plans`, `subscriptions`).
* **Figure 26:** Database diagram - AI database (`ai_assistant_settings`, `ai_knowledge_items`, `ai_reply_suggestions`) and system tables (`outbox_events`).

---

### 3. API Design

##### Table 36: API operations by module (154 operations total)

| Swagger tag | Operations | Main routes |
| :--- | :-: | :--- |
| Authentication | 13 | `/auth/register`, `/auth/login`, `/auth/refresh`, `/auth/logout`, `/auth/forgot-password/*`, `/keycloak/google/*` |
| User, Customer, Admin | 16 | `/users/me`, `/customers/me`, `/customers/me/recommendations`, `/admin/users/*` |
| Photographer | 14 | `/photographers`, `/photographers/{id}`, `/photographers/top-rated`, `/admin/photographers/{id}/approve` |
| Plans & Portfolio | 15 | `/photographers/me/booking-plans`, `/photographers/me/portfolios`, `/portfolios/{id}/items` |
| Rank & Badge | 4 | `/ranks`, `/badges`, `/admin/ranks/{code}` |
| Calendar | 6 | `/calendar/me`, `/calendar/blocked-times`, `/photographers/{id}/availability` |
| Booking | 17 | `/bookings`, `/bookings/{id}`, `/accept`, `/reject`, `/start`, `/complete-shoot`, `/confirm-receipt`, `/cancel` |
| Payment & Wallet | 24 | `/bookings/{id}/payments/deposit`, `/payments/webhooks/{provider}`, `/wallet/*`, `/admin/refund-requests/*` |
| Media & Gallery | 10 | `/media/upload-url`, `/media/complete-upload`, `/bookings/{id}/gallery/publish`, `/gallery/download` |
| Review | 10 | `/bookings/{id}/reviews`, `/reviews/{id}/reply`, `/admin/reviews/*` |
| Subscription | 8 | `/subscriptions/plans`, `/subscriptions`, `/subscriptions/me` |
| Moderation & Admin | 10 | `/reports`, `/admin/reports/*`, `/admin/dashboard`, `/admin/queue` |
| AI Assistant | 7 | `/photographers/me/ai-assistant`, `/photographers/me/ai-assistant/faqs` |

---

### 4. Detailed Design

#### 4.1 Authentication and Session

*Figure 28: Sequence diagram - log in and token refresh*

#### 4.2 Booking

##### Table 37: Class specifications - booking feature

| Class | Method | Responsibility |
| :--- | :--- | :--- |
| `BookingController` | `create(actor, dto)` | Validates DTO and dispatches `BookingCreateCommand`. |
| `BookingCreateCommandHandler` | `execute(command)` | Executes `useCases.create()` inside `dataSource.transaction()`. |
| `BookingUseCases` | `create(s, actor, input)` | Locks photographer, checks overlaps, invokes `Booking.prepare()`, saves entities & outbox event. |
| `BookingUseCases` | `lockPhotographer(s, id)` | Issues `SELECT FOR NO KEY UPDATE` on photographer row to serialize schedule modifications. |
| `Booking` (domain) | `prepare(input)` | Validates BR-03 to BR-07, computes total price, $30\%$ deposit, and snapshots package details. |

*Figure 29:* Class diagram of the booking feature  
*Figure 30:* Sequence diagram - book a photo session  
*Figure 31:* Sequence diagram - photographer accepts or rejects a booking  

#### 4.3 Payment and Wallet

##### Table 38: Class specifications - payment and wallet feature

| Class | Method | Responsibility |
| :--- | :--- | :--- |
| `PaymentsController` | `deposit`, `remaining`, `webhook` | Exposes payment intent creation and provider webhook endpoints. |
| `PaymentUseCases` | `intent(s, actor, input, type)` | Generates or retrieves active payment transaction and VietQR link. |
| `PaymentUseCases` | `webhook(s, actor, input)` | Validates gateway signature, verifies amount, records webhook idempotently, updates transaction to `PAID`. |
| `WalletUseCases` | `holdBookingPayment` / `releaseBookingEscrow` | Writes immutable ledger entries and updates cached wallet balances. |

*Figure 32:* Class diagram of payment and wallet feature  
*Figure 33:* Sequence diagram - pay deposit with VietQR  

#### 4.4 Delivery and Confirm Receipt

*Figure 34: Sequence diagram - deliver gallery and confirm receipt*

#### 4.5 Report and Dispute

##### Table 39: Class specifications - report and moderation feature

| Class | Method | Responsibility |
| :--- | :--- | :--- |
| `BookingUseCases` | `dispute(s, actor, input)` | Verifies participant identity and delegates to moderation via `BookingDisputeReportPort`. |
| `ModerationReportUseCases` | `createBookingDispute` | Validates uploaded evidence media items and creates `reports` record. |
| `ModerationReportUseCases` | `resolve(s, actor, input)` | Appliess admin decision, updates status history, triggers refund allocations if approved. |

*Figure 35:* Class diagram of report and moderation feature  
*Figure 36:* Sequence diagram - report a booking issue and admin resolution  

#### 4.6 Photographer Application and Verification

*Figure 37: Sequence diagram - photographer application and verification*

#### 4.7 AI Auto-Reply with a Self-Hosted LLM

##### Table 40: AI safeguards

| Concern | Mechanism | Location |
| :--- | :--- | :--- |
| Concurrency | Single BullMQ job queue with concurrency = 1, 15-second delay, SHA256 job de-duplication. | `ai-reply.processor.ts` |
| Stale replies | Worker verifies no human reply occurred during 15s wait; skips if photographer is online. | `ai-assistant.service.ts` |
| Context limit | Max token context 4,096 tokens; last 11 messages; top-5 FAQ items by cosine similarity. | `ollama.client.ts` |
| Output control | Max generation length 220 tokens; JSON schema output; strict length check $\le 1500$ chars. | `ollama.client.ts` |
| Fallback / Risk | Prompt injection protection; payment, complaint, and booking modifications automatically handed off. | `ollama.client.ts` |

*Figure 38: Sequence diagram - AI auto-reply with retrieval-augmented generation (RAG)*

---

## V. Software Testing Documentation

### 1. Scope of Testing

* **In scope:** Booking rules, calendar overlaps, payment intents, VietQR webhooks, escrow release, wallet ledger, outbox event publishing, reviews, ranks, badges, AI assistant RAG pipeline, Flutter mobile UI & repositories, Web builds.
* **Levels:** Unit tests, Integration tests (real PostgreSQL, Redis, MinIO), OpenAPI contract tests, System & Acceptance testing.

### 2. Test Strategy

#### 2.1 Testing Types

##### Table 41: Testing types

| Type | Objective | Technique | Completion criteria |
| :--- | :--- | :--- | :--- |
| Unit test (Core API) | Validate business rules and use cases in isolation | `node:test` and `node:assert` with in-memory mocks | 100% pass rate; $\ge 60\%$ line coverage |
| Integration test (Core API) | Validate HTTP, DTO validation, DB transactions, SQL constraints | NestJS testing module with PostgreSQL 16, Redis, MinIO containers | 100% pass rate on fresh DB |
| OpenAPI contract test | Ensure Swagger documentation matches runtime routes | Route inspection vs OpenAPI schema | 100% routes documented |
| Mobile tests | Validate session handling, Dio interceptors, Flutter UI widgets | `flutter_test` with fake adapters | 100% pass rate |

#### 2.2 Test Levels

##### Table 42: Test types per test level

| Test type | Unit | Integration | System | Acceptance |
| :--- | :-: | :-: | :-: | :-: |
| Functional (business rules) | X | X | X | X |
| Concurrency & Data integrity | X | X | | |
| Security & Authorization | X | X | X | |
| User Interface & Navigation | X | | X | X |

---

### 3. Test Plan

#### 3.1 Human Resources

##### Table 44: Testing roles

| Member | Role | Responsibilities |
| :--- | :--- | :--- |
| Nguyễn Nhật Trường | Backend Test Owner | Unit and integration tests for booking, calendar, photographer, reviews; contract tests. |
| Đỗ Nguyễn Nhĩ Anh | Backend & DevOps | Payment, outbox, storage, gateway tests; Chat & Notification service tests; CI pipelines. |
| Nguyễn Như Lâm Dũng | Mobile Test Owner | Flutter repository, session, routing and widget tests for Customer & Creator apps. |
| Nguyễn Phúc Thịnh | Mobile Test Owner | Flutter tests; manual acceptance walkthroughs and UI verification. |

#### 3.2 Test Environment

##### Table 45: Test environment

| Purpose | Environment | Version |
| :--- | :--- | :--- |
| Developer machine | Windows 11, Docker Desktop, Android Emulator | Windows 11 (26200) |
| CI Runner | GitHub-hosted runner with pnpm, Go, Flutter, Docker | `ubuntu-latest` |
| Integration DB | PostgreSQL 16 (`pgvector`), Redis 7, MinIO object store | Docker containers |
| Acceptance System | Deployed platform under `lens.id.vn`, Android APK/AAB | Release v1.0.0+1 |

---

### 4. Test Cases

##### Table 47: Automated test suites overview

| Suite | Type | Cases | Command |
| :--- | :--- | :-: | :--- |
| `lens-be` (unit) | Unit | 107 | `pnpm test:unit` |
| `lens-be` (integration) | Integration | 31 | `pnpm test:integration` |
| `lens-be` (contract) | Contract | 2 | `pnpm test:openapi` |
| `lens-mobile` | Unit & Widget | 50 | `flutter test --coverage` |
| `lens-creator-mobile` | Unit & Widget | 66 | `flutter test --coverage` |
| `lens-notification-service` | Unit | 34 | `pnpm test` |
| `lens-chat-service` | Unit | 4 | `go test ./...` |
| **Total** | | **294** | |

##### Table 48: Selected Core API unit test cases

| ID | Test case | Input / precondition | Expected result | Result |
| :-: | :--- | :--- | :--- | :-: |
| UT-01 | Unverified photographer cannot be booked | Draft with unverified photographer | 404 "Photographer not found" | Pass |
| UT-02 | Booking duration must match plan | 90-min slot for 60-min plan | 400 "Booking length must match plan duration" | Pass |
| UT-03 | Pending booking reserves slot | Overlapping booking in status `pending` | Slot marked reserved | Pass |
| UT-04 | Cancelled/expired booking releases slot | Overlapping booking in status `cancelled` | Slot marked free | Pass |
| UT-05 | Max pending request limits enforced | 3 pending with same photographer | 409 "Too many open requests..." | Pass |
| UT-06 | Overlap condition calculation | Half-open ranges `[from, to)` touching at boundary | Touching boundaries do NOT overlap | Pass |
| UT-10 | Accepting request declines overlapping pending ones | 2 pending overlapping requests; accept 1 | Second request automatically `rejected` | Pass |
| UT-19 | Outbox dead-letters after 5 retries | 5 consecutive publish failures | `failed_at` populated, retries stop | Pass |

##### Table 49: Selected Core API integration test cases (real PostgreSQL, Redis, MinIO)

| ID | Test case | Scenario | Expected result | Result |
| :-: | :--- | :--- | :--- | :-: |
| IT-02 | Concurrent booking conflict | Two parallel requests for identical slot | One succeeds (200), one fails (409) | Pass |
| IT-05 | Payment intent idempotency | Retried payment creation call | Returns existing transaction without creating duplicate | Pass |
| IT-06 | Webhook replay protection | Replaying valid payment webhook | 200 `{ duplicate: true }`, ledger untouched | Pass |
| IT-11 | Account suspension effect | Admin suspends account | Next API call with existing token returns 403 | Pass |

---

### 5. Test Reports

#### 5.1 Execution Results

##### Table 53: Test execution results

| Suite | Total | Pass | Fail | Pass rate | Duration |
| :--- | :-: | :-: | :-: | :-: | :-: |
| Core API unit | 107 | 107 | 0 | 100% | 11.6 s |
| Core API integration | 31 | 31 | 0 | 100% | 14.1 s |
| Core API OpenAPI contract | 2 | 2 | 0 | 100% | 9.1 s |
| Customer App (Flutter) | 50 | 50 | 0 | 100% | 61.4 s |
| Creator App (Flutter) | 66 | 66 | 0 | 100% | 49.7 s |
| Notification Service (Jest) | 34 | 34 | 0 | 100% | 22.8 s |
| Chat Service (Go) | 4 | 4 | 0 | 100% | < 1.0 s |
| **Total** | **294** | **294** | **0** | **100%** | |

#### 5.2 Code Coverage

##### Table 54: Code coverage

| Scope | Line | Branch | Function | Tool |
| :--- | :-: | :-: | :-: | :--- |
| Core API (exercised source files) | **62.83%** | 70.90% | 59.55% | Node test coverage |
| `booking.domain.ts` | **99.39%** | 100% | 94.74% | Node test coverage |
| `calendar.domain.ts` | **100%** | 96.55% | 100% | Node test coverage |
| `outbox.worker.ts` | **91.45%** | 68.00% | 77.78% | Node test coverage |
| Customer App (`lib/`) | **35.91%** | – | – | `flutter test --coverage` |
| Creator App (`lib/`) | **46.46%** | – | – | `flutter test --coverage` |

#### 5.3 Continuous Integration

*Figure 39:* CI/CD pipeline (GitHub Actions $\rightarrow$ GHCR $\rightarrow$ Portainer)  
*Figure 40:* GitHub Actions run history of `LensExe/lens-be`

---

## VI. Release Package & User Guides

### 1. Deliverable Package

##### Table 56: Deliverable package

| No. | Deliverable item | Description |
| :-: | :--- | :--- |
| 1 | Source code | 6 GitHub repositories under `github.com/LensExe`. |
| 2 | Database scripts | SQL migration scripts for core DB and AI DB; seed data scripts. |
| 3 | Docker images | Published container images on GitHub Container Registry (GHCR). |
| 4 | Mobile builds | Android App Bundles (`.aab`) for Customer App and Creator App. |
| 5 | Deployed system | Live system running at `lens.id.vn`, `app.lens.id.vn`, `admin.lens.id.vn`, `api.lens.id.vn`. |
| 6 | API documentation | Swagger UI at `https://api.lens.id.vn/docs` (154 operations). |
| 7 | Documentation | Final Project Report (PDF/MD), Draw.io diagrams, presentation slides. |

---

### 2. Installation Guides

#### 2.1 System Requirements

##### Table 57: System requirements

| Component | Requirement |
| :--- | :--- |
| Server VPS | Linux host with Docker & Docker Compose; 4 vCPU, 16 GB RAM (for local Ollama LLM). |
| Backend Dev | Node.js 22+, pnpm 11, Docker Desktop. |
| Mobile Dev | Flutter 3.47 (Dart 3.13), Android Studio / Xcode. |

#### 2.2 Installation Instruction

##### 2.2.1 Backend (`lens-be`)

```bash
# 1. Clone repository and install dependencies
git clone https://github.com/LensExe/lens-be.git
cd lens-be
pnpm install --frozen-lockfile

# 2. Start infrastructure (PostgreSQL, Redis, MinIO, Keycloak)
pnpm docker:up

# 3. Apply database migrations and seed data
pnpm db:migrate
pnpm db:migrate:ai
pnpm seed:local

# 4. Start Core API in development mode
pnpm start:dev
```

##### 2.2.2 Web Applications (`Lens-web`)

```bash
git clone https://github.com/LensExe/Lens-web.git
cd Lens-web
pnpm install
pnpm dev # Starts Landing, Portal, Admin locally
```

##### 2.2.3 Mobile Applications (`lens-mobile` & `lens-creator-mobile`)

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://api.lens.id.vn/api/v1
```

---

### 3. User Manual

#### 3.1 Overview

The Lens platform operates across five client applications:
* **Guests / Customers:** Landing page (`lens.id.vn`), Portal (`app.lens.id.vn`), Customer App.
* **Photographers:** Creator App, Portal Studio (`app.lens.id.vn`).
* **Administrators:** Admin Web Console (`admin.lens.id.vn`).

#### 3.2 Customer Workflows

1. **Search & Browse:** Open "Khám phá", filter by city, photography style, rating, and budget. View portfolio albums and package details.
2. **Book Session:** Select package $\rightarrow$ Choose date & available 30-min start slot $\rightarrow$ Fill location & contact details $\rightarrow$ Confirm booking request.
3. **Pay Deposit:** Scan generated VietQR code using any Vietnamese banking app. System updates status automatically via webhook.
4. **Gallery & Completion:** Access delivered gallery photos $\rightarrow$ Tap "Xác nhận đã nhận ảnh" to complete booking and trigger escrow release.
5. **Review:** Rate photographer (1-5 stars for overall, punctuality, attitude) and leave written feedback within 7 days.

#### 3.3 Photographer Workflows

1. **Studio Setup:** Define service packages (price, duration, photo count, delivery timeline), upload portfolio photos, and block unavailable calendar slots.
2. **Manage Booking Requests:** Receive real-time notification $\rightarrow$ Accept or Reject request within 24 hours.
3. **Execute Shoot & Deliver:** Mark shoot as started $\rightarrow$ Upload final retouched photos to gallery $\rightarrow$ Publish gallery to customer.
4. **AI Assistant:** Enable AI Assistant in settings and add custom FAQ items. AI automatically responds to routine customer inquiries when photographer is offline.
5. **Wallet & Payout:** Track held escrow and available balance. Register bank account details to request payout withdrawals.

#### 3.4 Administrator Workflows

1. **Verify Photographers:** Review pending photographer registration applications, verify portfolios, and approve/reject accounts.
2. **Financial Management:** Monitor platform transactions, process customer refund requests, and approve photographer wallet payout withdrawals.
3. **Dispute Resolution:** Review reported booking disputes, examine evidence photos uploaded by users, and render resolutions (refunds, warnings, suspensions).

---

## VII. Appendix

### 1. Glossary

##### Table 58: Glossary

| Term | Meaning in Lens |
| :--- | :--- |
| Booking plan / package | A photography service package defined by price, duration, photo count, delivery days. |
| Offline slot | A custom calendar period blocked by a photographer to prevent incoming bookings. |
| Deposit | $30\%$ of total package price (rounded up) paid by customer to lock a time slot. |
| Escrow | Safe holding of booking payment by platform until 72h after completion. |
| Rank | Photographer tier determined by completed bookings; defines platform commission rate. |
| VIP plan | Monthly subscription granting photographers higher storage capacity and search visibility. |
| Outbox pattern | Transactional outbox pattern guaranteeing atomic DB writes and reliable Kafka event delivery. |
| Presigned URL | Short-lived, cryptographically signed URL allowing direct, secure S3 photo upload/download. |
| RAG | Retrieval-Augmented Generation: AI pattern combining vector similarity search with LLM inference. |

---

### 2. References

1. FPT University - SEP490 Report Document Templates (Report 1 to Report 7).
2. PRM393 - Mobile Programming Final Project Specifications, Fall 2026.
3. Lens Source Code & Documentation - [github.com/LensExe](https://github.com/LensExe).
4. NestJS Documentation - [docs.nestjs.com](https://docs.nestjs.com).
5. Flutter Documentation - [docs.flutter.dev](https://docs.flutter.dev).
6. React Documentation - [react.dev](https://react.dev).
7. Keycloak Documentation - [keycloak.org/documentation](https://www.keycloak.org/documentation).
8. Ollama AI API Reference - [github.com/ollama/ollama](https://github.com/ollama/ollama).
9. PayOS Integration Guide - [payos.vn/docs](https://payos.vn/docs).
10. SePay API Documentation - [docs.sepay.vn](https://docs.sepay.vn).