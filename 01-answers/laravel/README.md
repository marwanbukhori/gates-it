# Laravel — Discount Strategy (Answers)

Direct answer to the Laravel portion of the GATES Full-Stack Developer Assessment. This folder is intentionally minimal: it contains **just the classes the rubric asks for**, plus a small PHPUnit suite that proves each one behaves correctly.

For a production-grade take on the same problem — domain layer, factory, custom exception, OpenAPI, Docker, feature tests — see `../../02-showcase/laravel`.

## Rubric mapping

| # | Requirement | Where | Marks |
|---|-------------|-------|-------|
| 1 | `DiscountStrategyInterface` with `calculate(float $originalPrice): float` | [`app/Contracts/DiscountStrategyInterface.php`](app/Contracts/DiscountStrategyInterface.php) | 1 |
| 2a | `FixedDiscount` — `original − amount` | [`app/Services/Discounts/FixedDiscount.php`](app/Services/Discounts/FixedDiscount.php) | 1 |
| 2b | `PercentageDiscount` — `original − (percentage × original)` | [`app/Services/Discounts/PercentageDiscount.php`](app/Services/Discounts/PercentageDiscount.php) | 1 |
| 2c | `LoyaltyDiscount` — `original − (0.85 × original)` | [`app/Services/Discounts/LoyaltyDiscount.php`](app/Services/Discounts/LoyaltyDiscount.php) | 1 |
| 3a | `DiscountService` accepts a strategy via constructor injection | [`app/Services/DiscountService.php`](app/Services/DiscountService.php) | 1 |
| 3b | `applyDiscount(float $price): float` uses the injected strategy | same file | 1 |
| 3c | HTTP 400 for invalid percentage (0–100) and fixed amount > price | same file (`validate()`), thrown as `BadRequestHttpException` | 1 |

**Total: 7 / 7**

## Run

```bash
composer install
composer test
```

Expected output:

```
PHPUnit 11.x by Sebastian Bergmann and contributors.

......                                                              6 / 6 (100%)

Time: 00:00.002, Memory: 8.00 MB

OK (6 tests, 6 assertions)
```

## What each test covers

`tests/Unit/DiscountServiceTest.php`:

1. Fixed discount subtracts the amount
2. Percentage discount subtracts the percent share
3. Loyalty discount applies the 0.85 factor
4. Percentage `< 0` throws `BadRequestHttpException`
5. Percentage `> 100` throws `BadRequestHttpException`
6. Fixed amount `> price` throws `BadRequestHttpException`

## Layout

```
app/
  Contracts/DiscountStrategyInterface.php
  Services/
    DiscountService.php
    Discounts/
      FixedDiscount.php
      PercentageDiscount.php
      LoyaltyDiscount.php
tests/
  Unit/DiscountServiceTest.php
composer.json
phpunit.xml
```

## Notes on the code

- **Strategy pattern.** Adding a new discount type (e.g. `SeasonalDiscount`) is a new class implementing the interface. `DiscountService` doesn't change.
- **Constructor injection.** `DiscountService::__construct(DiscountStrategyInterface $strategy)` — the service has no knowledge of concrete strategies at build time.
- **HTTP 400 semantics.** `BadRequestHttpException` from `symfony/http-kernel`. When wired into Laravel, its exception handler converts this to a JSON 400 response automatically — see the showcase folder for that wiring.
- **Percentage semantics.** The formula in the PDF (`original − percentage × original`) is only self-consistent with the "between 0 and 100" validation rule if `percentage` is treated as a whole percent. `PercentageDiscount::calculate` divides by 100 accordingly.
