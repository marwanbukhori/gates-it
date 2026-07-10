<?php

declare(strict_types=1);

namespace Tests\Unit\Pet;

use App\Enums\PetStatus;
use App\Models\Pet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

final class PetModelTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_marks_a_pet_at_or_above_the_senior_age_as_senior(): void
    {
        config()->set('pawmise.senior.age_years', 8);

        $senior = Pet::factory()->create(['age_years' => 9]);
        $young  = Pet::factory()->create(['age_years' => 2]);

        $this->assertTrue($senior->is_senior);
        $this->assertFalse($young->is_senior);
    }

    #[Test]
    public function it_casts_status_to_the_enum(): void
    {
        $pet = Pet::factory()->create(['status' => 'available']);

        $this->assertSame(PetStatus::Available, $pet->status);
    }
}
