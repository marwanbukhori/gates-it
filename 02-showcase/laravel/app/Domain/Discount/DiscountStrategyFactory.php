<?php

declare(strict_types=1);

namespace App\Domain\Discount;

use App\Domain\Discount\Contracts\DiscountStrategyInterface;
use App\Domain\Discount\Enums\DiscountStrategyType;
use App\Domain\Discount\Strategies\FixedDiscount;
use App\Domain\Discount\Strategies\LoyaltyDiscount;
use App\Domain\Discount\Strategies\PercentageDiscount;
use InvalidArgumentException;

final class DiscountStrategyFactory
{
    public function make(DiscountStrategyType $type, ?float $value): DiscountStrategyInterface
    {
        return match ($type) {
            DiscountStrategyType::Fixed => new FixedDiscount(
                $this->requireValue($type, $value)
            ),
            DiscountStrategyType::Percentage => new PercentageDiscount(
                $this->requireValue($type, $value)
            ),
            DiscountStrategyType::Loyalty => new LoyaltyDiscount(),
        };
    }

    private function requireValue(DiscountStrategyType $type, ?float $value): float
    {
        if ($value === null) {
            throw new InvalidArgumentException(
                "Strategy '{$type->value}' requires a numeric 'value' input."
            );
        }

        return $value;
    }
}
