<?php

declare(strict_types=1);

namespace App\Domain\Discount\Contracts;

use App\Domain\Discount\Enums\DiscountStrategyType;
use App\Domain\Discount\Exceptions\InvalidDiscountException;

interface DiscountStrategyInterface
{
    public function calculate(float $originalPrice): float;

    public function type(): DiscountStrategyType;

    /**
     * Validate the strategy's inputs against the given base price.
     *
     * @throws InvalidDiscountException when the strategy inputs are not applicable
     *                                  to the given price.
     */
    public function assertApplicableTo(float $originalPrice): void;
}
