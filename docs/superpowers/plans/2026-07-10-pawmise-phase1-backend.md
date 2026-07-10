# Pawmise Phase 1 — Backend Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Grow the existing stateless discount calculator in `02-showcase/laravel` into the backend of a real pet-adoption product — persistent pets, Sanctum auth, an adoption flow, and the existing discount engine composed as the adoption-fee calculator — with a documented API contract and full test coverage.

**Architecture:** Keep the existing `Domain/Discount` strategy engine untouched and *compose* it behind a new `Domain/Adoption/AdoptionFeeCalculator`. Add Eloquent models (`Pet`, `Adoption`) and Sanctum-based auth. Expose a versioned `/api/v1` surface; the legacy `POST /api/v1/discount` endpoint stays exactly as-is. Errors use RFC 7807 `application/problem+json`, matching the existing `InvalidDiscountException::render()` pattern.

**Tech Stack:** Laravel ^13.8, PHP ^8.3, Laravel Sanctum (token auth), MySQL 8.4 (local/prod via existing `docker-compose`), SQLite in-memory (test suite via existing `phpunit.xml`), PHPUnit 12.

## Global Constraints

- All work happens in `02-showcase/laravel/`. **Never touch `01-answers/`.**
- **Do not modify** any file under `app/Domain/Discount/` — it is composed, not changed.
- The legacy route `POST /api/v1/discount` and its tests must remain green.
- `declare(strict_types=1);` at the top of every new PHP file.
- New classes are `final`; value objects and stateless services are `final readonly` where they hold no mutable state (match existing style).
- All API error responses use `Content-Type: application/problem+json` with keys `type, title, status, detail` (+ `errors` when field-level).
- Money is `decimal(8,2)`, currency `MYR`, rounded to 2 dp in output.
- Tests use PHPUnit attributes (`#[Test]`), not doc-comment annotations.
- Run a single test file with: `php artisan test --filter=ClassName` (from `02-showcase/laravel/`).
- Run the whole suite with: `composer test`.
- Tuneable business numbers live in `config/pawmise.php` — no magic numbers in domain code.

---

## Task 1: Config + install Sanctum

**Files:**
- Create: `02-showcase/laravel/config/pawmise.php`
- Modify: `02-showcase/laravel/composer.json` (adds `laravel/sanctum` via require)
- Modify: `02-showcase/laravel/app/Models/User.php`
- Create (published): `config/sanctum.php`, `database/migrations/*_create_personal_access_tokens_table.php`

**Interfaces:**
- Produces: `config('pawmise.currency')` → `'MYR'`; `config('pawmise.loyalty.threshold')` → int; `config('pawmise.loyalty.percentage')` → float; `config('pawmise.senior.age_years')` → int; `config('pawmise.senior.percentage')` → float; `config('pawmise.shelter_partner.waiver')` → float.
- Produces: `App\Models\User` uses `Laravel\Sanctum\HasApiTokens` (`$user->createToken(string $name): NewAccessToken`).

- [ ] **Step 1: Create the config file**

Create `config/pawmise.php`:

```php
<?php

declare(strict_types=1);

return [
    'currency' => 'MYR',

    // Repeat-adopter reward. Uses the existing LoyaltyDiscount strategy (15% off).
    'loyalty' => [
        'threshold'  => 3,     // prior completed adoptions required to qualify
        'percentage' => 15.0,  // documented for transparency; LoyaltyDiscount is fixed at 15%
    ],

    // Encourage senior-pet adoption.
    'senior' => [
        'age_years'  => 8,     // a pet is "senior" at or above this age
        'percentage' => 30.0,  // percent off the base adoption fee
    ],

    // Shelter-partner fee waiver (fixed amount off).
    'shelter_partner' => [
        'waiver' => 50.0,      // MYR off the base adoption fee
    ],
];
```

- [ ] **Step 2: Require Sanctum and publish its assets**

Run (from `02-showcase/laravel/`):

```bash
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
```

Expected: `config/sanctum.php` and a `*_create_personal_access_tokens_table.php` migration appear. If `composer require` reports a version conflict with Laravel ^13.8, run `composer require laravel/sanctum:^4.0` (or the latest tag Composer offers) and re-run the publish command.

- [ ] **Step 3: Add the HasApiTokens trait to User**

Modify `app/Models/User.php` — add the import and trait:

```php
use Laravel\Sanctum\HasApiTokens;
```

and change the `use` inside the class body from:

```php
    use HasFactory, Notifiable;
```

to:

```php
    use HasApiTokens, HasFactory, Notifiable;
```

- [ ] **Step 4: Verify the app still boots and existing tests pass**

