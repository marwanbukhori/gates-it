<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Models\Adoption;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Adoption
 */
final class AdoptionResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id'              => $this->id,
            'pet'             => new PetResource($this->whenLoaded('pet')),
            'base_fee'        => round((float) $this->base_fee, 2),
            'discount_type'   => $this->discount_type,
            'discount_amount' => round((float) $this->discount_amount, 2),
            'final_fee'       => round((float) $this->final_fee, 2),
            'adopted_at'      => $this->adopted_at?->toIso8601String(),
            'currency'        => config('pawmise.currency'),
        ];
    }
}
