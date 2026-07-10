<?php

declare(strict_types=1);

namespace App\Services;

use App\Contracts\DiscountStrategyInterface;
use App\Services\Discounts\FixedDiscount;
use App\Services\Discounts\PercentageDiscount;
use Symfony\Component\HttpKernel\Exception\BadRequestHttpException;

final class DiscountService
{
    public function __construct(private readonly DiscountStrategyInterface $strategy)
    {
    }

    public function applyDiscount(float $price): float
    {
        $this->validate($price);

        return $this->strategy->calculate($price);
    }

    private function validate(float $price): void
    {
        if ($this->strategy instanceof PercentageDiscount) {
            $percentage = $this->strategy->percentage();
            if ($percentage < 0 || $percentage > 100) {
                throw new BadRequestHttpException(
                    "Percentage discount must be between 0 and 100, got {$percentage}."
                );
            }
        }

        if ($this->strategy instanceof FixedDiscount) {
            $amount = $this->strategy->amount();
            if ($amount > $price) {
                throw new BadRequestHttpException(
                    "Fixed discount amount ({$amount}) must not exceed the original price ({$price})."
                );
            }
        }
    }
}