Run: `composer test`
Expected: PASS — the existing 28 tests remain green (Sanctum's own migration only runs in tests that use `RefreshDatabase`).

- [ ] **Step 5: Commit**

```bash
git add 02-showcase/laravel
git commit -m "chore(pawmise): add pawmise config and install Sanctum"
```

---

## Task 2: Pet model, migration, factory, seeder

**Files:**
- Create: `02-showcase/laravel/app/Models/Pet.php`
- Create: `02-showcase/laravel/app/Enums/PetStatus.php`
- Create: `02-showcase/laravel/database/migrations/2026_07_10_000001_create_pets_table.php`
- Create: `02-showcase/laravel/database/factories/PetFactory.php`
- Modify: `02-showcase/laravel/database/seeders/DatabaseSeeder.php`
- Test: `02-showcase/laravel/tests/Unit/Pet/PetModelTest.php`

**Interfaces:**
- Produces: `App\Enums\PetStatus` (cases `Available='available'`, `Pending='pending'`, `Adopted='adopted'`).
- Produces: `App\Models\Pet` with columns `name, species, breed, age_years, size, gender, description, image_url, base_fee, status, shelter_partner`; casts `base_fee`→`float`(decimal:2), `status`→`PetStatus`, `shelter_partner`→`bool`, `age_years`→`int`; accessor `Pet::isSenior(): bool`; factory states `senior()`, `shelterPartner()`, `adopted()`.

- [ ] **Step 1: Write the failing test**

Create `tests/Unit/Pet/PetModelTest.php`:

```php
<?php

declare(strict_types=1);

namespace Tests\Unit\Pet;

use App\Enums\PetStatus;
use App\Models\Pet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

final class PetModelTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_marks_a_pet_at_or_above_the_senior_age_as_senior(): void
    {
        config()->set('pawmise.senior.age_years', 8);

        $senior = Pet::factory()->create(['age_years' => 9]);
        $young  = Pet::factory()->create(['age_years' => 2]);

        $this->assertTrue($senior->is_senior);
        $this->assertFalse($young->is_senior);
    }

    #[Test]
    public function it_casts_status_to_the_enum(): void
    {
        $pet = Pet::factory()->create(['status' => 'available']);

        $this->assertSame(PetStatus::Available, $pet->status);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test --filter=PetModelTest`
Expected: FAIL — `Class "App\Models\Pet" not found`.

- [ ] **Step 3: Create the PetStatus enum**

Create `app/Enums/PetStatus.php`:

```php
<?php

declare(strict_types=1);

namespace App\Enums;

enum PetStatus: string
{
    case Available = 'available';
    case Pending   = 'pending';
    case Adopted   = 'adopted';
}
```

- [ ] **Step 4: Create the migration**

Create `database/migrations/2026_07_10_000001_create_pets_table.php`:

```php
<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pets', function (Blueprint $table): void {
            $table->id();
            $table->string('name');
            $table->string('species');
            $table->string('breed')->nullable();
            $table->unsignedSmallInteger('age_years');
            $table->string('size');   // small | medium | large
            $table->string('gender'); // male | female
            $table->text('description')->nullable();
            $table->string('image_url')->nullable();
            $table->decimal('base_fee', 8, 2);
            $table->string('status')->default('available');
            $table->boolean('shelter_partner')->default(false);
            $table->timestamps();

            $table->index(['status', 'species', 'size']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pets');
    }
};
```

- [ ] **Step 5: Create the Pet model**

Create `app/Models/Pet.php`:

```php
<?php

declare(strict_types=1);

namespace App\Models;

use App\Enums\PetStatus;
use Database\Factories\PetFactory;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

final class Pet extends Model
{
    /** @use HasFactory<PetFactory> */
    use HasFactory;

    protected $fillable = [
        'name', 'species', 'breed', 'age_years', 'size', 'gender',
        'description', 'image_url', 'base_fee', 'status', 'shelter_partner',
    ];

    protected function casts(): array
    {
        return [
            'age_years'       => 'integer',
            'base_fee'        => 'decimal:2',
            'status'          => PetStatus::class,
            'shelter_partner' => 'boolean',
        ];
    }

    protected function isSenior(): Attribute
    {
        return Attribute::get(
            fn (): bool => $this->age_years >= (int) config('pawmise.senior.age_years'),
        );
    }
}
```

Note: `decimal:2` casts return numeric strings; `AdoptionFeeCalculator` (Task 4) casts to `float` before arithmetic.

- [ ] **Step 6: Create the factory**

Create `database/factories/PetFactory.php`:

```php
<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Enums\PetStatus;
use App\Models\Pet;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Pet>
 */
final class PetFactory extends Factory
{
    protected $model = Pet::class;

    public function definition(): array
    {
        return [
            'name'            => fake()->firstName(),
            'species'         => fake()->randomElement(['dog', 'cat', 'rabbit']),
            'breed'           => fake()->word(),
            'age_years'       => fake()->numberBetween(1, 7),
            'size'            => fake()->randomElement(['small', 'medium', 'large']),
            'gender'          => fake()->randomElement(['male', 'female']),
            'description'     => fake()->sentence(12),
            'image_url'       => 'https://placedog.net/500/280?id=' . fake()->numberBetween(1, 200),
            'base_fee'        => fake()->randomFloat(2, 60, 400),
            'status'          => PetStatus::Available->value,
            'shelter_partner' => false,
        ];
    }

    public function senior(): static
    {
        return $this->state(fn (): array => ['age_years' => fake()->numberBetween(8, 15)]);
    }

    public function shelterPartner(): static
    {
        return $this->state(fn (): array => ['shelter_partner' => true]);
    }

    public function adopted(): static
    {
        return $this->state(fn (): array => ['status' => PetStatus::Adopted->value]);
    }
}
```

- [ ] **Step 7: Run the test to verify it passes**

Run: `php artisan test --filter=PetModelTest`
Expected: PASS (2 tests).

- [ ] **Step 8: Seed realistic pets**

Replace the body of `database/seeders/DatabaseSeeder.php`'s `run()` with:

```php
    public function run(): void
    {
        User::factory()->create([
            'name'  => 'Demo Adopter',
            'email' => 'demo@pawmise.test',
        ]);

        Pet::factory()->count(16)->create();
        Pet::factory()->count(4)->senior()->create();
        Pet::factory()->count(2)->shelterPartner()->create();
        Pet::factory()->count(2)->senior()->shelterPartner()->create();
    }
```

Add the import at the top of the file:

```php
use App\Models\Pet;
```

- [ ] **Step 9: Commit**

```bash
git add 02-showcase/laravel
git commit -m "feat(pawmise): add Pet model, migration, factory, and seeder"
```

---

## Task 3: Adoption model + users.adoptions_count

**Files:**
- Create: `02-showcase/laravel/app/Models/Adoption.php`
- Create: `02-showcase/laravel/database/migrations/2026_07_10_000002_create_adoptions_table.php`
- Create: `02-showcase/laravel/database/migrations/2026_07_10_000003_add_adoptions_count_to_users_table.php`
- Create: `02-showcase/laravel/database/factories/AdoptionFactory.php`
- Modify: `02-showcase/laravel/app/Models/User.php`
- Test: `02-showcase/laravel/tests/Unit/Adoption/AdoptionModelTest.php`

**Interfaces:**
- Produces: `App\Models\Adoption` with `user_id, pet_id, base_fee, discount_type, discount_amount, final_fee, adopted_at`; relations `user()`, `pet()`; casts `base_fee/discount_amount/final_fee`→`decimal:2`, `adopted_at`→`datetime`.
- Produces: `App\Models\User` gains `adoptions_count` (int, default 0) and relation `adoptions(): HasMany`.

- [ ] **Step 1: Write the failing test**

Create `tests/Unit/Adoption/AdoptionModelTest.php`:

```php
<?php

declare(strict_types=1);

namespace Tests\Unit\Adoption;

use App\Models\Adoption;
use App\Models\Pet;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

final class AdoptionModelTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_belongs_to_a_user_and_a_pet(): void
    {
        $user = User::factory()->create();
        $pet  = Pet::factory()->create();

        $adoption = Adoption::factory()->create([
            'user_id' => $user->id,
            'pet_id'  => $pet->id,
        ]);

        $this->assertTrue($adoption->user->is($user));
        $this->assertTrue($adoption->pet->is($pet));
    }

    #[Test]
    public function a_user_starts_with_zero_adoptions_count(): void
    {
        $this->assertSame(0, User::factory()->create()->adoptions_count);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test --filter=AdoptionModelTest`
Expected: FAIL — `Class "App\Models\Adoption" not found`.

- [ ] **Step 3: Create the adoptions migration**

Create `database/migrations/2026_07_10_000002_create_adoptions_table.php`:

```php
<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('adoptions', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('pet_id')->constrained()->cascadeOnDelete();
            $table->decimal('base_fee', 8, 2);
            $table->string('discount_type')->nullable();
            $table->decimal('discount_amount', 8, 2)->default(0);
            $table->decimal('final_fee', 8, 2);
            $table->timestamp('adopted_at');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('adoptions');
    }
};
```

- [ ] **Step 4: Create the users.adoptions_count migration**

Create `database/migrations/2026_07_10_000003_add_adoptions_count_to_users_table.php`:

```php
<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            $table->unsignedInteger('adoptions_count')->default(0)->after('email');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            $table->dropColumn('adoptions_count');
        });
    }
};
```

- [ ] **Step 5: Create the Adoption model**

Create `app/Models/Adoption.php`:

```php
<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\AdoptionFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

final class Adoption extends Model
{
    /** @use HasFactory<AdoptionFactory> */
    use HasFactory;

    protected $fillable = [
        'user_id', 'pet_id', 'base_fee', 'discount_type',
        'discount_amount', 'final_fee', 'adopted_at',
    ];

    protected function casts(): array
    {
        return [
            'base_fee'        => 'decimal:2',
            'discount_amount' => 'decimal:2',
            'final_fee'       => 'decimal:2',
            'adopted_at'      => 'datetime',
        ];
    }

    /** @return BelongsTo<User, $this> */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /** @return BelongsTo<Pet, $this> */
    public function pet(): BelongsTo
    {
        return $this->belongsTo(Pet::class);
    }
}
```

- [ ] **Step 6: Create the Adoption factory**

Create `database/factories/AdoptionFactory.php`:

```php
<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\Adoption;
use App\Models\Pet;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Adoption>
 */
final class AdoptionFactory extends Factory
{
    protected $model = Adoption::class;

    public function definition(): array
    {
        $base = fake()->randomFloat(2, 60, 400);

        return [
            'user_id'         => User::factory(),
            'pet_id'          => Pet::factory(),
            'base_fee'        => $base,
            'discount_type'   => null,
            'discount_amount' => 0,
            'final_fee'       => $base,
            'adopted_at'      => now(),
        ];
    }
}
```

- [ ] **Step 7: Add adoptions relation + cast to User**

Modify `app/Models/User.php`. Add imports:

```php
use App\Models\Adoption;
use Illuminate\Database\Eloquent\Relations\HasMany;
```

Add `adoptions_count` to the casts array in `casts()`:

```php
            'adoptions_count' => 'integer',
```

Add the relation method inside the class:

```php
    /** @return HasMany<Adoption, $this> */
    public function adoptions(): HasMany
    {
        return $this->hasMany(Adoption::class);
    }
```

- [ ] **Step 8: Run the test to verify it passes**

Run: `php artisan test --filter=AdoptionModelTest`
Expected: PASS (2 tests).

- [ ] **Step 9: Commit**

```bash
git add 02-showcase/laravel
git commit -m "feat(pawmise): add Adoption model and users.adoptions_count"
```

---

## Task 4: AdoptionFeeCalculator (composes the discount engine)

**Files:**
- Create: `02-showcase/laravel/app/Domain/Adoption/FeeDiscount.php`
- Create: `02-showcase/laravel/app/Domain/Adoption/FeeBreakdown.php`
- Create: `02-showcase/laravel/app/Domain/Adoption/AdoptionFeeCalculator.php`
- Test: `02-showcase/laravel/tests/Unit/Adoption/AdoptionFeeCalculatorTest.php`

**Design note (why not the `LoyaltyDiscount` strategy):** the existing `LoyaltyDiscount` strategy computes `price - 0.85*price` — i.e. **85% off** — despite its label reading "15% off". That mislabel/behaviour mismatch makes it unsafe to build on. The adoption-fee engine therefore models discounts by **product-semantic reason** (`FeeDiscount`), each backed by a clean, correct engine strategy: Loyalty → `PercentageDiscount(loyalty.percentage)`, Senior → `PercentageDiscount(senior.percentage)`, Shelter waiver → `FixedDiscount(waiver)`. This composes the engine, keeps `discount_type` semantically distinct, and avoids the buggy strategy. (The legacy `/discount` endpoint still exercises all three original strategies, so nothing is lost from the assessment.)

**Interfaces:**
- Consumes: `App\Domain\Discount\DiscountStrategyFactory::make(DiscountStrategyType $type, ?float $value): DiscountStrategyInterface`; `App\Domain\Discount\DiscountService::applyDiscount(float $price): float`; `App\Domain\Discount\Enums\DiscountStrategyType`; `App\Domain\Discount\Exceptions\InvalidDiscountException`; `App\Models\Pet` (`base_fee`, `is_senior`, `shelter_partner`); `App\Models\User` (`adoptions_count`).
- Produces: `App\Domain\Adoption\FeeDiscount` enum (cases `Loyalty='loyalty'`, `Senior='senior'`, `ShelterPartner='shelter_partner'`).
- Produces: `App\Domain\Adoption\FeeBreakdown` (readonly: `float $baseFee`, `?FeeDiscount $discountType`, `float $discountAmount`, `float $finalFee`).
- Produces: `AdoptionFeeCalculator::quote(Pet $pet, User $user): FeeBreakdown` — returns the single best (max-saving) applicable discount, or a zero-discount breakdown when none apply.

- [ ] **Step 1: Write the failing test**

Create `tests/Unit/Adoption/AdoptionFeeCalculatorTest.php`:

```php
<?php

declare(strict_types=1);

namespace Tests\Unit\Adoption;

use App\Domain\Adoption\AdoptionFeeCalculator;
use App\Domain\Adoption\FeeDiscount;
use App\Domain\Discount\DiscountStrategyFactory;
use App\Models\Pet;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

final class AdoptionFeeCalculatorTest extends TestCase
{
    use RefreshDatabase;

    private function calculator(): AdoptionFeeCalculator
    {
        return new AdoptionFeeCalculator(new DiscountStrategyFactory());
    }

    protected function setUp(): void
    {
        parent::setUp();

        config()->set('pawmise.loyalty.threshold', 3);
        config()->set('pawmise.loyalty.percentage', 15.0);
        config()->set('pawmise.senior.age_years', 8);
        config()->set('pawmise.senior.percentage', 30.0);
        config()->set('pawmise.shelter_partner.waiver', 50.0);
    }

    #[Test]
    public function no_discount_applies_to_a_young_non_partner_pet_for_a_new_user(): void
    {
        $pet  = Pet::factory()->make(['base_fee' => 200, 'age_years' => 2, 'shelter_partner' => false]);
        $user = User::factory()->make(['adoptions_count' => 0]);

        $breakdown = $this->calculator()->quote($pet, $user);

        $this->assertNull($breakdown->discountType);
        $this->assertSame(200.0, $breakdown->finalFee);
        $this->assertSame(0.0, $breakdown->discountAmount);
    }

    #[Test]
    public function loyalty_discount_applies_to_a_repeat_adopter(): void
    {
        $pet  = Pet::factory()->make(['base_fee' => 200, 'age_years' => 2, 'shelter_partner' => false]);
        $user = User::factory()->make(['adoptions_count' => 3]);

        $breakdown = $this->calculator()->quote($pet, $user);

        $this->assertSame(FeeDiscount::Loyalty, $breakdown->discountType);
        $this->assertSame(170.0, $breakdown->finalFee); // 15% off 200
    }

    #[Test]
    public function senior_percentage_beats_loyalty_when_it_saves_more(): void
    {
        // Senior 30% off (=> 140) beats loyalty 15% off (=> 170) on a 200 base.
        $pet  = Pet::factory()->make(['base_fee' => 200, 'age_years' => 10, 'shelter_partner' => false]);
        $user = User::factory()->make(['adoptions_count' => 5]);

        $breakdown = $this->calculator()->quote($pet, $user);

        $this->assertSame(FeeDiscount::Senior, $breakdown->discountType);
        $this->assertSame(140.0, $breakdown->finalFee);
        $this->assertSame(60.0, $breakdown->discountAmount);
    }

    #[Test]
    public function shelter_partner_waiver_applies_as_a_fixed_amount(): void
    {
        $pet  = Pet::factory()->make(['base_fee' => 120, 'age_years' => 2, 'shelter_partner' => true]);
        $user = User::factory()->make(['adoptions_count' => 0]);

        $breakdown = $this->calculator()->quote($pet, $user);

        $this->assertSame(FeeDiscount::ShelterPartner, $breakdown->discountType);
        $this->assertSame(70.0, $breakdown->finalFee); // 120 - 50
    }

    #[Test]
    public function a_waiver_larger_than_the_fee_is_skipped_not_applied(): void
    {
        // Waiver 50 exceeds a 40 fee => that candidate is invalid and skipped; no discount.
        $pet  = Pet::factory()->make(['base_fee' => 40, 'age_years' => 2, 'shelter_partner' => true]);
        $user = User::factory()->make(['adoptions_count' => 0]);

        $breakdown = $this->calculator()->quote($pet, $user);

        $this->assertNull($breakdown->discountType);
        $this->assertSame(40.0, $breakdown->finalFee);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test --filter=AdoptionFeeCalculatorTest`
Expected: FAIL — `Class "App\Domain\Adoption\AdoptionFeeCalculator" not found`.

- [ ] **Step 3: Create the FeeDiscount enum**

Create `app/Domain/Adoption/FeeDiscount.php`:

```php
<?php

declare(strict_types=1);

namespace App\Domain\Adoption;

/**
 * Product-level reason an adoption fee was discounted. Distinct from the
 * engine's DiscountStrategyType so the fee breakdown speaks the product's
 * language, not the implementation's.
 */
enum FeeDiscount: string
{
    case Loyalty        = 'loyalty';
    case Senior         = 'senior';
    case ShelterPartner = 'shelter_partner';

    public function label(): string
    {
        return match ($this) {
            self::Loyalty        => 'Loyalty reward',
            self::Senior         => 'Senior pet',
            self::ShelterPartner => 'Shelter partner waiver',
        };
    }
}
```

- [ ] **Step 4: Create the FeeBreakdown value object**

Create `app/Domain/Adoption/FeeBreakdown.php`:

```php
<?php

declare(strict_types=1);

namespace App\Domain\Adoption;

final readonly class FeeBreakdown
{
    public function __construct(
        public float $baseFee,
        public ?FeeDiscount $discountType,
        public float $discountAmount,
        public float $finalFee,
    ) {
    }

    public static function none(float $baseFee): self
    {
        return new self($baseFee, null, 0.0, $baseFee);
    }
}
```

- [ ] **Step 5: Create the calculator**

Create `app/Domain/Adoption/AdoptionFeeCalculator.php`:

```php
<?php

declare(strict_types=1);

namespace App\Domain\Adoption;

use App\Domain\Discount\Contracts\DiscountStrategyInterface;
use App\Domain\Discount\DiscountService;
use App\Domain\Discount\DiscountStrategyFactory;
use App\Domain\Discount\Enums\DiscountStrategyType;
use App\Domain\Discount\Exceptions\InvalidDiscountException;
use App\Models\Pet;
use App\Models\User;

final readonly class AdoptionFeeCalculator
{
    public function __construct(private DiscountStrategyFactory $factory)
    {
    }

    public function quote(Pet $pet, User $user): FeeBreakdown
    {
        $baseFee = (float) $pet->base_fee;

        $bestReason = null;
        $bestFinal  = $baseFee;

        foreach ($this->candidatesFor($pet, $user) as $reason => $strategy) {
            try {
                $final = (new DiscountService($strategy))->applyDiscount($baseFee);
            } catch (InvalidDiscountException) {
                continue; // strategy not applicable to this fee (e.g. waiver > fee)
            }

            if ($final < $bestFinal) {
                $bestFinal  = $final;
                $bestReason = FeeDiscount::from($reason);
            }
        }

        if ($bestReason === null) {
            return FeeBreakdown::none($baseFee);
        }

        return new FeeBreakdown(
            baseFee: $baseFee,
            discountType: $bestReason,
            discountAmount: round($baseFee - $bestFinal, 2),
            finalFee: round($bestFinal, 2),
        );
    }

    /**
     * Map each applicable product reason to a clean engine strategy.
     *
     * @return array<string, DiscountStrategyInterface> keyed by FeeDiscount value
     */
    private function candidatesFor(Pet $pet, User $user): array
    {
        $candidates = [];

        if ($user->adoptions_count >= (int) config('pawmise.loyalty.threshold')) {
            $candidates[FeeDiscount::Loyalty->value] = $this->factory->make(
                DiscountStrategyType::Percentage,
                (float) config('pawmise.loyalty.percentage'),
            );
        }

        if ($pet->is_senior) {
            $candidates[FeeDiscount::Senior->value] = $this->factory->make(
                DiscountStrategyType::Percentage,
                (float) config('pawmise.senior.percentage'),
            );
        }

        if ($pet->shelter_partner) {
            $candidates[FeeDiscount::ShelterPartner->value] = $this->factory->make(
                DiscountStrategyType::Fixed,
                (float) config('pawmise.shelter_partner.waiver'),
            );
        }

        return $candidates;
    }
}
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `php artisan test --filter=AdoptionFeeCalculatorTest`
Expected: PASS (5 tests).

- [ ] **Step 7: Commit**

```bash
git add 02-showcase/laravel
git commit -m "feat(pawmise): add AdoptionFeeCalculator composing the discount engine"
```

---

## Task 5: Auth endpoints (register, login, me)

**Files:**
- Create: `02-showcase/laravel/app/Http/Controllers/Api/AuthController.php`
- Create: `02-showcase/laravel/app/Http/Requests/RegisterRequest.php`
- Create: `02-showcase/laravel/app/Http/Requests/LoginRequest.php`
- Create: `02-showcase/laravel/app/Http/Resources/UserResource.php`
- Modify: `02-showcase/laravel/routes/api.php`
- Test: `02-showcase/laravel/tests/Feature/Api/AuthEndpointTest.php`

**Interfaces:**
- Consumes: `App\Models\User` (`HasApiTokens::createToken`).
- Produces: routes `POST /api/v1/auth/register`, `POST /api/v1/auth/login`, `GET /api/v1/me` (named `api.v1.auth.register`, `api.v1.auth.login`, `api.v1.me`).
- Produces: register/login responses `{ token: string, user: {...UserResource} }`; `UserResource` → `{ id, name, email, adoptions_count }`.

- [ ] **Step 1: Write the failing test**

Create `tests/Feature/Api/AuthEndpointTest.php`:

```php
<?php

declare(strict_types=1);

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

final class AuthEndpointTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_registers_a_user_and_returns_a_token(): void
    {
        $this->postJson('/api/v1/auth/register', [
            'name'     => 'Ada Lovelace',
            'email'    => 'ada@pawmise.test',
            'password' => 'secret1234',
        ])
            ->assertCreated()
            ->assertJsonStructure(['token', 'user' => ['id', 'name', 'email', 'adoptions_count']])
            ->assertJsonPath('user.email', 'ada@pawmise.test');
    }

    #[Test]
    public function it_logs_in_with_valid_credentials(): void
    {
        User::factory()->create([
            'email'    => 'grace@pawmise.test',
            'password' => Hash::make('secret1234'),
        ]);

        $this->postJson('/api/v1/auth/login', [
            'email'    => 'grace@pawmise.test',
            'password' => 'secret1234',
        ])
            ->assertOk()
            ->assertJsonStructure(['token', 'user']);
    }

    #[Test]
    public function it_rejects_bad_credentials_with_422(): void
    {
        User::factory()->create(['email' => 'grace@pawmise.test', 'password' => Hash::make('secret1234')]);

        $this->postJson('/api/v1/auth/login', [
            'email'    => 'grace@pawmise.test',
            'password' => 'wrong-password',
        ])->assertStatus(422)->assertJsonValidationErrors(['email']);
    }

    #[Test]
    public function me_requires_authentication(): void
    {
        $this->getJson('/api/v1/me')->assertUnauthorized();
    }

    #[Test]
    public function me_returns_the_authenticated_user(): void
    {
        $user = User::factory()->create(['adoptions_count' => 2]);

        $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/me')
            ->assertOk()
            ->assertJsonPath('data.adoptions_count', 2)
            ->assertJsonPath('data.id', $user->id);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test --filter=AuthEndpointTest`
Expected: FAIL — 404/route not defined for `/api/v1/auth/register`.

- [ ] **Step 3: Create UserResource**

Create `app/Http/Resources/UserResource.php`:

```php
<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin User
 */
final class UserResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id'              => $this->id,
            'name'            => $this->name,
            'email'           => $this->email,
            'adoptions_count' => $this->adoptions_count,
        ];
    }
}
```

- [ ] **Step 4: Create the request classes**

Create `app/Http/Requests/RegisterRequest.php`:

```php
<?php

declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

final class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'name'     => ['required', 'string', 'max:255'],
            'email'    => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
        ];
    }
}
```

Create `app/Http/Requests/LoginRequest.php`:

```php
<?php

declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

final class LoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'email'    => ['required', 'email'],
            'password' => ['required', 'string'],
        ];
    }
}
```

- [ ] **Step 5: Create the AuthController**

Create `app/Http/Controllers/Api/AuthController.php`:

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\LoginRequest;
use App\Http\Requests\RegisterRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\Response;

final class AuthController extends Controller
{
    public function register(RegisterRequest $request): JsonResponse
    {
        $user = User::create([
            'name'     => $request->validated('name'),
            'email'    => $request->validated('email'),
            'password' => Hash::make($request->validated('password')),
        ]);

        return $this->tokenResponse($user, Response::HTTP_CREATED);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $user = User::where('email', $request->validated('email'))->first();

        if ($user === null || ! Hash::check($request->validated('password'), $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['These credentials do not match our records.'],
            ]);
        }

        return $this->tokenResponse($user, Response::HTTP_OK);
    }

    public function me(): UserResource
    {
        return new UserResource(request()->user());
    }

    private function tokenResponse(User $user, int $status): JsonResponse
    {
        return response()->json([
            'token' => $user->createToken('api')->plainTextToken,
            'user'  => new UserResource($user),
        ], $status);
    }
}
```

