# Architecture

Both parts of `02-showcase/` (Pawmise) follow the same principle: **business rules go in the middle, framework code goes at the edges**. The two products share a common dependency direction: domain → application → infrastructure, never the reverse.

---

## Laravel — Pawmise API

The backend grew from a stateless discount calculator into a real product API. The discount domain was composed — not modified.

### System overview

```
        HTTP boundary                  Application layer          Domain
 ─────────────────────────         ──────────────────────      ──────────────────────────

 POST /auth/register
 POST /auth/login        ──▶  AuthController
 GET  /me

 GET  /pets              ──▶  PetController          ──▶   Pet model (Eloquent)
 GET  /pets/{id}

 GET  /pets/{id}/        ──▶  AdoptionController     ──▶   AdoptionFeeCalculator
      fee-quote                                             │
                                                           ├── PercentageDiscount (loyalty)
 POST /pets/{id}/adopt   ──▶  AdoptionController     ──▶   ├── PercentageDiscount (senior)
                                                           └── FixedDiscount (shelter-partner)

 GET  /me/adoptions      ──▶  AdoptionController          Adoption model (Eloquent)

 POST /api/v1/discount   ──▶  DiscountController    ──▶   DiscountService (legacy — unchanged)
```

### Folder layout (selected)

```
app/
├── Domain/
│   ├── Discount/                   ← unchanged from assessment — no imports of Illuminate\*
│   │   ├── Contracts/
│   │   │   └── DiscountStrategyInterface.php
│   │   ├── DiscountService.php
│   │   ├── DiscountStrategyFactory.php
│   │   ├── Enums/
│   │   │   └── DiscountStrategyType.php
│   │   ├── Exceptions/
│   │   │   └── InvalidDiscountException.php
│   │   └── Strategies/
│   │       ├── FixedDiscount.php
│   │       ├── PercentageDiscount.php
│   │       └── LoyaltyDiscount.php
│   │
│   └── Adoption/                   ← new; composes Domain/Discount
│       ├── AdoptionFeeCalculator.php
│       ├── FeeBreakdown.php         (value object)
│       └── FeeDiscount.php          (enum: loyalty | senior | shelter_partner)
│
├── Http/
│   ├── Controllers/Api/
│   ├── Requests/
│   └── Resources/
│
├── Models/
│   ├── User.php                     (+ adoptions_count)
│   ├── Pet.php                      (species, breed, age, shelter_partner, status)
│   └── Adoption.php                 (immutable fee record)
│
└── Providers/
    ├── AppServiceProvider.php
    └── DiscountServiceProvider.php
```

### Layer rules

| Layer | Path | May depend on | Must not depend on |
|-------|------|---------------|--------------------|
| **Domain/Discount** | `app/Domain/Discount/` | Symfony HTTP kernel (exception base only) | `Illuminate\*` |
| **Domain/Adoption** | `app/Domain/Adoption/` | `Domain/Discount`, PHP stdlib | `Illuminate\*` |
| **Application (HTTP)** | `app/Http/` | Domain, Laravel framework | Concrete strategy classes |
| **Models** | `app/Models/` | Laravel Eloquent | Domain (models are data access, not business logic) |
| **Providers** | `app/Providers/` | Domain, framework | HTTP layer |

The **Domain layers** are the parts I would extract into a package if this code were shared across multiple apps. The adoption calculator delegates all arithmetic to the discount strategies and never touches a Laravel class.

### The fee engine composition

`AdoptionFeeCalculator` receives a `Pet` and a `User` and does three things:

1. Determines which `FeeDiscount` variants apply for that combination (could be multiple).
2. Selects the single best discount (maximum saving). The selection rule is centralised — easily changed to stacking later.
3. Instantiates the correct `Domain/Discount` strategy via the `DiscountStrategyFactory` and delegates the arithmetic.

The output is a `FeeBreakdown` value object: `{ base_fee, discount_type, discount_amount, final_fee }`. This is stored on the `Adoption` record, making every adoption auditable.

```
AdoptionFeeCalculator::quote(Pet $pet, User $user): FeeBreakdown
    │
    ├── senior?       → PercentageDiscount(config('pawmise.senior_discount_pct'))
    ├── shelter_partner? → FixedDiscount(config('pawmise.shelter_waiver'))
    └── adoptions_count ≥ N? → PercentageDiscount(config('pawmise.loyalty_discount_pct'))
                                                    ↑ all three are Domain/Discount strategies
    → pick best discount (max saving)
    → DiscountService::applyDiscount(base_fee) → final_fee
```

Fee thresholds live in `config/pawmise.php` — no magic numbers in the domain.

### Error semantics

Two failure modes, two response shapes, the same as the original discount API:

| Failure | Status | Content-Type | Meaning |
|---------|--------|--------------|---------|
| Missing / wrong-shaped field | `422` | `application/json` | The request itself is malformed |
| Well-formed request, invalid business input | `400` | `application/problem+json` | The discount doesn't apply |
| Pet already adopted | `409` | `application/problem+json` | Concurrent adoption guard |
| No auth token / expired | `401` | `application/json` | Sanctum standard |

