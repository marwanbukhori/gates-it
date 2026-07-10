<?php

declare(strict_types=1);

namespace Tests\Unit\Discount\Strategies;

use App\Domain\Discount\Enums\DiscountStrategyType;
use App\Domain\Discount\Strategies\LoyaltyDiscount;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;

final class LoyaltyDiscountTest extends TestCase
{
    #[Test]
    public function it_returns_original_minus_0_85_times_original(): void
    {
        $strategy = new LoyaltyDiscount();

        $this->assertEqualsWithDelta(15.0, $strategy->calculate(100), 0.0001);
        $this->assertEqualsWithDelta(30.0, $strategy->calculate(200), 0.0001);
    }

    #[Test]
    public function it_reports_its_strategy_type(): void
    {
        $this->assertSame(
            DiscountStrategyType::Loyalty,
            (new LoyaltyDiscount())->type()
        );
    }

    #[Test]
    public function it_has_no_input_to_validate(): void
    {
        (new LoyaltyDiscount())->assertApplicableTo(100);
        $this->addToAssertionCount(1);
    }
}