- [ ] **Step 6: Register the routes**

Modify `routes/api.php`. Add imports below the existing `use` lines:

```php
use App\Http\Controllers\Api\AuthController;
```

Inside the existing `Route::prefix('v1')->group(...)` closure, add:

```php
    Route::post('/auth/register', [AuthController::class, 'register'])->name('api.v1.auth.register');
    Route::post('/auth/login', [AuthController::class, 'login'])->name('api.v1.auth.login');

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::get('/me', [AuthController::class, 'me'])->name('api.v1.me');
    });
```

- [ ] **Step 7: Run the test to verify it passes**

Run: `php artisan test --filter=AuthEndpointTest`
Expected: PASS (5 tests).

- [ ] **Step 8: Commit**

```bash
git add 02-showcase/laravel
git commit -m "feat(pawmise): add register, login, and me endpoints via Sanctum"
```

---

## Task 6: Pets listing + detail endpoints

**Files:**
- Create: `02-showcase/laravel/app/Http/Controllers/Api/PetController.php`
- Create: `02-showcase/laravel/app/Http/Requests/ListPetsRequest.php`
- Create: `02-showcase/laravel/app/Http/Resources/PetResource.php`
- Modify: `02-showcase/laravel/routes/api.php`
- Test: `02-showcase/laravel/tests/Feature/Api/PetEndpointTest.php`

