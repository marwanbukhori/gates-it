<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\Adoption;
use App\Models\Pet;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Adoption>
 */
final class AdoptionFactory extends Factory
{
    protected $model = Adoption::class;

    public function definition(): array
    {
        $base = fake()->randomFloat(2, 60, 400);

        return [
            'user_id'         => User::factory(),
            'pet_id'          => Pet::factory(),
            'base_fee'        => $base,
            'discount_type'   => null,
            'discount_amount' => 0,
            'final_fee'       => $base,
            'adopted_at'      => now(),
        ];
    }
}
