# Architecture

Both showcase projects follow the same principle: **business rules go in the middle, framework code goes at the edges**. Below is what that looks like for each stack.

## Laravel — Discount Service

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

### Layers and their rules

| Layer | Path | May depend on | Must not depend on |
|-------|------|---------------|--------------------|
| **Domain** | `app/Domain/Discount/` | Symfony HTTP kernel (only for the exception base class) | Anything Laravel-specific |
| **Application (HTTP)** | `app/Http/{Controllers,Requests,Resources}/` | Domain, Laravel framework | Concrete strategy classes |
| **Providers** | `app/Providers/` | Domain, framework | HTTP layer |

The **domain layer** is the part I'd extract into a package if this discount system were shared across multiple apps. It has zero references to `Illuminate\*`. That's not incidental — it's the design rule.

### Why a factory?

`DiscountController` doesn't know how to build a `PercentageDiscount`. It calls `factory.make(type, value)` and gets back an interface. The factory is bound as a container singleton in `DiscountServiceProvider`, so it's swappable in tests (via `$this->app->instance(...)`) if we ever need to.

The alternative — a `match` expression inside the controller — works fine for three strategies. It stops working when someone wants to add a strategy that depends on an injected service (a `SeasonalDiscount` reading dates from a calendar service, say). The factory absorbs that change without touching the controller.

### Why "assert on the strategy" instead of "validate in the service"?

In `01-answers/`, `DiscountService::validate()` uses `$this->strategy instanceof PercentageDiscount` to decide which rule to apply. That works for three strategies. It scales terribly.

In `02-showcase/`, each strategy owns its own `assertApplicableTo()` method. Adding a new strategy adds a new class — no changes to `DiscountService`, no `instanceof` chains anywhere. That's the Open/Closed Principle actually paying off, not just being name-dropped.

### Error semantics

Two distinct failure modes, two distinct response shapes:

| Failure | Status | Body | Meaning |
|---------|--------|------|---------|
| Missing / wrong-shaped field | `422` | Laravel default validation envelope | The request itself is malformed |
| Well-formed request, invalid discount input | `400` | `application/problem+json` (RFC 7807) | The request parsed fine, but the discount doesn't apply |

Frontend clients need to distinguish "your form has a bug" from "your input violated a business rule" — different UI, different logging.

## Flutter — Adoption Home

```
lib/
├── main.dart                              ProviderScope root
├── app/                                   cross-cutting concerns
│   ├── app.dart                           MaterialApp + home
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
        │   └── in_memory_pet_repository.dart
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

### Layers and their rules

| Layer | Path | May import | Must not import |
|-------|------|-----------|-----------------|
| **Domain** | `features/pets/domain/` | `flutter/foundation` (for `@immutable`) | Anything from `data`, `application`, `presentation` |
| **Data** | `features/pets/data/` | `domain` | `application`, `presentation` |
| **Application** | `features/pets/application/` | `domain`, `data`, `flutter_riverpod` | `presentation` |
| **Presentation** | `features/pets/presentation/` | any lower layer | *(top of the stack)* |

The rule is one-way: **higher layers depend on lower layers, never the reverse**. If I ever wanted to replace Riverpod with Bloc, I'd only touch `application/` and `presentation/`. Domain and data would move over untouched.

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
   │  - build(): fetch from repo│
   │  - adopt(id): new list     │
   └────────┬───────────────────┘
            │  read
            ▼
   ┌───────────────────────┐
   │ petRepositoryProvider │
   │  (Provider — bound to │
   │   InMemoryPetRepo)    │
   └───────────────────────┘
```

- The screen watches a *derived* provider (`visiblePetsProvider`) that composes the pet list and the current filter. It doesn't watch the pet list directly.
- `PetListController.adopt(id)` produces a *new* list with a *new* pet instance for the adopted one. The other pets keep the same identity. Riverpod's equality-based rebuild logic sees exactly one changed reference and rebuilds only the affected widget.
- In tests, `petRepositoryProvider.overrideWithValue(fakeRepo)` swaps the data source without touching anything else. Same pattern would work for an HTTP client, a SQLite backend, or a Firebase reader.

### Why immutability?

`Pet` is `@immutable`. `Dog.copyWith(isAdopted: true)` returns a *new* Dog, doesn't mutate the old one. This matters because:

1. Riverpod diffs by `==`. Immutable objects give correct rebuild signals.
2. Any widget holding a reference to the old pet still sees the old state — useful for exit animations, undo, etc.
3. Time-travel debugging and Redux-style dev tooling are effectively free.

### Why "seedless" Material 3?

`ColorScheme.fromSeed()` is a lovely shortcut, but every seeded scheme has a family resemblance — the AI-generated aesthetic the assessment specifically warned against. This uses a hand-picked palette (deep sage / clay rose / paper cream) with species-tinted card surfaces (dogs on warm ochre, cats on muted clay-rose) so the two lists visually read differently at a glance.

Custom fonts — Fraunces (display) + Plus Jakarta Sans (body) — do a similar job. They're distinctive enough that the app looks like it has a brand, but not so quirky they get in the way of scannability.

### Adaptive layout

The grid picks its column count from `LayoutBuilder(constraints.maxWidth)`:

```dart
final columns = switch (constraints.maxWidth) {
  > 1200 => 4,
  > 900  => 3,
  > 620  => 2,
  _      => 1,
};
```

Same code renders as a single-column list on a phone and a 4-column grid on a desktop. No `MediaQuery` checks scattered through the codebase, no separate widget trees, no `if (isMobile) …`. Screenshots in the top-level README show both.
