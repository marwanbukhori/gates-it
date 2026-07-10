<?php

declare(strict_types=1);

namespace App\Domain\Adoption;

final readonly class FeeBreakdown
{
    public function __construct(
        public float $baseFee,
        public ?FeeDiscount $discountType,
        public float $discountAmount,
        public float $finalFee,
    ) {
    }

    public static function none(float $baseFee): self
    {
        return new self($baseFee, null, 0.0, $baseFee);
    }
}
