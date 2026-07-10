<?php

declare(strict_types=1);

namespace Tests\Unit\Adoption;

use App\Models\Adoption;
use App\Models\Pet;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

final class AdoptionModelTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_belongs_to_a_user_and_a_pet(): void
    {
        $user = User::factory()->create();
        $pet  = Pet::factory()->create();

        $adoption = Adoption::factory()->create([
            'user_id' => $user->id,
            'pet_id'  => $pet->id,
        ]);

        $this->assertTrue($adoption->user->is($user));
        $this->assertTrue($adoption->pet->is($pet));
    }

    #[Test]
    public function a_user_starts_with_zero_adoptions_count(): void
    {
        $this->assertSame(0, User::factory()->create()->adoptions_count);
    }
}
