<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\AdoptionFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

final class Adoption extends Model
{
    /** @use HasFactory<AdoptionFactory> */
    use HasFactory;

    protected $fillable = [
        'user_id', 'pet_id', 'base_fee', 'discount_type',
        'discount_amount', 'final_fee', 'adopted_at',
    ];

    protected function casts(): array
    {
        return [
            'base_fee'        => 'decimal:2',
            'discount_amount' => 'decimal:2',
            'final_fee'       => 'decimal:2',
            'adopted_at'      => 'datetime',
        ];
    }

    /** @return BelongsTo<User, $this> */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /** @return BelongsTo<Pet, $this> */
    public function pet(): BelongsTo
    {
        return $this->belongsTo(Pet::class);
    }
}
