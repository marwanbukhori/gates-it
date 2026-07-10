<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Models\Pet;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Pet
 */
final class PetResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id'              => $this->id,
            'name'            => $this->name,
            'species'         => $this->species,
            'breed'           => $this->breed,
            'age_years'       => $this->age_years,
            'size'            => $this->size,
            'gender'          => $this->gender,
            'description'     => $this->description,
            'image_url'       => $this->image_url,
            'base_fee'        => round((float) $this->base_fee, 2),
            'status'          => $this->status->value,
            'shelter_partner' => $this->shelter_partner,
            'is_senior'       => $this->is_senior,
            'currency'        => config('pawmise.currency'),
        ];
    }
}
