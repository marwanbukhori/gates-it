<?php

declare(strict_types=1);

namespace App\Domain\Discount\Strategies;

use App\Domain\Discount\Contracts\DiscountStrategyInterface;
use App\Domain\Discount\Enums\DiscountStrategyType;
use App\Domain\Discount\Exceptions\InvalidDiscountException;

final readonly class PercentageDiscount implements DiscountStrategyInterface
{
    public function __construct(public float $percentage)
    {
    }

    public function calculate(float $originalPrice): float
    {
        return $originalPrice - (($this->percentage / 100) * $originalPrice);
    }

    public function type(): DiscountStrategyType
    {
        return DiscountStrategyType::Percentage;
    }

    public function assertApplicableTo(float $originalPrice): void
    {
        if ($this->percentage < 0 || $this->percentage > 100) {
            throw InvalidDiscountException::percentageOutOfRange($this->percentage);
        }
    }
}