**Interfaces:**
- Consumes: `App\Models\Pet`, `App\Enums\PetStatus`.
- Produces: routes `GET /api/v1/pets` (named `api.v1.pets.index`), `GET /api/v1/pets/{pet}` (named `api.v1.pets.show`).
- Produces: `PetResource` → `{ id, name, species, breed, age_years, size, gender, description, image_url, base_fee, status, shelter_partner, is_senior, currency }`.
- Query filters on index: `species` (string), `size` (string), `status` (enum value), `senior` (bool), `q` (name LIKE). Paginated (15/page).

- [ ] **Step 1: Write the failing test**

Create `tests/Feature/Api/PetEndpointTest.php`:

```php
<?php

declare(strict_types=1);

namespace Tests\Feature\Api;

use App\Models\Pet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

final class PetEndpointTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_lists_pets_with_pagination_metadata(): void
    {
        Pet::factory()->count(3)->create();

        $this->getJson('/api/v1/pets')
            ->assertOk()
            ->assertJsonStructure([
                'data' => [['id', 'name', 'species', 'base_fee', 'status', 'is_senior', 'currency']],
                'meta' => ['current_page', 'total'],
            ])
            ->assertJsonPath('meta.total', 3);
    }

    #[Test]
    public function it_filters_by_species(): void
    {
        Pet::factory()->create(['species' => 'dog']);
        Pet::factory()->create(['species' => 'cat']);

        $this->getJson('/api/v1/pets?species=cat')
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.species', 'cat');
    }

    #[Test]
    public function it_filters_by_senior_flag(): void
    {
        config()->set('pawmise.senior.age_years', 8);
        Pet::factory()->create(['age_years' => 10]);
        Pet::factory()->create(['age_years' => 2]);

        $this->getJson('/api/v1/pets?senior=1')
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.is_senior', true);
    }

    #[Test]
    public function it_searches_by_name(): void
    {
        Pet::factory()->create(['name' => 'Rex']);
        Pet::factory()->create(['name' => 'Bella']);

        $this->getJson('/api/v1/pets?q=Rex')
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.name', 'Rex');
    }

    #[Test]
    public function it_shows_a_single_pet(): void
    {
        $pet = Pet::factory()->create(['name' => 'Rex']);

        $this->getJson("/api/v1/pets/{$pet->id}")
            ->assertOk()
            ->assertJsonPath('data.id', $pet->id)
            ->assertJsonPath('data.name', 'Rex');
    }

    #[Test]
    public function it_returns_404_for_a_missing_pet(): void
    {
        $this->getJson('/api/v1/pets/999999')->assertNotFound();
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test --filter=PetEndpointTest`
Expected: FAIL — 404 route not defined for `/api/v1/pets`.

- [ ] **Step 3: Create the ListPetsRequest**

Create `app/Http/Requests/ListPetsRequest.php`:

```php
<?php

declare(strict_types=1);

namespace App\Http\Requests;

use App\Enums\PetStatus;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class ListPetsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'species' => ['nullable', 'string', 'max:50'],
            'size'    => ['nullable', 'string', Rule::in(['small', 'medium', 'large'])],
            'status'  => ['nullable', Rule::enum(PetStatus::class)],
            'senior'  => ['nullable', 'boolean'],
            'q'       => ['nullable', 'string', 'max:100'],
        ];
    }
}
```

- [ ] **Step 4: Create the PetResource**

Create `app/Http/Resources/PetResource.php`:

```php
<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Models\Pet;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Pet
 */
final class PetResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id'              => $this->id,
            'name'            => $this->name,
            'species'         => $this->species,
            'breed'           => $this->breed,
            'age_years'       => $this->age_years,
            'size'            => $this->size,
            'gender'          => $this->gender,
            'description'     => $this->description,
            'image_url'       => $this->image_url,
            'base_fee'        => round((float) $this->base_fee, 2),
            'status'          => $this->status->value,
            'shelter_partner' => $this->shelter_partner,
            'is_senior'       => $this->is_senior,
            'currency'        => config('pawmise.currency'),
        ];
    }
}
```

