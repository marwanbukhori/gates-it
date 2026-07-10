<?php

declare(strict_types=1);

namespace Tests\Unit\Discount\Strategies;

use App\Domain\Discount\Enums\DiscountStrategyType;
use App\Domain\Discount\Exceptions\InvalidDiscountException;
use App\Domain\Discount\Strategies\PercentageDiscount;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;

final class PercentageDiscountTest extends TestCase
{
    #[Test]
    public function it_applies_percent_off_the_original_price(): void
    {
        $strategy = new PercentageDiscount(percentage: 25);

        $this->assertSame(75.0, $strategy->calculate(100));
    }

    #[Test]
    public function it_reports_its_strategy_type(): void
    {
        $this->assertSame(
            DiscountStrategyType::Percentage,
            (new PercentageDiscount(1))->type()
        );
    }

    /**
     * @param  int|float  $value
     */
    #[Test]
    #[DataProvider('outOfRangeValues')]
    public function it_rejects_percentages_outside_zero_to_hundred($value): void
    {
        $this->expectException(InvalidDiscountException::class);
        $this->expectExceptionMessage('must be between 0 and 100');

        (new PercentageDiscount((float) $value))->assertApplicableTo(100);
    }

    /**
     * @return iterable<string, array{int|float}>
     */
    public static function outOfRangeValues(): iterable
    {
        yield 'negative'    => [-1];
        yield 'over 100'    => [120];
        yield 'huge'        => [9999];
    }

    #[Test]
    public function it_accepts_boundary_values_zero_and_one_hundred(): void
    {
        (new PercentageDiscount(0))->assertApplicableTo(100);
        (new PercentageDiscount(100))->assertApplicableTo(100);
        $this->addToAssertionCount(2);
    }
}
