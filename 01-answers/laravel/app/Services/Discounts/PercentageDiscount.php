<?php

declare(strict_types=1);

namespace App\Services\Discounts;

use App\Contracts\DiscountStrategyInterface;

final class PercentageDiscount implements DiscountStrategyInterface
{
    public function __construct(private readonly float $percentage)
    {
    }

    public function calculate(float $originalPrice): float
    {
        return $originalPrice - (($this->percentage / 100) * $originalPrice);
    }

    public function percentage(): float
    {
        return $this->percentage;
    }
}
