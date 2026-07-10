<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Adoption\FeeBreakdown;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @property FeeBreakdown $resource
 */
final class FeeBreakdownResource extends JsonResource
{
    public function __construct(FeeBreakdown $breakdown)
    {
        parent::__construct($breakdown);
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'base_fee'        => round($this->resource->baseFee, 2),
            'discount_type'   => $this->resource->discountType?->value,
            'discount_amount' => round($this->resource->discountAmount, 2),
            'final_fee'       => round($this->resource->finalFee, 2),
            'currency'        => config('pawmise.currency'),
        ];
    }
}
