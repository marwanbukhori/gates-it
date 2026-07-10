<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Services\Discounts\FixedDiscount;
use App\Services\Discounts\LoyaltyDiscount;
use App\Services\Discounts\PercentageDiscount;
use App\Services\DiscountService;
use PHPUnit\Framework\TestCase;
use Symfony\Component\HttpKernel\Exception\BadRequestHttpException;

final class DiscountServiceTest extends TestCase
{
    public function test_fixed_discount_subtracts_amount(): void
    {
        $service = new DiscountService(new FixedDiscount(20));
        $this->assertSame(80.0, $service->applyDiscount(100));
    }

    public function test_percentage_discount_applies_percent(): void
    {
        $service = new DiscountService(new PercentageDiscount(25));
        $this->assertSame(75.0, $service->applyDiscount(100));
    }

    public function test_loyalty_discount_uses_0_85_factor(): void
    {
        $service = new DiscountService(new LoyaltyDiscount());
        $this->assertEqualsWithDelta(15.0, $service->applyDiscount(100), 0.0001);
    }

    public function test_percentage_below_zero_throws_400(): void
    {
        $this->expectException(BadRequestHttpException::class);
        (new DiscountService(new PercentageDiscount(-1)))->applyDiscount(100);
    }

    public function test_percentage_above_hundred_throws_400(): void
    {
        $this->expectException(BadRequestHttpException::class);
        (new DiscountService(new PercentageDiscount(120)))->applyDiscount(100);
    }

    public function test_fixed_amount_greater_than_price_throws_400(): void
    {
        $this->expectException(BadRequestHttpException::class);
        (new DiscountService(new FixedDiscount(150)))->applyDiscount(100);
    }
}
