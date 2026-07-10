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
