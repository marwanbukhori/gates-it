# What is this? *(one-pager for anyone reading)*

## The short version

GATES IT Solution sent me a coding assessment with two tasks:

1. **Laravel** — build a discount system (fixed / percentage / loyalty discounts)
2. **Flutter** — build a mobile screen that lists adoptable pets with filtering and an adopt action

This repository contains my answer, delivered in two folders with a clear, honest boundary between them.

## The two folders

**`01-answers/`** is the direct answer to the marking sheet. Written by hand, no AI. Every rubric item maps to an exact file. If you're grading, start here — it takes about five minutes and everything is tested.

**`02-showcase/`** is the same problems, evolved into a real product called **Pawmise**. Pawmise is a pet-adoption platform with a Laravel API backend and a Flutter app that talks to it. It was built using AI-driven development (Claude + the `superpowers` plugin) — documented transparently in [`docs/how-02-was-built.md`](how-02-was-built.md).

The assessment says "the answer must not be built with AI". The answer (`01-answers/`) isn't. `02-showcase/` is something different: a demonstration that I can direct AI to produce production-quality software. Full transparency, no rule-bending.

## What Pawmise is

Pawmise unifies both assessment tasks into one product:

- The **Flutter app** is the user-facing product — browse pets, see adoption fees, adopt.
- The **Laravel backend** is the real API — authentication, pet catalogue, adoption flow.
- The **discount engine** from the assessment is reused, unchanged, as the adoption-fee calculator: loyalty discount for repeat adopters, percentage off for senior pets, fixed waiver for shelter-partner pets.

That last point is not just a cute story — it shows that good domain design makes reuse free. The `Domain/Discount` layer didn't need a single line changed to become the fee engine of a different product.

## What each mark is worth

The Laravel part is out of **7 marks**. The Flutter part is out of **5 marks**. Both are fully met in `01-answers/`.

Each project has a table in its own README (a "rubric map") linking every marking-sheet item to the exact file. See [`docs/evaluator-guide.md`](evaluator-guide.md) for a combined view.

## What the showcase adds

`01-answers/` proves I can write the classes. `02-showcase/` shows what I do after the classes exist.

**On the Laravel side** (now a real product API):
- Sanctum authentication, pets listing and filtering, a transactional adopt flow
- The discount engine composed as an adoption-fee calculator (`AdoptionFeeCalculator`)
- Every endpoint and the full fee engine covered by an automated test suite
- Docker Compose, OpenAPI 3.1 spec, Postman collection, GitHub Actions CI

**On the Flutter side** (now wired to the live backend):
- Real API calls via Riverpod `AsyncNotifier` providers
- Adaptive layout (1–4 columns, same code, `LayoutBuilder`)
- Custom Material 3 theme — hand-picked palette, not a seeded default
- Skeleton loaders, empty states, animated adopt transition, accessibility labels

## Contact

**Marwan Bukhori**
[marwanbukhori.dev@gmail.com](mailto:marwanbukhori.dev@gmail.com)
