# Pawmise — Product Roadmap

**Author:** Marwan Bukhori · **Date:** 2026-07-10

## Context

This repository is a submission for the GATES IT Solution full-stack developer
assessment (a Laravel discount system + a Flutter pet-adoption screen). The
reviewers stated the *answer* must not be built with AI.

The repo therefore has two parts, with a clear and honest boundary:

- **`01-answers/`** — the direct answer to the marking sheet. Written by hand,
  **no AI**. Kept pristine. This is what satisfies the "no AI" rule.
- **`02-showcase/`** — evolved into **Pawmise**, a real product built with
  **AI-driven development** (Claude + the `superpowers` plugin). This is a
  deliberate, transparent demonstration that the candidate can *direct* AI to
  ship enterprise-grade software — framed as a hireable strength, not a
  rule-break.

Audience for all documentation: **the software engineer reviewing the exercise.**

## The product

**Pawmise** — a pet-adoption platform that unifies both assessment tasks into
one believable product:

- **Flutter app** (user-facing) — browse & filter adoptable pets, view details,
  adopt, manage an account. Talks to a **real backend**, not mock data.
- **Laravel backend** (the real API) — pets, adoptions, users/auth, and the
  **discount engine reused as the adoption-fee calculator**:
  - Loyalty discount → repeat adopters
  - Percentage discount → senior pets
  - Fixed discount → shelter-partner fee waivers
- **Admin panel** (shelter staff) — manage pets, mark adopted, configure promos.
- **Live, clickable demo** + premium docs/presentation.

## Phased roadmap

Each phase gets its own spec → plan → build cycle. We build one phase at a time.

| Phase | Delivers | Rationale |
|-------|----------|-----------|
| **1 — Backend foundation & API contract** | MySQL, seeded pets, Sanctum auth, pets + adoption endpoints, discount engine wired to adoption fees, OpenAPI 3.1, tests | The API is the contract everything depends on. |
| **2 — Flutter end-to-end** | Rewire the Flutter app to the live API: browse/filter/detail/adopt persist; login; loyalty discount in the fee; real network + error/loading/offline states | Makes the product *real* — a reviewer can adopt a pet and it sticks. |
| **3 — Admin panel** | Shelter-staff web UI (Filament/Livewire): CRUD pets, mark adopted, configure promos | Demonstrates internal-tools maturity; makes the demo self-serve. |
| **4 — Deploy & CI/CD** | Backend + admin on Railway, Flutter web on Cloudflare Pages, one public clickable URL, CI/CD to live, seeded demo data | "Big company" = actually running, not just on a laptop. |
| **5 — Presentation layer** | Docs site, architecture diagrams, design system, README/docs reframe for the SE reviewer, the honest "how AI built this" doc, walkthrough | The Apple-tier packaging that ties it together. |

### Deployment plan (Phase 4)

- **Flutter web** → Cloudflare Pages (or GitHub Pages) — static, free, no cold
  starts, no expiry.
- **Laravel backend + MySQL + admin** → Railway (trial credit / ~$5 Hobby),
  scripted via Railway tooling. Sized for a low-traffic 2–3 week reviewer window.
- Truly-free fallback: Render free tier (accepts cold starts; free managed DB
  expires after 30 days — fine for the window).

## Documentation reframe (spanning)

- **Now (light):** top-level `README.md` + the `01`/`02` framing rewritten so the
  repo reads coherently for the SE reviewer even mid-build.
- **Phase 5 (full):** the complete presentation layer.

## Scope guardrails (YAGNI)

- `01-answers/` is **never** touched during Pawmise work.
- The existing `Domain/Discount` engine is **composed, not rewritten**.
- Each phase ships working, tested software before the next begins.
```
