# GATES IT Solution — Full Stack Developer Assessment

Marwan Bukhori · July 2026

This repository contains two complete deliverables for the [assessment PDF](./Full%20Stack%20Developer%20Assessment.pdf) — a focused answer to each question, and a production-grade take on the same problems.

## Two deliverables

| Folder | Purpose | Contents |
|--------|---------|----------|
| [`01-answers/`](./01-answers) | Direct, rubric-focused answer to every question in the PDF. Minimal ceremony, easy to grade against the marking scheme. | Laravel classes + PHPUnit tests · Flutter project with the required models, repository, and a small screen |
| [`02-showcase/`](./02-showcase) | The same problems built the way I'd ship them in production. Clean architecture, container wiring, custom exceptions, OpenAPI, Docker, Riverpod, adaptive UI, animations, accessibility. | Laravel with domain / app / infra layers, RFC-7807 errors, Docker Compose, CI, 28 tests · Flutter feature-first with Riverpod, custom Material 3 theme, staggered animations, 12 tests |

Start with **`01-answers/`** to see the assessment answered directly, then open **`02-showcase/`** to see how the same brief scales into real engineering.

## What each part demonstrates

### Laravel — Discount Service

Both versions solve the same brief: a `DiscountService` composed with a `DiscountStrategyInterface` (Fixed / Percentage / Loyalty), with HTTP 400 validation.

| Aspect | `01-answers/laravel` | `02-showcase/laravel` |
|--------|----------------------|-----------------------|
| Structure | 3 folders under `app/` | Domain / Http / Providers, framework-free domain layer |
| Strategy validation | `instanceof` inside `DiscountService` | Each strategy owns its own `assertApplicableTo()` — real OCP |
| Exception | `BadRequestHttpException` | Custom `InvalidDiscountException`, renders RFC 7807 `application/problem+json` |
| Strategy construction | `match` inside the controller | `DiscountStrategyFactory` bound as a container singleton |
| Validation | Inline in controller | Form Request with enum rules + cross-field checks |
| Response shape | Raw JSON | `DiscountedPriceResource` envelope (`data.*`) with computed `discount_percent` |
| Tests | 6 unit tests | 28 tests — unit + feature (HTTP), data providers |
| Ops | — | Docker Compose (nginx + php-fpm + mysql), OpenAPI 3.1, Postman, GitHub Actions CI |

### Flutter — Adoption Home

Both versions solve the same brief: abstract `Pet` with `Dog` / `Cat` subclasses, `PetRepository` returning the four seed pets, a UI to filter and mark as adopted.

| Aspect | `01-answers/flutter` | `02-showcase/flutter` |
|--------|----------------------|-----------------------|
| Structure | Flat `lib/{models,repositories,widgets}` | Feature-first `features/pets/{domain,data,application,presentation}` |
| State | `setState` in `PetListScreen` | Riverpod 3 — `AsyncNotifier` for pets, `Notifier` for filter |
| Repository | Concrete class | `abstract interface class` + concrete impl; provider-overridable in tests |
| Immutability | Mutable `isAdopted` on `Pet` | `copyWith` on every subclass, equality contract, exhaustive `switch` on subtype |
| Theme | Default M3 with a seed color | Seedless custom scheme, Fraunces + Plus Jakarta Sans, species-tinted card surfaces |
| Layout | Single column list | LayoutBuilder-driven grid (1 → 4 columns), staggered fade-in |
| States | List + snackbar | Loading skeleton, per-filter empty states, error state, animated adopt transition |
| Tests | 6 model + repo tests | 12 tests — domain, application (Riverpod overrides), widget (Semantics, tap flow) |

## Verified

Everything below was actually run on macOS Darwin 23.1.0, PHP 8.5.8, Composer 2.10.2, Flutter 3.44.6.

```
$ (cd 02-showcase/laravel && vendor/bin/phpunit)
{"tool":"phpunit","result":"passed","tests":28,"passed":28,"assertions":52,"duration_ms":96}

$ (cd 02-showcase/flutter && flutter analyze)
Analyzing flutter... No issues found!

$ (cd 02-showcase/flutter && flutter test)
00:00 +12: All tests passed!
```

The Laravel endpoint was smoke-tested end-to-end with `php artisan serve` + `curl` — see [`02-showcase/laravel/README.md`](./02-showcase/laravel/README.md#run-it) for the exact requests and responses.

## Repository layout

```
gates-assessment/
├── README.md                              ← you are here
├── Full Stack Developer Assessment.pdf    ← original brief (copy from Downloads)
├── 01-answers/
│   ├── laravel/                           7-mark Laravel answer
│   │   ├── app/{Contracts,Services,Http}
│   │   ├── routes/api.php
│   │   ├── tests/Unit/…
│   │   └── README.md
│   └── flutter/                           5-mark Flutter answer
│       ├── lib/{models,repositories,widgets}
│       ├── test/pet_repository_test.dart
│       └── README.md
└── 02-showcase/
    ├── laravel/                           production-grade Laravel
    │   ├── app/Domain/Discount/{Contracts,Enums,Exceptions,Strategies,…}
    │   ├── app/Http/{Controllers/Api,Requests,Resources}
    │   ├── app/Providers/DiscountServiceProvider.php
    │   ├── tests/{Unit/Discount,Feature/Api}
    │   ├── docs/{openapi.yaml,postman_collection.json}
    │   ├── docker/{Dockerfile,nginx/default.conf}
    │   ├── docker-compose.yml
    │   ├── .github/workflows/ci.yml
    │   └── README.md
    └── flutter/                           production-grade Flutter
        ├── lib/app/theme/…
        ├── lib/features/pets/{domain,data,application,presentation}
        ├── test/features/pets/{domain,application,presentation}
        └── README.md
```

## How to run

Each project's README has the full runbook. TL;DR:

```bash
# 01-answers — Laravel
(cd 01-answers/laravel && composer install && composer test)

# 01-answers — Flutter
(cd 01-answers/flutter && flutter pub get && flutter test)

# 02-showcase — Laravel
(cd 02-showcase/laravel && composer install && composer test)
(cd 02-showcase/laravel && php artisan serve)          # → http://127.0.0.1:8000/api/v1/discount

# 02-showcase — Flutter
(cd 02-showcase/flutter && flutter pub get && flutter test)
(cd 02-showcase/flutter && flutter run -d chrome)      # or -d macos
```

## Contact

**Marwan Bukhori** · marwanbukhori.dev@gmail.com
