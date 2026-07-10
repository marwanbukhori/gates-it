<?php

declare(strict_types=1);

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

final class AuthEndpointTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_registers_a_user_and_returns_a_token(): void
    {
        $this->postJson('/api/v1/auth/register', [
            'name'     => 'Ada Lovelace',
            'email'    => 'ada@pawmise.test',
            'password' => 'secret1234',
        ])
            ->assertCreated()
            ->assertJsonStructure(['token', 'user' => ['id', 'name', 'email', 'adoptions_count']])
            ->assertJsonPath('user.email', 'ada@pawmise.test');
    }

    #[Test]
    public function it_logs_in_with_valid_credentials(): void
    {
        User::factory()->create([
            'email'    => 'grace@pawmise.test',
            'password' => Hash::make('secret1234'),
        ]);

        $this->postJson('/api/v1/auth/login', [
            'email'    => 'grace@pawmise.test',
            'password' => 'secret1234',
        ])
            ->assertOk()
            ->assertJsonStructure(['token', 'user']);
    }

    #[Test]
    public function it_rejects_bad_credentials_with_422(): void
    {
        User::factory()->create(['email' => 'grace@pawmise.test', 'password' => Hash::make('secret1234')]);

        $this->postJson('/api/v1/auth/login', [
            'email'    => 'grace@pawmise.test',
            'password' => 'wrong-password',
        ])->assertStatus(422)->assertJsonValidationErrors(['email']);
    }

    #[Test]
    public function me_requires_authentication(): void
    {
        $this->getJson('/api/v1/me')->assertUnauthorized();
    }

    #[Test]
    public function me_returns_the_authenticated_user(): void
    {
        $user = User::factory()->create(['adoptions_count' => 2]);

        $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/me')
            ->assertOk()
            ->assertJsonPath('data.adoptions_count', 2)
            ->assertJsonPath('data.id', $user->id);
    }
}
