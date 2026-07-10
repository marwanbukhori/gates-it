# Pawmise — Phase 1: Backend Foundation & API Contract

**Author:** Marwan Bukhori · **Date:** 2026-07-10
**Location:** `02-showcase/laravel` (evolved in place; `01-answers/` untouched)
**Parent:** [Pawmise Roadmap](./2026-07-10-pawmise-roadmap.md)

## Goal

Grow the existing stateless discount calculator into the backend of a real
product: persistent pets, user accounts with auth, an adoption flow, and the
**existing discount engine composed as the adoption-fee calculator** — all with
a documented API contract and full test coverage.

## Non-goals (Phase 1)

- No Flutter changes (Phase 2).
- No admin UI (Phase 3).
- No deployment (Phase 4).
- No rewrite of `Domain/Discount` — it is **composed, not modified**.

## Starting point (already present)

`02-showcase/laravel` has a clean discount engine:

- `Domain/Discount/DiscountService.php`, `DiscountStrategyFactory.php`
- Strategies: `FixedDiscount`, `PercentageDiscount`, `LoyaltyDiscount`
- `Enums/DiscountStrategyType`, `Exceptions/InvalidDiscountException`
- Stateless endpoint `POST /api/v1/discount` + feature/unit tests, CI, Docker.

Laravel ^13.8, PHP ^8.3, currently no domain models beyond `User`.

## Section A — Domain & data

### Entities

**User** (extend existing)
- add `adoptions_count` (int, default 0) — drives loyalty tier.
- Sanctum-authenticatable.

**Pet**
- `id, name, species, breed, age_years, size (small|medium|large), gender,
  description, image_url, base_fee (decimal), status (available|pending|adopted),
  shelter_partner (bool), timestamps`
- `is_senior` — derived accessor (e.g. `age_years >= 8`).

**Adoption** (immutable record)
- `id, user_id, pet_id, base_fee, discount_type (nullable), discount_amount,
  final_fee, adopted_at, timestamps`
- Stores the computed fee breakdown so every adoption is auditable.

### Database

- **Postgres** (production-like; matches Phase 4 Railway). Local via the existing
  `docker/` compose setup.
- Migrations for `pets`, `adoptions`, and the `users.adoptions_count` column.
- **Factories** for `Pet` and `Adoption`.
- **Seeder**: ~24 realistic pets (varied species/size/age, some senior, some
  shelter-partner) with real photo URLs.

## Section B — Discount engine → adoption-fee engine

The existing strategies map onto adoption fees with **no rewrite**:

| Existing strategy | Adoption-fee meaning | Trigger |
|---|---|---|
| `LoyaltyDiscount` | Reward repeat adopters | `user.adoptions_count >= N` |
| `PercentageDiscount` | Encourage senior adoption | `pet.is_senior` |
| `FixedDiscount` | Shelter-partner fee waiver | `pet.shelter_partner` |

New class **`Domain/Adoption/AdoptionFeeCalculator`**:

- Input: a `Pet` and the acting `User`.
- Determines which strategies apply for that (pet, user).
- Applies the **single best discount** (maximum saving). Chosen because it is
  transparent and trivially testable; the selection rule is centralized in one
  method so it can be swapped for stacking later.
- Output: a value object / breakdown `{ base_fee, discount_type,
  discount_amount, final_fee }`.
- Delegates the actual arithmetic to the existing `Domain/Discount` strategies —
  it orchestrates, it does not reimplement.

Fee thresholds/rates (loyalty N, senior %, waiver amount) live in a config file
(`config/pawmise.php`) so they are not magic numbers.

## Section C — API surface (`/api/v1`)

All error responses use **RFC 7807 problem+json** (existing pattern).

### Public

- `POST /auth/register` → creates user, returns Sanctum token.
- `POST /auth/login` → returns Sanctum token.
- `GET /pets` → list adoptable pets. Filters: `species`, `size`, `status`,
  `senior` (bool), `q` (name search). Paginated. Returns `PetResource`.
- `GET /pets/{id}` → single pet.
- `POST /discount` → **legacy** stateless endpoint, retained unchanged (the
  literal assessment endpoint; proves the pure engine still stands).

### Protected (Sanctum bearer token)

- `GET /me` → current user + `adoptions_count`.
- `GET /pets/{id}/fee-quote` → fee preview for this pet *for the acting user*
  (loyalty reflected), returns the fee breakdown. No side effects.
- `POST /pets/{id}/adopt` → **transaction**: guard pet is `available`, compute
  fee via `AdoptionFeeCalculator`, create `Adoption`, set pet `adopted`,
  increment `user.adoptions_count`. Returns the adoption record. Concurrent
  double-adopt is rejected (row lock / status guard → 409).
- `GET /me/adoptions` → the user's adoption history with fee breakdowns.

### Resources

`PetResource`, `AdoptionResource`, `FeeBreakdownResource`, `UserResource` —
keep the existing `DiscountedPriceResource` for the legacy endpoint.

## Section D — Testing & tooling

**Unit**
- `AdoptionFeeCalculator`: each discount path (loyalty / senior / waiver), the
  "best discount wins" selection, and the no-discount baseline.
- Existing discount strategy tests remain green (regression guard).

**Feature**
- Auth: register, login, protected route without token → 401.
- `GET /pets` filters + pagination.
- `fee-quote` reflects loyalty for a repeat adopter.
- `adopt` happy path (record created, pet flipped, count incremented) and
  guards (already adopted → 409, unauthenticated → 401).
- Legacy `/discount` still passes.

**Tooling**
- Updated **OpenAPI 3.1** spec covering all endpoints.
- Updated **Postman collection**.
- Extend existing **GitHub Actions** CI to run against Postgres.

## Acceptance criteria

- [ ] `composer test` green; new tests cover every endpoint + every fee path.
- [ ] Fresh clone → `docker compose up` + migrate + seed → `GET /pets` returns
      seeded pets.
- [ ] A registered user can quote a fee, adopt a pet, and see it in their
      history; the pet then reads `adopted`; a second adopt attempt returns 409.
- [ ] Loyalty discount visibly changes a repeat adopter's fee.
- [ ] `Domain/Discount` source is unchanged from its current state.
- [ ] OpenAPI spec validates and matches the implemented routes.

## Open decisions (resolved)

- **Best single discount wins** (not stacking) — approved.
- **Legacy `/discount` endpoint retained** — approved.