### Adoption transaction

`POST /pets/{id}/adopt` runs inside a database transaction:

1. Acquire row lock on the `pets` row.
2. Assert `pet.status === 'available'` (returns 409 if not).
3. Compute fee via `AdoptionFeeCalculator`.
4. Insert `adoptions` record.
5. Update `pets.status = 'adopted'`.
6. Increment `users.adoptions_count`.
7. Commit.

Steps 1–2 together prevent concurrent double-adopts. The lock is released on commit/rollback.

---

## Flutter — Pawmise App

### Folder layout

```
lib/
├── main.dart                              ProviderScope root
├── app/
│   ├── app.dart                           MaterialApp + router
│   └── theme/                             seedless Material 3
│       ├── app_colors.dart
│       ├── app_spacing.dart
│       └── app_theme.dart
└── features/
    └── pets/
        ├── domain/                        ← framework-free
        │   ├── pet.dart                   abstract Pet + equality
        │   ├── dog.dart                   Dog (isTrained)
        │   ├── cat.dart                   Cat (isIndoor)
        │   └── pet_repository.dart        abstract interface class
        ├── data/                          ← concrete impls
        │   ├── in_memory_pet_repository.dart
        │   └── api_pet_repository.dart    (wired to live backend)
        ├── application/                   ← state + intent
        │   ├── pet_filter.dart            enum
        │   └── pet_providers.dart         Riverpod providers + controllers
        └── presentation/                  ← widgets only
            ├── pet_list_screen.dart
            └── widgets/
                ├── pet_filter_bar.dart
                ├── pet_card.dart
                ├── pet_grid.dart          staggered enter + adaptive cols
                ├── pet_list_skeleton.dart
                └── empty_state.dart
```

### Layer rules

| Layer | Path | May import | Must not import |
|-------|------|-----------|-----------------|
| **Domain** | `features/pets/domain/` | `flutter/foundation` (for `@immutable`) | `data`, `application`, `presentation` |
| **Data** | `features/pets/data/` | `domain` | `application`, `presentation` |
| **Application** | `features/pets/application/` | `domain`, `data`, `flutter_riverpod` | `presentation` |
| **Presentation** | `features/pets/presentation/` | any lower layer | *(top of stack)* |

Replacing Riverpod with Bloc would touch only `application/` and `presentation/`. Replacing the HTTP backend with SQLite would touch only `data/`.

### State flow

```
┌─────────────────────────────────────┐
│           PetListScreen              │
│  (ConsumerWidget — watches state)   │
└──────────────┬──────────────────────┘
               │
               │ watch                      set
               ▼                            │
   ┌──────────────────────┐    ┌───────────▼────────────┐
   │ visiblePetsProvider  │    │   petFilterProvider    │
   │ (derived / computed) │    │ (NotifierProvider)     │
   └────────┬─────────────┘    └────────────────────────┘
            │  watch
            ▼
   ┌────────────────────────────┐
   │ petListControllerProvider  │
   │ (AsyncNotifier<List<Pet>>) │
   │                            │
   │  - build(): fetch from API │
   │  - adopt(id): POST + new   │
   │    list from response      │
   └────────┬───────────────────┘
            │  read
            ▼
   ┌───────────────────────┐
   │ petRepositoryProvider │
   │  (Provider — bound to │
   │   ApiPetRepository)   │
   └───────────────────────┘
```

- The screen watches `visiblePetsProvider`, a derived provider that composes the pet list and the current filter. It doesn't watch the pet list directly.
- `PetListController.adopt(id)` calls the backend; on success, it produces a new list with the updated pet. Riverpod's equality-based rebuild sees one changed reference.
- In tests, `petRepositoryProvider.overrideWithValue(fakeRepo)` swaps the data source without touching anything else.

### Why immutability?

`Pet` is `@immutable`. `Dog.copyWith(isAdopted: true)` returns a new `Dog`, never mutating the original. This matters because:

1. Riverpod diffs by `==`. Immutable objects give correct, granular rebuild signals.
2. Any widget holding a reference to the old pet still sees the old state — useful for exit animations, undo, etc.
3. Time-travel debugging is effectively free.

### Adaptive layout

```dart
final columns = switch (constraints.maxWidth) {
  > 1200 => 4,
  > 900  => 3,
  > 620  => 2,
  _      => 1,
};
```

`LayoutBuilder` drives the column count. Same code renders as a single-column list on a phone and a four-column grid on a desktop. No `MediaQuery` checks scattered through the codebase, no separate widget trees.

### Why "seedless" Material 3?

`ColorScheme.fromSeed()` is a fine shortcut, but every seeded scheme has a family resemblance — exactly what the assessment brief warned against. This uses a hand-picked palette (deep sage / clay rose / paper cream) with species-tinted card surfaces (dogs on warm ochre, cats on muted clay-rose), so the two lists read differently at a glance. Custom fonts (Fraunces display + Plus Jakarta Sans body) give the app a distinctive look without getting in the way of scannability.
