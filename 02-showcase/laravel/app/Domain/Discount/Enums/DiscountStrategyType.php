<?php

declare(strict_types=1);

namespace App\Domain\Discount\Enums;

enum DiscountStrategyType: string
{
    case Fixed = 'fixed';
    case Percentage = 'percentage';
    case Loyalty = 'loyalty';

    public function requiresValue(): bool
    {
        return match ($this) {
            self::Fixed, self::Percentage => true,
            self::Loyalty => false,
        };
    }

    public function label(): string
    {
        return match ($this) {
            self::Fixed => 'Fixed amount',
            self::Percentage => 'Percentage',
            self::Loyalty => 'Loyalty (15% off)',
        };
    }
}
