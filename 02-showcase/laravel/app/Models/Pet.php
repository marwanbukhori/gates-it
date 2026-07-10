<?php

declare(strict_types=1);

namespace App\Models;

use App\Enums\PetStatus;
use Database\Factories\PetFactory;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

final class Pet extends Model
{
    /** @use HasFactory<PetFactory> */
    use HasFactory;

    protected $fillable = [
        'name', 'species', 'breed', 'age_years', 'size', 'gender',
        'description', 'image_url', 'base_fee', 'status', 'shelter_partner',
    ];

    protected function casts(): array
    {
        return [
            'age_years'       => 'integer',
            'base_fee'        => 'decimal:2',
            'status'          => PetStatus::class,
            'shelter_partner' => 'boolean',
        ];
    }

    protected function isSenior(): Attribute
    {
        return Attribute::get(
            fn (): bool => $this->age_years >= (int) config('pawmise.senior.age_years'),
        );
    }
}
