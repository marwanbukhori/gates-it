<?php

declare(strict_types=1);

namespace App\Services\Discounts;

use App\Contracts\DiscountStrategyInterface;

final class LoyaltyDiscount implements DiscountStrategyInterface
{
    private const LOYALTY_FACTOR = 0.85;

    public function calculate(float $originalPrice): float
    {
        return $originalPrice - (self::LOYALTY_FACTOR * $originalPrice);
    }
}
