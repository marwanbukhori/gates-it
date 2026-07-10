<?php

declare(strict_types=1);

namespace App\Domain\Discount;

use App\Domain\Discount\Contracts\DiscountStrategyInterface;

final readonly class DiscountService
{
    public function __construct(private DiscountStrategyInterface $strategy)
    {
    }

    public function applyDiscount(float $price): float
    {
        $this->strategy->assertApplicableTo($price);

        return $this->strategy->calculate($price);
    }

    public function strategy(): DiscountStrategyInterface
    {
        return $this->strategy;
    }
}
