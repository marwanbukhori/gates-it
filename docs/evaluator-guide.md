# Evaluator guide

A five-minute path through the repository, mapped to the marking sheet. Every requirement is a link to the exact file that satisfies it.

## Grading in 5 minutes

1. Open [`01-answers/laravel/app/Contracts/DiscountStrategyInterface.php`](../01-answers/laravel/app/Contracts/DiscountStrategyInterface.php) and the three strategy files in `01-answers/laravel/app/Services/`. That is the entire Laravel rubric.
2. Open [`01-answers/flutter/lib/models/`](../01-answers/flutter/lib/models/) and [`01-answers/flutter/lib/repositories/pet_repository.dart`](../01-answers/flutter/lib/repositories/pet_repository.dart). That is the entire Flutter rubric.
3. Run the tests: `(cd 01-answers/laravel && composer test)` and `(cd 01-answers/flutter && flutter test)`. Both are green.
4. If you want to see the same problems solved at a senior level — including how the discount engine was reused as a real product's fee calculator — open [`02-showcase/`](../02-showcase/).

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
```

## Rubric mapping — Flutter (5 marks)

| # | Requirement | `01-answers/flutter` | `02-showcase/flutter` |
|---|-------------|----------------------|-----------------------|
| 1a | Abstract `Pet` (name, age, breed, isAdopted) | [`lib/models/pet.dart`](../01-answers/flutter/lib/models/pet.dart) | [`lib/features/pets/domain/pet.dart`](../02-showcase/flutter/lib/features/pets/domain/pet.dart) |
| 1b (Dog) | `Dog` with `isTrained` (default false) | [`lib/models/dog.dart`](../01-answers/flutter/lib/models/dog.dart) | [`lib/features/pets/domain/dog.dart`](../02-showcase/flutter/lib/features/pets/domain/dog.dart) |
| 1b (Cat) | `Cat` with `isIndoor` (default true) | [`lib/models/cat.dart`](../01-answers/flutter/lib/models/cat.dart) | [`lib/features/pets/domain/cat.dart`](../02-showcase/flutter/lib/features/pets/domain/cat.dart) |
| 2 | `PetRepository` returning the seed list | [`lib/repositories/pet_repository.dart`](../01-answers/flutter/lib/repositories/pet_repository.dart) | [`lib/features/pets/data/`](../02-showcase/flutter/lib/features/pets/data/) behind an [`abstract interface class`](../02-showcase/flutter/lib/features/pets/domain/pet_repository.dart) |

**Test proof:**

```bash
$ (cd 01-answers/flutter && flutter test)
00:00 +6: All tests passed!
```

The brief also describes filtering by species and marking pets as adopted (not scored, but described). Both are implemented:

- **Filter:** `PetFilter.dogs / .cats / .all` — [answers](../01-answers/flutter/lib/main.dart) | [showcase](../02-showcase/flutter/lib/features/pets/presentation/widgets/pet_filter_bar.dart)
- **Adopt:** `setState`-based mutation in answers | Riverpod `AsyncNotifier.adopt(id)` producing a new immutable list in showcase

## What to notice in `02-showcase/`

If you are grading depth, these are the details that differentiate senior work from junior work.

**Laravel — the discount engine becomes a fee engine**

The most interesting thing in `02-showcase/` is not any individual class — it is the composition. `Domain/Adoption/AdoptionFeeCalculator` takes a `Pet` and a `User`, decides which fee discount applies (loyalty / senior / shelter-partner), and delegates the arithmetic to the existing `Domain/Discount` strategies. The strategies are unchanged. The fee engine is a new layer on top.

This is what "open for extension, closed for modification" looks like in practice: a new product requirement (adoption fees) is satisfied without touching existing, tested code.

Other details:

- Business logic in `app/Domain/` is framework-free. The discount domain imports zero `Illuminate\*` classes. An Artisan command, a queue worker, or a different framework could use it directly.
- Each strategy owns its own `assertApplicableTo()` method. Adding a new strategy does not touch `DiscountService`.
- The custom `InvalidDiscountException` implements Laravel's renderable-exception contract. Business errors become RFC 7807 `application/problem+json` automatically — no scattered try/catch.
- `ApplyDiscountRequest` uses `Rule::enum()` and `withValidator()` for cross-field validation, so `422` (malformed request) and `400` (invalid business input) are cleanly distinguishable by API consumers.

**Flutter — wired to a real backend**

- Feature-first structure (`features/pets/{domain,data,application,presentation}`) with a strict one-way dependency rule — domain has no Flutter imports at all.
- The repository is an `abstract interface class`. The UI never sees `InMemoryPetRepository`. Swapping to HTTP or SQLite is one override.
- Every pet is immutable. `Dog.copyWith(isAdopted: true)` returns a new `Dog`. Riverpod's rebuild logic gives correct granular updates.
- The theme is seedless — hand-picked palette, Fraunces for headers, Plus Jakarta Sans for body. Doesn't look like a default Material 3 app.
- The grid picks 1/2/3/4 columns from `LayoutBuilder`. No hard-coded breakpoints, no separate mobile/desktop implementations.

## Deeper reading

- [`architecture.md`](architecture.md) — system design including Pawmise API topology and Flutter layers
- [`decisions.md`](decisions.md) — every non-obvious design choice with context and trade-offs
- [`how-02-was-built.md`](how-02-was-built.md) — the AI-driven-development process that produced `02-showcase/`

## Environment used for verification

- macOS Darwin 23.1.0 (Apple Silicon)
- PHP 8.5.8 (Homebrew) · Composer 2.10.2
- Flutter 3.44.6 · Dart 3.12.2
- Laravel 13.x (`02-showcase/laravel`)
- Riverpod 3.x (`02-showcase/flutter`)
