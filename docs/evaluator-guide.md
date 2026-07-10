# Evaluator guide

A five-minute path through the repository, mapped to the marking sheet. Every requirement is a link to the exact file that satisfies it.

## Grading in 5 minutes

1. Open [`01-answers/laravel/app/Contracts/DiscountStrategyInterface.php`](../01-answers/laravel/app/Contracts/DiscountStrategyInterface.php) and the three files in `01-answers/laravel/app/Services/`. That's the entire Laravel rubric.
2. Open [`01-answers/flutter/lib/models/`](../01-answers/flutter/lib/models/) and [`01-answers/flutter/lib/repositories/pet_repository.dart`](../01-answers/flutter/lib/repositories/pet_repository.dart). That's the entire Flutter rubric.
3. Run the tests: `(cd 01-answers/laravel && composer test)` and `(cd 01-answers/flutter && flutter test)`. Both should be green.
4. If you want to see the same problems solved at a senior level, open [`02-showcase/`](../02-showcase/).

## Rubric mapping — Laravel (7 marks)

| # | Requirement | `01-answers/laravel` | `02-showcase/laravel` |
|---|-------------|----------------------|-----------------------|
| 1 | `DiscountStrategyInterface` with `calculate(float): float` | [`app/Contracts/DiscountStrategyInterface.php`](../01-answers/laravel/app/Contracts/DiscountStrategyInterface.php) | [`app/Domain/Discount/Contracts/DiscountStrategyInterface.php`](../02-showcase/laravel/app/Domain/Discount/Contracts/DiscountStrategyInterface.php) |
| 2a | `FixedDiscount` — `original − amount` | [`app/Services/Discounts/FixedDiscount.php`](../01-answers/laravel/app/Services/Discounts/FixedDiscount.php) | [`app/Domain/Discount/Strategies/FixedDiscount.php`](../02-showcase/laravel/app/Domain/Discount/Strategies/FixedDiscount.php) |
| 2b | `PercentageDiscount` — `original − (pct × original)` | [`app/Services/Discounts/PercentageDiscount.php`](../01-answers/laravel/app/Services/Discounts/PercentageDiscount.php) | [`app/Domain/Discount/Strategies/PercentageDiscount.php`](../02-showcase/laravel/app/Domain/Discount/Strategies/PercentageDiscount.php) |
| 2c | `LoyaltyDiscount` — `original − (0.85 × original)` | [`app/Services/Discounts/LoyaltyDiscount.php`](../01-answers/laravel/app/Services/Discounts/LoyaltyDiscount.php) | [`app/Domain/Discount/Strategies/LoyaltyDiscount.php`](../02-showcase/laravel/app/Domain/Discount/Strategies/LoyaltyDiscount.php) |
| 3a | Constructor injection into `DiscountService` | [`app/Services/DiscountService.php`](../01-answers/laravel/app/Services/DiscountService.php) | [`app/Domain/Discount/DiscountService.php`](../02-showcase/laravel/app/Domain/Discount/DiscountService.php) |
| 3b | `applyDiscount(float): float` uses the strategy | same file | same file |
| 3c | HTTP 400 for percentage 0–100 and fixed ≤ price | same file — `throw BadRequestHttpException` | [`app/Domain/Discount/Exceptions/InvalidDiscountException.php`](../02-showcase/laravel/app/Domain/Discount/Exceptions/InvalidDiscountException.php) with `render()` returning RFC 7807 `application/problem+json` |

**Test proof:**

```bash
$ (cd 01-answers/laravel && composer test)
OK (6 tests, 6 assertions)

$ (cd 02-showcase/laravel && composer test)
{"tool":"phpunit","result":"passed","tests":28,"passed":28,"assertions":52}
```

## Rubric mapping — Flutter (5 marks)

