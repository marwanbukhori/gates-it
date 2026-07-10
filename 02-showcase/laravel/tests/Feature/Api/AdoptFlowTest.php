<?php

declare(strict_types=1);

namespace Tests\Feature\Api;

use App\Enums\PetStatus;
use App\Models\Pet;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

final class AdoptFlowTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config()->set('pawmise.loyalty.threshold', 3);
        config()->set('pawmise.senior.age_years', 8);
    }

    #[Test]
    public function fee_quote_requires_authentication(): void
    {
        $pet = Pet::factory()->create();
        $this->getJson("/api/v1/pets/{$pet->id}/fee-quote")->assertUnauthorized();
    }

    #[Test]
    public function fee_quote_reflects_loyalty_for_a_repeat_adopter(): void
    {
        $user = User::factory()->create(['adoptions_count' => 3]);
        $pet  = Pet::factory()->create(['base_fee' => 200, 'age_years' => 2, 'shelter_partner' => false]);

        $this->actingAs($user, 'sanctum')
            ->getJson("/api/v1/pets/{$pet->id}/fee-quote")
            ->assertOk()
            ->assertJsonPath('data.discount_type', 'loyalty')
            ->assertJsonPath('data.final_fee', 170);
    }

    #[Test]
    public function it_adopts_an_available_pet_and_records_the_fee(): void
    {
        $user = User::factory()->create(['adoptions_count' => 0]);
        $pet  = Pet::factory()->create(['base_fee' => 150, 'status' => PetStatus::Available->value]);

        $this->actingAs($user, 'sanctum')
            ->postJson("/api/v1/pets/{$pet->id}/adopt")
            ->assertCreated()
            ->assertJsonPath('data.final_fee', 150)
            ->assertJsonPath('data.pet.id', $pet->id);

        $this->assertSame(PetStatus::Adopted, $pet->fresh()->status);
        $this->assertSame(1, $user->fresh()->adoptions_count);
        $this->assertDatabaseHas('adoptions', ['user_id' => $user->id, 'pet_id' => $pet->id]);
    }

    #[Test]
    public function adopt_applies_loyalty_from_prior_count_then_increments(): void
    {
        // Guards the CRITICAL invariant: the fee is quoted from the adopter's
        // PRIOR adoptions_count (3 => loyalty), and the count is incremented
        // only after the record is written.
        $user = User::factory()->create(['adoptions_count' => 3]);
        $pet  = Pet::factory()->create(['base_fee' => 200, 'age_years' => 2, 'shelter_partner' => false]);

        $this->actingAs($user, 'sanctum')
            ->postJson("/api/v1/pets/{$pet->id}/adopt")
            ->assertCreated()
            ->assertJsonPath('data.discount_type', 'loyalty')
            ->assertJsonPath('data.final_fee', 170);

        $this->assertSame(4, $user->fresh()->adoptions_count);
        $this->assertDatabaseHas('adoptions', [
            'user_id'       => $user->id,
            'pet_id'        => $pet->id,
            'discount_type' => 'loyalty',
            'final_fee'     => 170,
        ]);
    }

    #[Test]
    public function adopting_an_already_adopted_pet_returns_409(): void
    {
        $user = User::factory()->create();
        $pet  = Pet::factory()->adopted()->create();

        $this->actingAs($user, 'sanctum')
            ->postJson("/api/v1/pets/{$pet->id}/adopt")
            ->assertStatus(409)
            ->assertHeader('Content-Type', 'application/problem+json')
            ->assertJsonStructure(['type', 'title', 'status', 'detail']);
    }

    #[Test]
    public function adopt_requires_authentication(): void
    {
        $pet = Pet::factory()->create();
        $this->postJson("/api/v1/pets/{$pet->id}/adopt")->assertUnauthorized();
    }

    #[Test]
    public function it_lists_the_users_adoption_history(): void
    {
        $user = User::factory()->create();
        $pet  = Pet::factory()->create(['status' => PetStatus::Available->value]);

        $this->actingAs($user, 'sanctum')->postJson("/api/v1/pets/{$pet->id}/adopt")->assertCreated();

        $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/me/adoptions')
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.pet.id', $pet->id);
    }
}
