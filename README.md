# GATES IT Solution — Full-Stack Developer Assessment

**Marwan Bukhori** · [marwanbukhori.dev@gmail.com](mailto:marwanbukhori.dev@gmail.com) · July 2026

![Adoption Home — desktop screenshot](docs/screenshots/01-list-desktop.png)

The assessment asked me to build two things: a Laravel discount system and a Flutter pet-adoption screen. I built each one twice — once as a direct answer to the marking sheet, and once evolved into a real product called **Pawmise**. This repo contains both. The boundary between them is explicit and honest.

---

## Who is this repo for?

| If you are… | Read this first |
|-------------|-----------------|
| **HR / recruiter** — you just want to know what's here | [`docs/what-is-this.md`](docs/what-is-this.md) *(1 page, plain English)* |
| **Technical evaluator** — grading against the rubric | [`docs/evaluator-guide.md`](docs/evaluator-guide.md) *(5-minute path, file-by-file)* |
| **Software engineer** — you want architecture and design decisions | [`docs/architecture.md`](docs/architecture.md) and [`docs/decisions.md`](docs/decisions.md) |
| **Developer running the code** | [`01-answers/laravel/README.md`](01-answers/laravel/README.md), [`01-answers/flutter/README.md`](01-answers/flutter/README.md), [`02-showcase/laravel/README.md`](02-showcase/laravel/README.md), [`02-showcase/flutter/README.md`](02-showcase/flutter/README.md) |

---

## What's in the box

```
gates-assessment/
├── Full Stack Developer Assessment.pdf      ← the original brief
├── docs/                                    ← technical reading
│   ├── what-is-this.md                      (HR-friendly overview)
│   ├── evaluator-guide.md                   (rubric-mapped review path)
│   ├── architecture.md                      (system design + diagrams)
│   ├── decisions.md                         (ADR-style design rationale)
│   └── how-02-was-built.md                  (the AI-driven-development process)
│
├── 01-answers/                              ← DIRECT ANSWERS (hand-written, no AI)
│   ├── laravel/                             6/6 tests passing
│   └── flutter/                             6/6 tests passing
│
└── 02-showcase/                             ← PAWMISE (AI-driven, production-grade)
    ├── laravel/                             Full backend API — tested, OpenAPI, CI
    └── flutter/                             Adaptive UI, Riverpod, custom M3 theme
```

---

## The honest 01 / 02 split

The assessment brief says the answer must not be built with AI. That rule is respected — and then deliberately exceeded.

**`01-answers/`** is the direct, hand-written answer to the marking sheet. No AI. Every rubric item is mapped to the exact file that satisfies it. It grades in five minutes and the tests are green.

**`02-showcase/`** evolved into **Pawmise** — a real pet-adoption product, built using AI-driven development (Claude + the `superpowers` plugin). It is not a separate answer to the same question. It is a demonstration, in a production-quality codebase, that I can *direct* AI to build software I would actually ship.

The two folders serve different purposes:

- Read `01-answers/` to verify the rubric. It is complete.
- Read `02-showcase/` to see how I engineer. The process is documented in [`docs/how-02-was-built.md`](docs/how-02-was-built.md).

---

## Pawmise

Pawmise is a pet-adoption platform that unifies both assessment tasks into one believable product.

### The product idea

- **Flutter app** (user-facing) — browse and filter adoptable pets, view a pet's adoption-fee quote, adopt, see your adoption history. Wired to the live backend at the data layer; Riverpod state management; adaptive UI that reflows from one column on a phone to four on a desktop; custom Material 3 theme (hand-picked palette, Fraunces + Plus Jakarta Sans).
- **Laravel backend** (the real API) — Sanctum-authenticated REST API: pets listing and filtering, a transactional adopt flow, user accounts, and the **discount engine reused as the adoption-fee calculator**.

### The discount engine as the fee engine

This is the part that ties both assessment tasks together.

The marking sheet asks for a discount system with three strategies: fixed, percentage, loyalty. Pawmise reuses that domain layer — unchanged — as the engine behind adoption fees:

| Fee reason | Engine strategy | Trigger |
|------------|-----------------|---------|
| Repeat-adopter loyalty | `PercentageDiscount` | user's `adoptions_count ≥ N` |
| Senior pet | `PercentageDiscount` | `pet.age_years ≥ 8` |
| Shelter-partner waiver | `FixedDiscount` | `pet.shelter_partner = true` |

