<?php

declare(strict_types=1);

namespace App\Domain\Discount\Strategies;

use App\Domain\Discount\Contracts\DiscountStrategyInterface;
use App\Domain\Discount\Enums\DiscountStrategyType;
use App\Domain\Discount\Exceptions\InvalidDiscountException;

final readonly class FixedDiscount implements DiscountStrategyInterface
{
    public function __construct(public float $amount)
    {
    }

    public function calculate(float $originalPrice): float
    {
        return $originalPrice - $this->amount;
    }

    public function type(): DiscountStrategyType
    {
        return DiscountStrategyType::Fixed;
    }

    public function assertApplicableTo(float $originalPrice): void
    {
        if ($this->amount > $originalPrice) {
            throw InvalidDiscountException::fixedAmountExceedsPrice($this->amount, $originalPrice);
        }
    }
}
