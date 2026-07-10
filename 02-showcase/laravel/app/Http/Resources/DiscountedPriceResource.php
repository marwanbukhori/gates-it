<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Discount\Enums\DiscountStrategyType;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @property float $originalPrice
 * @property float $finalPrice
 * @property DiscountStrategyType $strategy
 */
final class DiscountedPriceResource extends JsonResource
{
    public function __construct(
        public readonly float $originalPrice,
        public readonly float $finalPrice,
        public readonly DiscountStrategyType $strategy,
    ) {
        parent::__construct(null);
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $discountAmount = $this->originalPrice - $this->finalPrice;
        $discountPercent = $this->originalPrice > 0
            ? ($discountAmount / $this->originalPrice) * 100
            : 0.0;

        return [
            'strategy'         => $this->strategy->value,
            'strategy_label'   => $this->strategy->label(),
            'original_price'   => round($this->originalPrice, 2),
            'final_price'      => round($this->finalPrice, 2),
            'discount_amount'  => round($discountAmount, 2),
            'discount_percent' => round($discountPercent, 2),
            'currency'         => 'MYR',
        ];
    }
}