- [ ] **Step 5: Create the PetController**

Create `app/Http/Controllers/Api/PetController.php`:

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\ListPetsRequest;
use App\Http\Resources\PetResource;
use App\Models\Pet;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

final class PetController extends Controller
{
    public function index(ListPetsRequest $request): AnonymousResourceCollection
    {
        $seniorAge = (int) config('pawmise.senior.age_years');

        $pets = Pet::query()
            ->when($request->validated('species'), fn ($q, $v) => $q->where('species', $v))
            ->when($request->validated('size'), fn ($q, $v) => $q->where('size', $v))
            ->when($request->validated('status'), fn ($q, $v) => $q->where('status', $v))
            ->when($request->validated('q'), fn ($q, $v) => $q->where('name', 'like', "%{$v}%"))
            ->when($request->boolean('senior'), fn ($q) => $q->where('age_years', '>=', $seniorAge))
            ->orderByDesc('id')
            ->paginate(15);

        return PetResource::collection($pets);
    }

    public function show(Pet $pet): PetResource
    {
        return new PetResource($pet);
    }
}
```

- [ ] **Step 6: Register the routes**

Modify `routes/api.php`. Add import:

```php
use App\Http\Controllers\Api\PetController;
```

Inside the `v1` group (public section, above the `auth:sanctum` group), add:

```php
    Route::get('/pets', [PetController::class, 'index'])->name('api.v1.pets.index');
    Route::get('/pets/{pet}', [PetController::class, 'show'])->name('api.v1.pets.show');
```

- [ ] **Step 7: Run the test to verify it passes**

Run: `php artisan test --filter=PetEndpointTest`
Expected: PASS (6 tests).

- [ ] **Step 8: Commit**

```bash
git add 02-showcase/laravel
git commit -m "feat(pawmise): add pets listing (with filters) and detail endpoints"
```

---

## Task 7: Fee-quote + adopt flow + adoption history

**Files:**
- Create: `02-showcase/laravel/app/Domain/Adoption/Exceptions/PetNotAvailableException.php`
- Create: `02-showcase/laravel/app/Http/Controllers/Api/AdoptionController.php`
- Create: `02-showcase/laravel/app/Http/Resources/FeeBreakdownResource.php`
- Create: `02-showcase/laravel/app/Http/Resources/AdoptionResource.php`
- Modify: `02-showcase/laravel/routes/api.php`
- Test: `02-showcase/laravel/tests/Feature/Api/AdoptFlowTest.php`

**Interfaces:**
- Consumes: `App\Domain\Adoption\AdoptionFeeCalculator::quote(Pet, User): FeeBreakdown`; `App\Domain\Adoption\FeeBreakdown`; `App\Enums\PetStatus`; `App\Models\{Pet,Adoption}`.
- Produces: routes (all `auth:sanctum`) `GET /api/v1/pets/{pet}/fee-quote` (`api.v1.pets.fee-quote`), `POST /api/v1/pets/{pet}/adopt` (`api.v1.pets.adopt`), `GET /api/v1/me/adoptions` (`api.v1.me.adoptions`).
- Produces: `FeeBreakdownResource` → `{ base_fee, discount_type, discount_amount, final_fee, currency }`; `AdoptionResource` → `{ id, pet: PetResource, base_fee, discount_type, discount_amount, final_fee, adopted_at }`.
- `PetNotAvailableException::render()` → 409 `application/problem+json`.

- [ ] **Step 1: Write the failing test**

Create `tests/Feature/Api/AdoptFlowTest.php`:

```php
<?php

declare(strict_types=1);

namespace Tests\Feature\Api;

use App\Enums\PetStatus;
use App\Models\Pet;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