The new class `Domain/Adoption/AdoptionFeeCalculator` composes the existing strategies — it doesn't rewrite them. The legacy `POST /api/v1/discount` endpoint is retained, unchanged, proving the pure engine still stands. `Domain/Discount` source is untouched.

### What is built and tested

The backend (Laravel API) covers:

- Sanctum auth (`register`, `login`, `GET /me`)
- Pets listing with filters (species, size, status, senior, name search), pagination, and a `PetResource`
- `GET /pets/{id}/fee-quote` — fee preview for the acting user (loyalty reflected), no side effects
- `POST /pets/{id}/adopt` — transactional: guards pet availability, computes fee via `AdoptionFeeCalculator`, creates an `Adoption` record, flips pet status, increments `user.adoptions_count`. Concurrent double-adopt returns 409.
- `GET /me/adoptions` — history with full fee breakdowns (base fee, discount type, discount amount, final fee)
- Every endpoint and the full fee engine are covered by an automated suite (see CI / `composer test`)
- OpenAPI 3.1 specification and Postman collection

The Flutter app is wired to the live backend at the data layer. Riverpod `AsyncNotifier` providers drive real API calls for the pet list, fee quotes, and the adopt action. The adaptive `LayoutBuilder` grid, custom Material 3 theme, skeleton loaders, and animations are all in place.

### Deploy plan

No live public URL yet. Deploy plan: Laravel backend + MySQL on **Railway**, Flutter web on **Cloudflare Pages**. This is Phase 4 of the roadmap.

---

## How 02 was built with AI — and why that's a strength

The brief says "don't use AI for the answer". I didn't. `01-answers/` is clean.

`02-showcase/` is something different: a demonstration that I can *manage* AI as a development tool to produce production-quality software. The workflow:

1. **Brainstorm** — define the product, constraints, and boundaries
2. **Spec** — write precise technical specs for each phase (see `docs/superpowers/specs/`)
3. **Plan** — break the spec into independent, reviewable tasks
4. **Execute with review gates** — run subagents against the plan; review output for correctness, architecture fit, and test coverage before accepting
5. **Verify** — run the full test suite; read the generated code as I would in a code review

AI fluency — knowing what to spec, what to review, when to push back, and how to integrate the output — is a real engineering skill. Every design decision in `02-showcase/` (the layered architecture, the domain/framework separation, the fee engine composition, the RFC 7807 error semantics) was made by me. The AI generated the code to a spec I wrote.

The full process is documented in [`docs/how-02-was-built.md`](docs/how-02-was-built.md).

---

## Look and feel

Same Flutter code, adapts to screen size:

| Desktop (grid reflows to 4 columns) | Mobile (single column) |
|-------------------------------------|------------------------|
| ![Desktop](docs/screenshots/01-list-desktop.png) | ![Mobile](docs/screenshots/02-list-mobile.png) |

Both are the same Dart code driven by `LayoutBuilder` — no separate mobile/desktop implementations.

---

## Running it locally

Each project has a full runbook in its own README. The short version:

```bash
# 01-answers — direct rubric answers
(cd 01-answers/laravel && composer install && composer test)
(cd 01-answers/flutter && flutter pub get && flutter test)

# 02-showcase — Pawmise backend
(cd 02-showcase/laravel && composer install && cp .env.example .env)
(cd 02-showcase/laravel && php artisan key:generate && php artisan migrate --seed)
(cd 02-showcase/laravel && composer test)
(cd 02-showcase/laravel && php artisan serve)     # http://127.0.0.1:8000/api/v1

# 02-showcase — Pawmise Flutter app
(cd 02-showcase/flutter && flutter pub get && flutter test)
(cd 02-showcase/flutter && flutter run -d chrome) # or -d macos
```

Prerequisites: PHP ≥ 8.2 + Composer, Flutter ≥ 3.22. On macOS: `brew install php composer && brew install --cask flutter`.

For Docker: `(cd 02-showcase/laravel && docker compose up)` brings up nginx + php-fpm + MySQL.

---

## Contact

**Marwan Bukhori** · marwanbukhori.dev@gmail.com

Happy to walk through the code. [`docs/decisions.md`](docs/decisions.md) covers the design trade-offs; [`docs/how-02-was-built.md`](docs/how-02-was-built.md) covers the AI-driven-development process if either is a useful starting point for questions.
