<?php

declare(strict_types=1);

namespace App\Services\Discounts;

use App\Contracts\DiscountStrategyInterface;

final class FixedDiscount implements DiscountStrategyInterface
{
    public function __construct(private readonly float $amount)
    {
    }

    public function calculate(float $originalPrice): float
    {
        return $originalPrice - $this->amount;
    }

    public function amount(): float
    {
        return $this->amount;
    }
}
