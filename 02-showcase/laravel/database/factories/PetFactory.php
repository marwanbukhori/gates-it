<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Enums\PetStatus;
use App\Models\Pet;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Pet>
 */
final class PetFactory extends Factory
{
    protected $model = Pet::class;

    public function definition(): array
    {
        return [
            'name'            => fake()->firstName(),
            'species'         => fake()->randomElement(['dog', 'cat', 'rabbit']),
            'breed'           => fake()->word(),
            'age_years'       => fake()->numberBetween(1, 7),
            'size'            => fake()->randomElement(['small', 'medium', 'large']),
            'gender'          => fake()->randomElement(['male', 'female']),
            'description'     => fake()->sentence(12),
            'image_url'       => 'https://placedog.net/500/280?id=' . fake()->numberBetween(1, 200),
            'base_fee'        => fake()->randomFloat(2, 60, 400),
            'status'          => PetStatus::Available->value,
            'shelter_partner' => false,
        ];
    }

    public function senior(): static
    {
        return $this->state(fn (): array => ['age_years' => fake()->numberBetween(8, 15)]);
    }

    public function shelterPartner(): static
    {
        return $this->state(fn (): array => ['shelter_partner' => true]);
    }

    public function adopted(): static
    {
        return $this->state(fn (): array => ['status' => PetStatus::Adopted->value]);
    }
}
