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
        // Idempotent so it is safe to run on every deploy/boot.
        // The fixed-password demo user is LOCAL-ONLY — never bake a known
        // credential into a deployed (public-repo) environment. In a deploy,
        // users are created at runtime via POST /api/v1/auth/register.
        if (app()->environment('local')) {
            User::firstOrCreate(
                ['email' => 'demo@pawmise.test'],
                ['name' => 'Demo Adopter', 'password' => env('DEMO_USER_PASSWORD', 'password')],
            );
        }

        if (Pet::query()->exists()) {
            return;
        }

        Pet::factory()->count(16)->create();
        Pet::factory()->count(4)->senior()->create();
        Pet::factory()->count(2)->shelterPartner()->create();
        Pet::factory()->count(2)->senior()->shelterPartner()->create();
    }
}
