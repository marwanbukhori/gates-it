<?php

declare(strict_types=1);

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
        // Idempotent so it is safe to run on every deploy/boot in production.
        User::firstOrCreate(
            ['email' => 'demo@pawmise.test'],
            ['name' => 'Demo Adopter', 'password' => 'password'],
        );

        if (Pet::query()->exists()) {
            return;
        }

        Pet::factory()->count(16)->create();
        Pet::factory()->count(4)->senior()->create();
        Pet::factory()->count(2)->shelterPartner()->create();
        Pet::factory()->count(2)->senior()->shelterPartner()->create();
    }
}
