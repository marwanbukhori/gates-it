<?php

declare(strict_types=1);

namespace Tests\Unit\Discount;

use App\Domain\Discount\DiscountStrategyFactory;
use App\Domain\Discount\Enums\DiscountStrategyType;
use App\Domain\Discount\Strategies\FixedDiscount;
use App\Domain\Discount\Strategies\LoyaltyDiscount;
use App\Domain\Discount\Strategies\PercentageDiscount;
use InvalidArgumentException;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;

final class DiscountStrategyFactoryTest extends TestCase
{
    #[Test]
    public function it_builds_a_fixed_strategy(): void
    {
        $strategy = (new DiscountStrategyFactory())->make(DiscountStrategyType::Fixed, 20.0);

        $this->assertInstanceOf(FixedDiscount::class, $strategy);
    }

    #[Test]
    public function it_builds_a_percentage_strategy(): void
    {
        $strategy = (new DiscountStrategyFactory())->make(DiscountStrategyType::Percentage, 15.0);

        $this->assertInstanceOf(PercentageDiscount::class, $strategy);
    }

    #[Test]
    public function it_builds_a_loyalty_strategy_without_a_value(): void
    {
        $strategy = (new DiscountStrategyFactory())->make(DiscountStrategyType::Loyalty, null);

        $this->assertInstanceOf(LoyaltyDiscount::class, $strategy);
    }

    #[Test]
    public function it_rejects_a_missing_value_when_strategy_requires_it(): void
    {
        $this->expectException(InvalidArgumentException::class);

        (new DiscountStrategyFactory())->make(DiscountStrategyType::Fixed, null);
    }
}
