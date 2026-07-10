<?php

declare(strict_types=1);

namespace Tests\Unit\Discount;

use App\Domain\Discount\Contracts\DiscountStrategyInterface;
use App\Domain\Discount\DiscountService;
use App\Domain\Discount\Enums\DiscountStrategyType;
use App\Domain\Discount\Exceptions\InvalidDiscountException;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;

final class DiscountServiceTest extends TestCase
{
    #[Test]
    public function it_delegates_calculation_to_the_injected_strategy(): void
    {
        $strategy = $this->stubStrategy(
            calculateResult: 42.0,
        );

        $service = new DiscountService($strategy);

        $this->assertSame(42.0, $service->applyDiscount(100));
    }

    #[Test]
    public function it_validates_before_calculating(): void
    {
        $strategy = new class implements DiscountStrategyInterface
        {
            public function calculate(float $originalPrice): float
            {
                throw new \LogicException('calculate() must not run when validation fails');
            }

            public function type(): DiscountStrategyType
            {
                return DiscountStrategyType::Fixed;
            }

            public function assertApplicableTo(float $originalPrice): void
            {
                throw new InvalidDiscountException('nope', field: 'value', value: null);
            }
        };

        $this->expectException(InvalidDiscountException::class);

        (new DiscountService($strategy))->applyDiscount(100);
    }

    private function stubStrategy(float $calculateResult): DiscountStrategyInterface
    {
        return new class($calculateResult) implements DiscountStrategyInterface
        {
            public function __construct(private readonly float $result)
            {
            }

            public function calculate(float $originalPrice): float
            {
                return $this->result;
            }

            public function type(): DiscountStrategyType
            {
                return DiscountStrategyType::Loyalty;
            }

            public function assertApplicableTo(float $originalPrice): void
            {
            }
        };
    }
}