final class AdoptFlowTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config()->set('pawmise.loyalty.threshold', 3);
        config()->set('pawmise.senior.age_years', 8);
    }

    #[Test]
    public function fee_quote_requires_authentication(): void
    {
        $pet = Pet::factory()->create();
        $this->getJson("/api/v1/pets/{$pet->id}/fee-quote")->assertUnauthorized();
    }

    #[Test]
    public function fee_quote_reflects_loyalty_for_a_repeat_adopter(): void
    {
        $user = User::factory()->create(['adoptions_count' => 3]);
        $pet  = Pet::factory()->create(['base_fee' => 200, 'age_years' => 2, 'shelter_partner' => false]);

        $this->actingAs($user, 'sanctum')
            ->getJson("/api/v1/pets/{$pet->id}/fee-quote")
            ->assertOk()
            ->assertJsonPath('data.discount_type', 'loyalty')
            ->assertJsonPath('data.final_fee', 170);
    }

    #[Test]
    public function it_adopts_an_available_pet_and_records_the_fee(): void
    {
        $user = User::factory()->create(['adoptions_count' => 0]);
        $pet  = Pet::factory()->create(['base_fee' => 150, 'status' => PetStatus::Available->value]);

        $this->actingAs($user, 'sanctum')
            ->postJson("/api/v1/pets/{$pet->id}/adopt")
            ->assertCreated()
            ->assertJsonPath('data.final_fee', 150)
            ->assertJsonPath('data.pet.id', $pet->id);

        $this->assertSame(PetStatus::Adopted, $pet->fresh()->status);
        $this->assertSame(1, $user->fresh()->adoptions_count);
        $this->assertDatabaseHas('adoptions', ['user_id' => $user->id, 'pet_id' => $pet->id]);
    }

    #[Test]
    public function adopting_an_already_adopted_pet_returns_409(): void
    {
        $user = User::factory()->create();
        $pet  = Pet::factory()->adopted()->create();

        $this->actingAs($user, 'sanctum')
            ->postJson("/api/v1/pets/{$pet->id}/adopt")
            ->assertStatus(409)
            ->assertHeader('Content-Type', 'application/problem+json')
            ->assertJsonStructure(['type', 'title', 'status', 'detail']);
    }

    #[Test]
    public function adopt_requires_authentication(): void
    {
        $pet = Pet::factory()->create();
        $this->postJson("/api/v1/pets/{$pet->id}/adopt")->assertUnauthorized();
    }

    #[Test]
    public function it_lists_the_users_adoption_history(): void
    {
        $user = User::factory()->create();
        $pet  = Pet::factory()->create(['status' => PetStatus::Available->value]);

        $this->actingAs($user, 'sanctum')->postJson("/api/v1/pets/{$pet->id}/adopt")->assertCreated();

        $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/me/adoptions')
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.pet.id', $pet->id);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test --filter=AdoptFlowTest`
Expected: FAIL — 404/route not defined for the fee-quote route.

- [ ] **Step 3: Create the PetNotAvailableException**

Create `app/Domain/Adoption/Exceptions/PetNotAvailableException.php`:

```php
<?php

declare(strict_types=1);

namespace App\Domain\Adoption\Exceptions;

use App\Models\Pet;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use RuntimeException;
use Symfony\Component\HttpFoundation\Response;

final class PetNotAvailableException extends RuntimeException
{
    public function __construct(public readonly int $petId)
    {
        parent::__construct("Pet {$petId} is not available for adoption.");
    }

    public static function for(Pet $pet): self
    {
        return new self((int) $pet->id);
    }

    public function render(Request $request): JsonResponse
    {
        return response()->json(
            [
                'type'   => 'https://pawmise.local/errors/pet-not-available',
                'title'  => 'Pet not available',
                'status' => Response::HTTP_CONFLICT,
                'detail' => $this->getMessage(),
            ],
            Response::HTTP_CONFLICT,
            ['Content-Type' => 'application/problem+json'],
        );
    }
}
```

- [ ] **Step 4: Create the resources**

Create `app/Http/Resources/FeeBreakdownResource.php`:

```php
<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Adoption\FeeBreakdown;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @property FeeBreakdown $resource
 */
final class FeeBreakdownResource extends JsonResource
{
    public function __construct(FeeBreakdown $breakdown)
    {
        parent::__construct($breakdown);
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'base_fee'        => round($this->resource->baseFee, 2),
            'discount_type'   => $this->resource->discountType?->value,
            'discount_amount' => round($this->resource->discountAmount, 2),
            'final_fee'       => round($this->resource->finalFee, 2),
            'currency'        => config('pawmise.currency'),
        ];
    }
}
```

Create `app/Http/Resources/AdoptionResource.php`:

```php
<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Models\Adoption;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Adoption
 */
final class AdoptionResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id'              => $this->id,
            'pet'             => new PetResource($this->whenLoaded('pet')),
            'base_fee'        => round((float) $this->base_fee, 2),
            'discount_type'   => $this->discount_type,
            'discount_amount' => round((float) $this->discount_amount, 2),
            'final_fee'       => round((float) $this->final_fee, 2),
            'adopted_at'      => $this->adopted_at?->toIso8601String(),
            'currency'        => config('pawmise.currency'),
        ];
    }
}
```

- [ ] **Step 5: Create the AdoptionController**

Create `app/Http/Controllers/Api/AdoptionController.php`:

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Domain\Adoption\AdoptionFeeCalculator;
use App\Domain\Adoption\Exceptions\PetNotAvailableException;
use App\Enums\PetStatus;
use App\Http\Controllers\Controller;
use App\Http\Resources\AdoptionResource;
use App\Http\Resources\FeeBreakdownResource;
use App\Models\Adoption;
use App\Models\Pet;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

final class AdoptionController extends Controller
{
    public function __construct(private readonly AdoptionFeeCalculator $calculator)
    {
    }

    public function quote(Pet $pet, Request $request): FeeBreakdownResource
    {
        return new FeeBreakdownResource(
            $this->calculator->quote($pet, $request->user()),
        );
    }

    public function adopt(Pet $pet, Request $request): JsonResponse
    {
        $user = $request->user();

        $adoption = DB::transaction(function () use ($pet, $user): Adoption {
            $locked = Pet::query()->whereKey($pet->id)->lockForUpdate()->firstOrFail();

            if ($locked->status !== PetStatus::Available) {
                throw PetNotAvailableException::for($locked);
            }

            $breakdown = $this->calculator->quote($locked, $user);

            $adoption = Adoption::create([
                'user_id'         => $user->id,
                'pet_id'          => $locked->id,
                'base_fee'        => $breakdown->baseFee,
                'discount_type'   => $breakdown->discountType?->value,
                'discount_amount' => $breakdown->discountAmount,
                'final_fee'       => $breakdown->finalFee,
                'adopted_at'      => now(),
            ]);

            $locked->update(['status' => PetStatus::Adopted]);
            $user->increment('adoptions_count');

            return $adoption;
        });

        return (new AdoptionResource($adoption->load('pet')))
            ->response()
            ->setStatusCode(Response::HTTP_CREATED);
    }

    public function history(Request $request): AnonymousResourceCollection
    {
        $adoptions = $request->user()
            ->adoptions()
            ->with('pet')
            ->latest('adopted_at')
            ->paginate(15);

        return AdoptionResource::collection($adoptions);
    }
}
```

- [ ] **Step 6: Register the routes**

Modify `routes/api.php`. Add import:

```php
use App\Http\Controllers\Api\AdoptionController;
```

Inside the existing `Route::middleware('auth:sanctum')->group(...)` block (created in Task 5), add:

```php
        Route::get('/pets/{pet}/fee-quote', [AdoptionController::class, 'quote'])->name('api.v1.pets.fee-quote');
        Route::post('/pets/{pet}/adopt', [AdoptionController::class, 'adopt'])->name('api.v1.pets.adopt');
        Route::get('/me/adoptions', [AdoptionController::class, 'history'])->name('api.v1.me.adoptions');
```

- [ ] **Step 7: Run the test to verify it passes**

Run: `php artisan test --filter=AdoptFlowTest`
Expected: PASS (6 tests).

- [ ] **Step 8: Run the whole suite (regression guard)**

Run: `composer test`
Expected: PASS — all new tests plus the original discount tests (legacy `/discount` still green).

- [ ] **Step 9: Commit**

```bash
git add 02-showcase/laravel
git commit -m "feat(pawmise): add fee-quote, adopt (transactional), and adoption history"
```

---

## Task 8: API docs (OpenAPI + Postman) + CI

**Files:**
- Create: `02-showcase/laravel/docs/openapi.yaml`
- Create: `02-showcase/laravel/docs/pawmise.postman_collection.json`
- Modify: `02-showcase/laravel/.github/workflows/ci.yml`
- Test: `02-showcase/laravel/tests/Feature/Api/RouteContractTest.php`

**Interfaces:**
- Consumes: all routes from Tasks 5–7.
- Produces: an OpenAPI 3.1 document and a Postman collection covering every `/api/v1` route; a contract test asserting the documented routes are registered.

- [ ] **Step 1: Write the failing contract test**

Create `tests/Feature/Api/RouteContractTest.php`:

```php
<?php

declare(strict_types=1);

namespace Tests\Feature\Api;

use Illuminate\Support\Facades\Route;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

final class RouteContractTest extends TestCase
{
    #[Test]
    public function all_documented_v1_routes_are_registered(): void
    {
        $expected = [
            'api.v1.discount.apply',
            'api.v1.auth.register',
            'api.v1.auth.login',
            'api.v1.me',
            'api.v1.pets.index',
            'api.v1.pets.show',
            'api.v1.pets.fee-quote',
            'api.v1.pets.adopt',
            'api.v1.me.adoptions',
        ];

        $registered = collect(Route::getRoutes()->getRoutesByName())->keys();

        foreach ($expected as $name) {
            $this->assertTrue($registered->contains($name), "Missing route: {$name}");
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails (or passes) and confirms route names**

Run: `php artisan test --filter=RouteContractTest`
Expected: PASS if Tasks 5–7 are complete (this test guards the contract). If any route name is missing, it FAILS naming the route — fix the route name before continuing.

- [ ] **Step 3: Write the OpenAPI document**

Create `docs/openapi.yaml`:

```yaml
openapi: 3.1.0
info:
  title: Pawmise API
  version: "1.0.0"
  description: >
    Pet-adoption platform API. Public endpoints for browsing pets and auth;
    Sanctum bearer-token endpoints for quoting fees, adopting, and history.
    The legacy POST /discount endpoint exposes the raw discount engine.
servers:
  - url: /api/v1
security:
  - bearerAuth: []
components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
  schemas:
    Pet:
      type: object
      properties:
        id: { type: integer }
        name: { type: string }
        species: { type: string }
        breed: { type: string, nullable: true }
        age_years: { type: integer }
        size: { type: string, enum: [small, medium, large] }
        gender: { type: string, enum: [male, female] }
        description: { type: string, nullable: true }
        image_url: { type: string, nullable: true }
        base_fee: { type: number }
        status: { type: string, enum: [available, pending, adopted] }
        shelter_partner: { type: boolean }
        is_senior: { type: boolean }
        currency: { type: string }
    FeeBreakdown:
      type: object
      properties:
        base_fee: { type: number }
        discount_type: { type: string, nullable: true, enum: [loyalty, senior, shelter_partner] }
        discount_amount: { type: number }
        final_fee: { type: number }
        currency: { type: string }
    Problem:
      type: object
      properties:
        type: { type: string }
        title: { type: string }
        status: { type: integer }
        detail: { type: string }
paths:
  /discount:
    post:
      security: []
      summary: Apply a discount (legacy raw engine)
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [price, strategy]
              properties:
                price: { type: number }
                strategy: { type: string, enum: [fixed, percentage, loyalty] }
                value: { type: number, nullable: true }
      responses:
        "200": { description: Discounted price }
        "400":
          description: Invalid discount input
          content:
            application/problem+json:
              schema: { $ref: "#/components/schemas/Problem" }
  /auth/register:
    post:
      security: []
      summary: Register and receive a token
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [name, email, password]
              properties:
                name: { type: string }
                email: { type: string, format: email }
                password: { type: string, minLength: 8 }
      responses:
        "201": { description: Created with token }
  /auth/login:
    post:
      security: []
      summary: Log in and receive a token
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [email, password]
              properties:
                email: { type: string, format: email }
                password: { type: string }
      responses:
        "200": { description: Token }
        "422": { description: Invalid credentials }
  /me:
    get:
      summary: Current user
      responses:
        "200": { description: The authenticated user }
        "401": { description: Unauthenticated }
  /pets:
    get:
      security: []
      summary: List adoptable pets
      parameters:
        - { name: species, in: query, schema: { type: string } }
        - { name: size, in: query, schema: { type: string, enum: [small, medium, large] } }
        - { name: status, in: query, schema: { type: string, enum: [available, pending, adopted] } }
        - { name: senior, in: query, schema: { type: boolean } }
        - { name: q, in: query, schema: { type: string } }
      responses:
        "200":
          description: Paginated pets
          content:
            application/json:
              schema:
                type: object
                properties:
                  data: { type: array, items: { $ref: "#/components/schemas/Pet" } }
  /pets/{pet}:
    get:
      security: []
      summary: Show one pet
      parameters:
        - { name: pet, in: path, required: true, schema: { type: integer } }
      responses:
        "200": { description: A pet }
        "404": { description: Not found }
  /pets/{pet}/fee-quote:
    get:
      summary: Preview the adoption fee for the current user
      parameters:
        - { name: pet, in: path, required: true, schema: { type: integer } }
      responses:
        "200":
          description: Fee breakdown
          content:
            application/json:
              schema:
                type: object
                properties:
                  data: { $ref: "#/components/schemas/FeeBreakdown" }
        "401": { description: Unauthenticated }
  /pets/{pet}/adopt:
    post:
      summary: Adopt a pet
      parameters:
        - { name: pet, in: path, required: true, schema: { type: integer } }
      responses:
        "201": { description: Adoption record }
        "401": { description: Unauthenticated }
        "409":
          description: Pet not available
          content:
            application/problem+json:
              schema: { $ref: "#/components/schemas/Problem" }
  /me/adoptions:
    get:
      summary: The current user's adoption history
      responses:
        "200": { description: Paginated adoptions }
        "401": { description: Unauthenticated }
```

- [ ] **Step 4: Write the Postman collection**

Create `docs/pawmise.postman_collection.json`:

```json
{
  "info": {
    "name": "Pawmise API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "variable": [
    { "key": "baseUrl", "value": "http://127.0.0.1:8000/api/v1" },
    { "key": "token", "value": "" }
  ],
  "item": [
    {
      "name": "Register",
      "request": {
        "method": "POST",
        "header": [{ "key": "Content-Type", "value": "application/json" }],
        "url": "{{baseUrl}}/auth/register",
        "body": { "mode": "raw", "raw": "{\n  \"name\": \"Ada\",\n  \"email\": \"ada@pawmise.test\",\n  \"password\": \"secret1234\"\n}" }
      }
    },
    {
      "name": "Login",
      "request": {
        "method": "POST",
        "header": [{ "key": "Content-Type", "value": "application/json" }],
        "url": "{{baseUrl}}/auth/login",
        "body": { "mode": "raw", "raw": "{\n  \"email\": \"ada@pawmise.test\",\n  \"password\": \"secret1234\"\n}" }
      }
    },
    {
      "name": "List pets",
      "request": { "method": "GET", "url": "{{baseUrl}}/pets?species=dog&senior=1" }
    },
    {
      "name": "Show pet",
      "request": { "method": "GET", "url": "{{baseUrl}}/pets/1" }
    },
    {
      "name": "Fee quote",
      "request": {
        "method": "GET",
        "header": [{ "key": "Authorization", "value": "Bearer {{token}}" }],
        "url": "{{baseUrl}}/pets/1/fee-quote"
      }
    },
    {
      "name": "Adopt",
      "request": {
        "method": "POST",
        "header": [{ "key": "Authorization", "value": "Bearer {{token}}" }],
        "url": "{{baseUrl}}/pets/1/adopt"
      }
    },
    {
      "name": "My adoptions",
      "request": {
        "method": "GET",
        "header": [{ "key": "Authorization", "value": "Bearer {{token}}" }],
        "url": "{{baseUrl}}/me/adoptions"
      }
    },
    {
      "name": "Discount (legacy)",
      "request": {
        "method": "POST",
        "header": [{ "key": "Content-Type", "value": "application/json" }],
        "url": "{{baseUrl}}/discount",
        "body": { "mode": "raw", "raw": "{\n  \"price\": 200,\n  \"strategy\": \"percentage\",\n  \"value\": 25\n}" }
      }
    }
  ]
}
```

- [ ] **Step 5: Confirm CI is unchanged-compatible**

Open `.github/workflows/ci.yml`. The suite runs on SQLite in-memory (per `phpunit.xml`), so no MySQL service is needed in CI. Confirm the `extensions:` line includes `pdo_sqlite` (it does). No edit required unless a step is missing; if so, ensure the "Run tests" step is `vendor/bin/phpunit --colors=always` or `php artisan test`.

- [ ] **Step 6: Run the whole suite one final time**

Run: `composer test`
Expected: PASS — full suite green.

- [ ] **Step 7: Commit**

```bash
git add 02-showcase/laravel
git commit -m "docs(pawmise): add OpenAPI 3.1 spec, Postman collection, route contract test"
```

---

## Final verification (Definition of Done for Phase 1)

- [ ] `composer test` is fully green (original discount tests + all new tests).
- [ ] Fresh DB works: `php artisan migrate:fresh --seed` then `php artisan serve`, and `curl http://127.0.0.1:8000/api/v1/pets` returns seeded pets.
- [ ] End-to-end by curl: register → capture token → `GET /pets/{id}/fee-quote` (with `Authorization: Bearer <token>`) → `POST /pets/{id}/adopt` → pet now `adopted`; a second adopt returns `409` with `application/problem+json`.
- [ ] Loyalty: a user with `adoptions_count >= 3` sees a reduced `final_fee` in the quote.
- [ ] `git diff --stat` shows **no changes** under `app/Domain/Discount/` or anywhere in `01-answers/`.
- [ ] `docs/openapi.yaml` lists every implemented `/api/v1` route.
```
