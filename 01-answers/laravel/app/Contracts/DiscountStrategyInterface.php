<?php

declare(strict_types=1);

namespace App\Contracts;

interface DiscountStrategyInterface
{
    public function calculate(float $originalPrice): float;
}
