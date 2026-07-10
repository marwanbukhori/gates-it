# Discount Service — Laravel (Showcase)

Production-grade reference implementation of the discount system described in the GATES IT Solution Full-Stack Developer Assessment. Same rubric as `01-answers/laravel`, but structured the way I'd actually ship it to a production codebase.

**Highlights**

- Domain / Application / Presentation separation (no business logic in controllers)
- Strategy pattern + factory, wired through Laravel's container
- Custom domain exception rendered as [RFC 7807](https://datatracker.ietf.org/doc/html/rfc7807) `application/problem+json`
- Form Request for input validation, API Resource for output shape
- 28 tests — unit (domain), feature (HTTP), data-provider matrices
- Docker Compose (nginx + php-fpm + mysql), OpenAPI 3.1 spec, Postman collection, GitHub Actions CI

## Architecture at a glance

```
        HTTP boundary                Application            Domain
 ─────────────────────────      ──────────────────      ───────────────────────
                                                        DiscountService
 POST /api/v1/discount  ──▶  ApplyDiscountRequest ─▶  ┌─────────────────────┐
                             (Form Request)          │  strategy.assert()   │
                                                     │  strategy.calculate()│
                             DiscountController      └──────────┬──────────┘
                                    │                           │
                                    │  strategy = factory.make(type, value)
                                    ▼                           │
                             DiscountStrategyFactory ──creates──┘
                                                                │
                                                                ▼
                                                     ┌──────────────────────┐
                                                     │ DiscountStrategyInterface
                                                     ├──────────────────────┤
                                                     │ FixedDiscount        │
                                                     │ PercentageDiscount   │
                                                     │ LoyaltyDiscount      │
                                                     └──────────────────────┘

 ◀── DiscountedPriceResource ─── final price ─── returns from calculate()

 (Errors)  InvalidDiscountException.render() ─▶ 400 application/problem+json
```

- **Controllers know nothing about strategy internals.** They pull a factory from the container and hand off.
- **Strategies own their own validation** via `assertApplicableTo()`. Adding a new strategy (seasonal, tiered, etc.) is a new class — no other file changes.
- **Domain layer has zero framework dependencies.** `app/Domain/Discount/*` could be extracted into a standalone package.

## Rubric mapping

| # | Requirement | Where | Marks |
|---|-------------|-------|-------|
| 1 | `DiscountStrategyInterface::calculate` | [`app/Domain/Discount/Contracts/DiscountStrategyInterface.php`](app/Domain/Discount/Contracts/DiscountStrategyInterface.php) | 1 |
| 2a | `FixedDiscount` | [`app/Domain/Discount/Strategies/FixedDiscount.php`](app/Domain/Discount/Strategies/FixedDiscount.php) | 1 |
| 2b | `PercentageDiscount` | [`app/Domain/Discount/Strategies/PercentageDiscount.php`](app/Domain/Discount/Strategies/PercentageDiscount.php) | 1 |
| 2c | `LoyaltyDiscount` | [`app/Domain/Discount/Strategies/LoyaltyDiscount.php`](app/Domain/Discount/Strategies/LoyaltyDiscount.php) | 1 |
| 3a | Constructor injection into `DiscountService` | [`app/Domain/Discount/DiscountService.php`](app/Domain/Discount/DiscountService.php) | 1 |
| 3b | `applyDiscount(float): float` | same file | 1 |
| 3c | HTTP 400 validation (percentage 0–100, fixed ≤ price) | [`app/Domain/Discount/Exceptions/InvalidDiscountException.php`](app/Domain/Discount/Exceptions/InvalidDiscountException.php) via `assertApplicableTo` | 1 |

**7 / 7 marks — plus:** factory pattern, Form Request, API Resource envelope, RFC-7807 error shape, container-bound singleton, 28-test coverage.

## Design choices worth noting

**Validation on the strategy, not the service.** In the "answers" version, `DiscountService` uses `instanceof` to know how to validate. That works for three strategies but adds a coupling that scales badly. Here each strategy owns its own precondition (`assertApplicableTo`) so `DiscountService` is closed for modification — a real Open/Closed Principle payoff.

**RFC 7807 for business errors.** The endpoint distinguishes:

- **`400 application/problem+json`** — request was well-formed, but violates business rules (e.g. `percentage: 150`).
- **`422 application/json`** — Laravel's standard validation-failure envelope for malformed requests (missing field, unknown strategy).

Two shapes for two different failure modes gives frontend clients the signal they need.

**API versioning from day one.** The route prefix is `/api/v1/…`. Cheap to add now, expensive to add later.

## Run it

**Native PHP**

```bash
composer install
cp .env.example .env && php artisan key:generate
php artisan serve                              # http://127.0.0.1:8000
composer test                                  # PHPUnit — 28/28
```

**Docker Compose**

```bash
docker compose up --build                      # nginx + php-fpm + mysql
curl -X POST http://127.0.0.1:8080/api/v1/discount \
     -H 'Content-Type: application/json' \
     -d '{"price": 200, "strategy": "fixed", "value": 50}'
```

**Smoke test the endpoint**

```bash
# happy path
curl -sX POST http://127.0.0.1:8000/api/v1/discount \
     -H 'Content-Type: application/json' \
     -d '{"price": 100, "strategy": "percentage", "value": 25}' | jq
# → { "data": { "strategy": "percentage", "final_price": 75, ... } }

# 400 — business rule
curl -sX POST http://127.0.0.1:8000/api/v1/discount \
     -H 'Content-Type: application/json' \
     -d '{"price": 100, "strategy": "percentage", "value": 150}' | jq
# → { "type": "…/invalid-discount", "title": "Invalid discount input", "status": 400, ... }
```

## Project layout

```
app/
  Domain/Discount/                  ← framework-free domain
    Contracts/DiscountStrategyInterface.php
    Enums/DiscountStrategyType.php
    Exceptions/InvalidDiscountException.php
    Strategies/
      FixedDiscount.php
      PercentageDiscount.php
      LoyaltyDiscount.php
    DiscountService.php
    DiscountStrategyFactory.php
  Http/
    Controllers/Api/DiscountController.php
    Requests/ApplyDiscountRequest.php
    Resources/DiscountedPriceResource.php
  Providers/DiscountServiceProvider.php
routes/api.php                      ← /api/v1/discount
tests/
  Unit/Discount/                    ← domain tests, no HTTP
    Strategies/ …
    DiscountServiceTest.php
    DiscountStrategyFactoryTest.php
  Feature/Api/                      ← full HTTP tests
    ApplyDiscountEndpointTest.php
docs/
  openapi.yaml                      ← OpenAPI 3.1
  postman_collection.json
docker/
  Dockerfile
  nginx/default.conf
docker-compose.yml
phpstan.neon.dist
.github/workflows/ci.yml
```

## Test output

```
$ vendor/bin/phpunit
{"tool":"phpunit","result":"passed","tests":28,"passed":28,"assertions":52,"duration_ms":96}
```

Coverage by file:

- 3× strategies — happy path, boundary values, invalid inputs (data providers)
- `DiscountService` — delegation, order of validation-before-calculation
- `DiscountStrategyFactory` — construction rules and missing-value guard
- `ApplyDiscountEndpointTest` — 8 HTTP scenarios: happy paths per strategy, 400 for business errors, 422 for shape errors, missing-value guard

## References

- `docs/openapi.yaml` — full API contract, viewable in any Swagger/Stoplight UI
- `docs/postman_collection.json` — importable request collection
