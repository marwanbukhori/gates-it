<?php

declare(strict_types=1);

namespace App\Domain\Discount\Strategies;

use App\Domain\Discount\Contracts\DiscountStrategyInterface;
use App\Domain\Discount\Enums\DiscountStrategyType;

final readonly class LoyaltyDiscount implements DiscountStrategyInterface
{
    private const LOYALTY_FACTOR = 0.85;

    public function calculate(float $originalPrice): float
    {
        return $originalPrice - (self::LOYALTY_FACTOR * $originalPrice);
    }

    public function type(): DiscountStrategyType
    {
        return DiscountStrategyType::Loyalty;
    }

    public function assertApplicableTo(float $originalPrice): void
    {
        // Loyalty discount is a flat multiplier — no input to validate.
    }
}
