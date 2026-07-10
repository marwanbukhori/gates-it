<?php

declare(strict_types=1);

namespace App\Domain\Adoption;

/**
 * Product-level reason an adoption fee was discounted. Distinct from the
 * engine's DiscountStrategyType so the fee breakdown speaks the product's
 * language, not the implementation's.
 */
enum FeeDiscount: string
{
    case Loyalty        = 'loyalty';
    case Senior         = 'senior';
    case ShelterPartner = 'shelter_partner';

    public function label(): string
    {
        return match ($this) {
            self::Loyalty        => 'Loyalty reward',
            self::Senior         => 'Senior pet',
            self::ShelterPartner => 'Shelter partner waiver',
        };
    }
}
