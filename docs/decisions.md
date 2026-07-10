# Design decisions

Every decision I made that wasn't just "follow the framework's defaults". Presented ADR-style — context first, decision second, trade-offs last.

Numbering doesn't reflect priority; it's just for cross-referencing.

---

## 1. Two folders instead of one

**Context.** The assessment asks for classes to exist. My value as an engineer isn't proving I can write those classes — it's showing what I do *after* they exist. But I also can't dump a 500-file codebase on an evaluator and expect them to find the rubric answers.

**Decision.** Ship two versions of the same problem side-by-side. `01-answers/` is a minimal, rubric-focused answer that grades in five minutes. `02-showcase/` is production-grade — architecture, testing, ops, polish. The evaluator can grade the rubric quickly, then optionally look at the depth.

**Trade-offs.** More total code to maintain. Some duplication. But two small folders that each do one job well beat one folder that tries to be both a fast grade and a portfolio piece.

---

## 2. `01-answers/` uses `instanceof` in the service; `02-showcase/` doesn't

**Context.** The rubric says the service must validate: percentages 0–100, fixed amounts ≤ price. The obvious way is `if ($strategy instanceof PercentageDiscount) { … }` inside `DiscountService`.

**Decision.**

- `01-answers/`: use `instanceof`. It's the direct, honest answer to what the rubric asks.
- `02-showcase/`: each strategy owns its own `assertApplicableTo(float $price)` method. `DiscountService` just calls it.

**Trade-offs.** The `instanceof` version is one class fewer and easier to read at a glance. The `assertApplicableTo` version scales — adding a `SeasonalDiscount` doesn't touch `DiscountService`. For a three-strategy system, the difference is stylistic. For a growing product, it's the difference between "extend by adding" and "extend by editing".

I wanted the diff between the two folders to be obvious, so I picked this deliberately as one of the visible upgrades.

---

## 3. Custom `InvalidDiscountException` + `render()` instead of `BadRequestHttpException`

**Context.** The rubric says throw an HTTP 400. `symfony/http-kernel`'s `BadRequestHttpException` does exactly that.

**Decision.**

