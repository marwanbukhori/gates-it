<?php

declare(strict_types=1);

namespace App\Domain\Adoption;

use App\Domain\Discount\Contracts\DiscountStrategyInterface;
use App\Domain\Discount\DiscountService;
use App\Domain\Discount\DiscountStrategyFactory;
use App\Domain\Discount\Enums\DiscountStrategyType;
use App\Domain\Discount\Exceptions\InvalidDiscountException;
use App\Models\Pet;
use App\Models\User;

final readonly class AdoptionFeeCalculator
{
    public function __construct(private DiscountStrategyFactory $factory)
    {
    }

    public function quote(Pet $pet, User $user): FeeBreakdown
    {
        $baseFee = (float) $pet->base_fee;

        $bestReason = null;
        $bestFinal  = $baseFee;

        foreach ($this->candidatesFor($pet, $user) as $reason => $strategy) {
            try {
                $final = (new DiscountService($strategy))->applyDiscount($baseFee);
            } catch (InvalidDiscountException) {
                continue; // strategy not applicable to this fee (e.g. waiver > fee)
            }

            if ($final < $bestFinal) {
                $bestFinal  = $final;
                $bestReason = FeeDiscount::from($reason);
            }
        }

        if ($bestReason === null) {
            return FeeBreakdown::none($baseFee);
        }

        return new FeeBreakdown(
            baseFee: $baseFee,
            discountType: $bestReason,
            discountAmount: round($baseFee - $bestFinal, 2),
            finalFee: round($bestFinal, 2),
        );
    }

    /**
     * Map each applicable product reason to a clean engine strategy.
     *
     * @return array<string, DiscountStrategyInterface> keyed by FeeDiscount value
     */
    private function candidatesFor(Pet $pet, User $user): array
    {
        $candidates = [];

        if ($user->adoptions_count >= (int) config('pawmise.loyalty.threshold')) {
            $candidates[FeeDiscount::Loyalty->value] = $this->factory->make(
                DiscountStrategyType::Percentage,
                (float) config('pawmise.loyalty.percentage'),
            );
        }

        if ($pet->is_senior) {
            $candidates[FeeDiscount::Senior->value] = $this->factory->make(
                DiscountStrategyType::Percentage,
                (float) config('pawmise.senior.percentage'),
            );
        }

        if ($pet->shelter_partner) {
            $candidates[FeeDiscount::ShelterPartner->value] = $this->factory->make(
                DiscountStrategyType::Fixed,
                (float) config('pawmise.shelter_partner.waiver'),
            );
        }

        return $candidates;
    }
}
