<?php

namespace Database\Seeders;

use App\Models\Pet;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        User::factory()->create([
            'name'  => 'Demo Adopter',
            'email' => 'demo@pawmise.test',
        ]);

        Pet::factory()->count(16)->create();
        Pet::factory()->count(4)->senior()->create();
        Pet::factory()->count(2)->shelterPartner()->create();
        Pet::factory()->count(2)->senior()->shelterPartner()->create();
    }
}