- `01-answers/`: throw `BadRequestHttpException`. Meets the rubric.
- `02-showcase/`: define `InvalidDiscountException` with `field` and `value` properties and a `render()` method that returns an [RFC 7807](https://datatracker.ietf.org/doc/html/rfc7807) `application/problem+json` response.

**Trade-offs.** More code. But two real wins:

1. **Structured error metadata.** The response body carries `field`, `title`, `detail`, plus a per-field `errors` map — matching Laravel's own validation error shape. Frontend clients don't need to parse strings.
2. **Distinct content type.** `application/problem+json` for business errors, `application/json` for shape errors (`422`). Consumers can dispatch on `Content-Type` instead of guessing from status codes.

Junior devs often skip this because "an exception is an exception". Senior devs treat exception design as API design.

---

## 4. Form Request instead of inline `$request->validate()`

**Context.** Laravel controllers can call `$request->validate([...])` inline. It's shorter.

**Decision.** Extract `ApplyDiscountRequest` as a `FormRequest` subclass with typed accessor methods (`strategy(): DiscountStrategyType`, `price(): float`, `value(): ?float`).

**Trade-offs.** One extra class. But:

- The controller stops doing two jobs (validate + dispatch) and starts doing one (dispatch).
- Cross-field validation (`if strategy = percentage but value is null → 422`) has a natural home via `withValidator()`.
- Type-safe accessors mean the controller never touches `$request->input(...)` — no stringly-typed access.

---

## 5. `Rule::enum(DiscountStrategyType::class)` instead of `in:fixed,percentage,loyalty`

**Context.** Both work.

**Decision.** Use the enum. Adding a new strategy means adding an enum case, not editing a comma-separated string in a validation rule. The rule stays honest as the enum evolves.

**Trade-offs.** Requires PHP 8.1+ enums, which Laravel 11+ already assumes. No downside for this codebase.

---

## 6. `DiscountStrategyFactory` bound as a container singleton

**Context.** The controller could build strategies via a `match` expression directly. That was the `01-answers/` approach.

**Decision.** Extract a factory, register it as a singleton in `DiscountServiceProvider`.

**Trade-offs.** More indirection. But:

- Testing the factory in isolation gives cleaner unit tests than testing the controller.
- Future strategies that need injected dependencies (`SeasonalDiscount(HolidayCalendar $calendar)`) can be built by the factory without the controller knowing.
- The container binding gives us a swap point for tests: `$this->app->instance(DiscountStrategyFactory::class, $spyFactory)`.

---

## 7. API versioned from day one — `/api/v1/`

**Context.** The endpoint could sit at `/api/discount`.

**Decision.** Route prefix is `/api/v1/discount`.

**Trade-offs.** One extra path segment now. Cheap to add. Very expensive to add later — introducing versioning after clients already exist breaks every one of them.

---

## 8. Riverpod (not Bloc, not Provider, not ChangeNotifier)

**Context.** Flutter has half a dozen viable state solutions.

**Decision.** Riverpod 3 with `AsyncNotifier` for the pet list and `Notifier` for the filter.

**Rationale.**

- **No `BuildContext` dependency for reads.** `ref.read(...)` works anywhere. Testing state without pumping widgets is trivial.
- **Compile-time-checked provider overrides.** `ProviderScope(overrides: [petRepositoryProvider.overrideWithValue(fakeRepo)])` is how the tests swap the data layer — no mocking framework needed.
- **`AsyncNotifier`** models the "loading → data | error" lifecycle out of the box. The screen calls `.when(...)` and gets exhaustive handling.

**Trade-offs.** Extra dependency. Learning curve if the team hasn't seen it. But Riverpod is where the community has landed for medium-to-large Flutter apps in 2025+.

---

## 9. `PetRepository` as an `abstract interface class`

**Context.** Dart lets me use a bare class as an interface. The `abstract interface class` keyword is Dart 3+.

**Decision.** Declare `PetRepository` explicitly as an interface. Concrete implementation lives in `data/`.

**Trade-offs.** Slightly more ceremony for a single-implementation type. But this is the extension point — swapping to an HTTP or SQLite backend is one override in one file. Making the abstraction explicit signals that.

---

## 10. Immutable `Pet` with per-subclass `copyWith`

**Context.** The `01-answers/` version has `bool isAdopted` mutable and calls `pet.adopt()` to flip it. Simple, works with `setState`.

**Decision.** In the showcase, `Pet` is `@immutable`. `Dog.copyWith(isAdopted: true)` returns a new `Dog` with the new state, preserving `isTrained` etc. Same for `Cat`.

**Rationale.**

- Riverpod's rebuild logic is equality-based. Immutable objects give correct signals without hand-crafted equality.
- The old pet reference still exists after adoption — useful for undo, animations, snapshots.
- Redux/time-travel debugging is free.

**Trade-offs.** Every subclass needs its own `copyWith`. Slightly more code than a mutable field. Worth it.

---

## 11. Species-specific `copyWith` signatures

**Context.** I could give `Pet` a single `copyWith({bool? isAdopted, bool? isTrained, bool? isIndoor})` where the irrelevant fields are ignored per subclass. Simple.

**Decision.** `Dog.copyWith({bool? isAdopted, bool? isTrained})`, `Cat.copyWith({bool? isAdopted, bool? isIndoor})`. Two different signatures.

**Trade-offs.** The abstract `Pet.copyWith` has to have a compatible signature (only `isAdopted`), which forces the state controller to pattern-match: `switch (pet) { Dog() => …, Cat() => … }`. That's more code — but it's compiler-checked exhaustive. Adding a third species is a compile error until every switch is updated. That's the point.

---

## 12. Seedless Material 3 palette

**Context.** `ColorScheme.fromSeed(seedColor: Colors.teal)` gives a serviceable Material 3 scheme in one line.

**Decision.** Hand-pick every color. Deep sage primary, clay-rose secondary, sunlit-gold tertiary, paper-cream background. Add species-specific card surface tints (`dogSurface` warm ochre, `catSurface` muted clay-rose).

**Rationale.** Every "seed-from-teal" M3 app looks like every other "seed-from-teal" M3 app. That's the aesthetic the assessment brief explicitly warned against. Hand-picked palettes take longer but produce a distinctive look. The two card surfaces also mean the dog and cat lists visually read differently at a glance — a functional payoff, not just decoration.

---

## 13. Fraunces + Plus Jakarta Sans typography

**Context.** Roboto (Android default) or SF Pro (iOS default) would work.

**Decision.** Fraunces for display / titles (has personality — pet-adoption context leans warm), Plus Jakarta Sans for body (clean, high x-height, neutral where it needs to be).

**Trade-offs.** Two font families loaded at runtime. Both are Google Fonts and served through the `google_fonts` package, so the cost is one HTTP fetch on first load, cached thereafter. Worth it for the brand feel.

---

## 14. `LayoutBuilder`-driven column count instead of `MediaQuery`

**Context.** I could read `MediaQuery.of(context).size.width` at the top of the tree and pass it down.

**Decision.** The grid widget wraps its child in `LayoutBuilder`. Column count comes from `constraints.maxWidth`.

**Rationale.**

- Works correctly inside side sheets, split views, and embedded contexts where `MediaQuery` reports the whole window (wrong for the inner region).
- Same code renders correctly whether the grid is 100% wide or 50% wide.
- No prop-drilling of layout information.

---

## 15. `AnimatedSwitcher` for the "adopt" transition

**Context.** Toggling `isAdopted` could just re-render the card with a different button.

**Decision.** Wrap the button/pill area in `AnimatedSwitcher` with a scale + fade transition (`Curves.easeOutBack` for a subtle overshoot).

**Trade-offs.** Slightly more code. But the user gets a satisfying "click, whoosh" feedback for what is otherwise a state change with no visual anchor. Adoption is the most important action in the app; investing in its microinteraction is right.

---

## 16. Staggered enter animation for the grid

**Context.** Grid items appear all at once when the async load completes.

**Decision.** Wrap each grid item in a `FadeTransition` + `SlideTransition` with a per-index delay of 60ms.

**Trade-offs.** Cost is one `AnimationController` per visible card. Cheap. The result is a "settling into place" motion that makes the initial load feel deliberate rather than abrupt.

---

## 17. Shimmer skeleton instead of a spinner

**Context.** `CircularProgressIndicator` is one line.

**Decision.** A skeleton grid that mirrors the real card layout, with an animated shimmer over each placeholder rect.

**Rationale.** Users perceive apps with skeleton loaders as faster than apps with spinners — the layout is already there when the data arrives, so there's no "layout jump". Table stakes for anything user-facing above a certain polish threshold.

---

## 18. Semantics labels on cards and filter chips

**Context.** Flutter widgets get some semantics by default (buttons announce as buttons, etc.).

**Decision.** Add explicit `Semantics(label: '${pet.name}, ${pet.age} year old ${pet.breed}, ${pet.species}')` on each card, and `Semantics(label: '${filter.label}, $count pets')` on each filter chip.

**Rationale.** VoiceOver / TalkBack users get a coherent read of the screen. The compound label ("Rex, 2 year old Labrador, Dog") replaces the fragmented default that would announce each subtitle piece separately.

**Trade-offs.** Zero cost, real accessibility payoff.

---

## 19. Docker Compose (nginx + php-fpm + mysql) as an alternative to `artisan serve`

**Context.** `php artisan serve` works fine for local dev.

**Decision.** Ship a `docker-compose.yml` alongside `artisan serve` support.

**Rationale.** In a real team, the composed stack matches what production runs — same PHP version, same nginx config, same MySQL flavor. New developers get a working local environment with `docker compose up`, no matter what's on their machine.

**Trade-offs.** More files (`Dockerfile`, `nginx/default.conf`, `docker-compose.yml`). Cost is one-time to write, ongoing to occasionally update PHP versions. Modest.

---

## 20. OpenAPI 3.1 + Postman collection

**Context.** The rubric doesn't ask for API documentation.

**Decision.** Ship `docs/openapi.yaml` and `docs/postman_collection.json`.

**Rationale.** For any API a team is going to consume, docs aren't optional — they're the contract. OpenAPI is the industry-standard machine-readable format; Postman is what most frontend and QA engineers use interactively. Both are cheap to produce alongside the implementation and worth their weight in reduced Slack messages.

---

## 21. GitHub Actions CI

**Context.** Tests pass locally.

**Decision.** Add `.github/workflows/ci.yml` that runs the PHPUnit suite on every push.

**Rationale.** The gap between "tests pass on my machine" and "tests pass on a fresh checkout" catches missing dependencies, environment assumptions, and forgotten migrations. CI closes that gap on day one.

---

## Things I *didn't* do

Not everything is a mystery. A few things I deliberately left out:

- **No frontend for the Laravel discount API.** The rubric is backend-only. Building a React form would obscure what's actually being graded.
- **No pet detail screen in Flutter.** The brief describes a list with filtering and adoption. Adding a detail sheet would be scope creep.
- **No authentication.** Both APIs run open. Adding auth would be a whole other story and isn't in scope.
- **No i18n / dark mode / animations for the Flutter answers folder.** Kept it deliberately minimal so the diff between "answers" and "showcase" is visible.
- **No CD (deploy pipeline).** CI covers testing. Deploy pipeline setup is org-specific — I'd want a real conversation about targets before wiring one up.

If the interview goes further, any of these can be added with context on your team's actual conventions.
