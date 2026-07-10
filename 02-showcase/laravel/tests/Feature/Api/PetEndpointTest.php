<?php

declare(strict_types=1);

namespace Tests\Feature\Api;

use App\Models\Pet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

final class PetEndpointTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_lists_pets_with_pagination_metadata(): void
    {
        Pet::factory()->count(3)->create();

        $this->getJson('/api/v1/pets')
            ->assertOk()
            ->assertJsonStructure([
                'data' => [['id', 'name', 'species', 'base_fee', 'status', 'is_senior', 'currency']],
                'meta' => ['current_page', 'total'],
            ])
            ->assertJsonPath('meta.total', 3);
    }

    #[Test]
    public function it_filters_by_species(): void
    {
        Pet::factory()->create(['species' => 'dog']);
        Pet::factory()->create(['species' => 'cat']);

        $this->getJson('/api/v1/pets?species=cat')
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.species', 'cat');
    }

    #[Test]
    public function it_filters_by_senior_flag(): void
    {
        config()->set('pawmise.senior.age_years', 8);
        Pet::factory()->create(['age_years' => 10]);
        Pet::factory()->create(['age_years' => 2]);

        $this->getJson('/api/v1/pets?senior=1')
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.is_senior', true);
    }

    #[Test]
    public function it_searches_by_name(): void
    {
        Pet::factory()->create(['name' => 'Rex']);
        Pet::factory()->create(['name' => 'Bella']);

        $this->getJson('/api/v1/pets?q=Rex')
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.name', 'Rex');
    }

    #[Test]
    public function it_shows_a_single_pet(): void
    {
        $pet = Pet::factory()->create(['name' => 'Rex']);

        $this->getJson("/api/v1/pets/{$pet->id}")
            ->assertOk()
            ->assertJsonPath('data.id', $pet->id)
            ->assertJsonPath('data.name', 'Rex');
    }

    #[Test]
    public function it_returns_404_for_a_missing_pet(): void
    {
        $this->getJson('/api/v1/pets/999999')->assertNotFound();
    }
}