| # | Requirement | `01-answers/flutter` | `02-showcase/flutter` |
|---|-------------|----------------------|-----------------------|
| 1a | Abstract `Pet` (name, age, breed, isAdopted) | [`lib/models/pet.dart`](../01-answers/flutter/lib/models/pet.dart) | [`lib/features/pets/domain/pet.dart`](../02-showcase/flutter/lib/features/pets/domain/pet.dart) |
| 1b (Dog) | `Dog` with `isTrained` (default false) | [`lib/models/dog.dart`](../01-answers/flutter/lib/models/dog.dart) | [`lib/features/pets/domain/dog.dart`](../02-showcase/flutter/lib/features/pets/domain/dog.dart) |
| 1b (Cat) | `Cat` with `isIndoor` (default true) | [`lib/models/cat.dart`](../01-answers/flutter/lib/models/cat.dart) | [`lib/features/pets/domain/cat.dart`](../02-showcase/flutter/lib/features/pets/domain/cat.dart) |
| 2 | `PetRepository` returning the seed list | [`lib/repositories/pet_repository.dart`](../01-answers/flutter/lib/repositories/pet_repository.dart) | [`lib/features/pets/data/in_memory_pet_repository.dart`](../02-showcase/flutter/lib/features/pets/data/in_memory_pet_repository.dart) behind an [`abstract interface class`](../02-showcase/flutter/lib/features/pets/domain/pet_repository.dart) |

**Test proof:**

```bash
$ (cd 01-answers/flutter && flutter test)
00:00 +6: All tests passed!

$ (cd 02-showcase/flutter && flutter test)
00:00 +12: All tests passed!
```

The PDF also describes filtering by species and marking pets as adopted (not scored, but described in the brief). Both are implemented:

- **Filter:** `PetFilter.dogs / .cats / .all` — [answers](../01-answers/flutter/lib/main.dart) | [showcase](../02-showcase/flutter/lib/features/pets/presentation/widgets/pet_filter_bar.dart)
- **Adopt:** setState-based mutation | Riverpod `AsyncNotifier.adopt(id)` producing a new immutable list

## What to notice in `02-showcase/`

If you're grading depth as well as correctness, these are the details that differentiate senior work from junior work:

**Laravel:**

- Business logic lives in `app/Domain/`, framework-free — the discount domain doesn't import a single Laravel class. Adding another framework in front of it (a CLI command, a queue worker, an Artisan job) is free.
- Each strategy owns its own validation via `assertApplicableTo()`. Adding a new strategy (`SeasonalDiscount`) doesn't touch `DiscountService`. That's the Open/Closed Principle applied where it actually matters.
- The custom `InvalidDiscountException` implements Laravel's renderable-exception contract, so business errors become RFC 7807 `application/problem+json` responses automatically — no try/catch scattered across controllers.
- The Form Request (`ApplyDiscountRequest`) uses `Rule::enum()` and cross-field validation via `withValidator()`, so `422` failures (malformed request) and `400` failures (invalid business input) are cleanly distinguishable to API consumers.

**Flutter:**

- Feature-first structure (`features/pets/{domain,data,application,presentation}`) with a strict layering rule — domain has no Flutter imports at all. Same as Laravel: framework-independence where it counts.
- The repository is an `abstract interface class`. The UI never sees `InMemoryPetRepository`. Swapping to an HTTP or SQLite backend is one override in one file.
- Every pet is immutable. `Dog.copyWith(isAdopted: true)` returns a new `Dog` — the old one still exists. Riverpod's rebuild logic just works.
- The theme is *seedless* — hand-picked palette, Fraunces for headers, Plus Jakarta Sans for body. Doesn't have that generic "seeded Material 3" look.
- The grid picks 1 / 2 / 3 / 4 columns based on parent width via `LayoutBuilder`. No hard-coded breakpoints in the theme, no separate mobile / desktop implementations.

## Deeper reading

- [`architecture.md`](architecture.md) — how the code is organised, with diagrams
- [`decisions.md`](decisions.md) — the interesting design decisions, with rationale and trade-offs

## Environment used for verification

- macOS Darwin 23.1.0 (Apple Silicon)
- PHP 8.5.8 (Homebrew)
- Composer 2.10.2
- Flutter 3.44.6 · Dart 3.12.2
- Laravel 13.19.0 (`02-showcase/laravel`)
- Riverpod 3.3.2 (`02-showcase/flutter`)

Everything was installed fresh during this build session and every test suite was executed against the actual code.
