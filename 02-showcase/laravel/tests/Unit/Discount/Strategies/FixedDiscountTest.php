<?php

declare(strict_types=1);

namespace Tests\Unit\Discount\Strategies;

use App\Domain\Discount\Enums\DiscountStrategyType;
use App\Domain\Discount\Exceptions\InvalidDiscountException;
use App\Domain\Discount\Strategies\FixedDiscount;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;

final class FixedDiscountTest extends TestCase
{
    #[Test]
    public function it_subtracts_the_amount_from_the_original_price(): void
    {
        $strategy = new FixedDiscount(amount: 20);

        $this->assertSame(80.0, $strategy->calculate(100));
    }

    #[Test]
    public function it_reports_its_strategy_type(): void
    {
        $this->assertSame(
            DiscountStrategyType::Fixed,
            (new FixedDiscount(1))->type()
        );
    }

    #[Test]
    public function it_rejects_amounts_greater_than_the_original_price(): void
    {
        $this->expectException(InvalidDiscountException::class);
        $this->expectExceptionMessage('must not exceed the original price');

        (new FixedDiscount(150))->assertApplicableTo(100);
    }

    #[Test]
    public function it_accepts_an_amount_equal_to_the_price(): void
    {
        (new FixedDiscount(100))->assertApplicableTo(100);
        $this->addToAssertionCount(1);
    }
}
