<?php

declare(strict_types=1);

namespace Tests\Feature\Api;

use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

final class ApplyDiscountEndpointTest extends TestCase
{
    #[Test]
    public function it_applies_a_fixed_discount(): void
    {
        $this->postJson('/api/v1/discount', [
            'price'    => 200,
            'strategy' => 'fixed',
            'value'    => 50,
        ])
            ->assertOk()
            ->assertJson([
                'data' => [
                    'strategy'         => 'fixed',
                    'original_price'   => 200,
                    'final_price'      => 150,
                    'discount_amount'  => 50,
                    'discount_percent' => 25,
                ],
            ]);
    }

    #[Test]
    public function it_applies_a_percentage_discount(): void
    {
        $this->postJson('/api/v1/discount', [
            'price'    => 100,
            'strategy' => 'percentage',
            'value'    => 25,
        ])
            ->assertOk()
            ->assertJson([
                'data' => [
                    'strategy'         => 'percentage',
                    'final_price'      => 75,
                    'discount_percent' => 25,
                ],
            ]);
    }

    #[Test]
    public function it_applies_a_loyalty_discount(): void
    {
        $this->postJson('/api/v1/discount', [
            'price'    => 100,
            'strategy' => 'loyalty',
        ])
            ->assertOk()
            ->assertJsonPath('data.strategy', 'loyalty')
            ->assertJsonPath('data.final_price', 15);
    }

    #[Test]
    public function it_returns_400_for_percentage_greater_than_100(): void
    {
        $this->postJson('/api/v1/discount', [
            'price'    => 100,
            'strategy' => 'percentage',
            'value'    => 150,
        ])
            ->assertStatus(400)
            ->assertHeader('Content-Type', 'application/problem+json')
            ->assertJsonStructure(['type', 'title', 'status', 'detail', 'errors']);
    }

    #[Test]
    public function it_returns_400_for_fixed_amount_exceeding_price(): void
    {
        $this->postJson('/api/v1/discount', [
            'price'    => 100,
            'strategy' => 'fixed',
            'value'    => 150,
        ])
            ->assertStatus(400)
            ->assertJsonPath('errors.value.0', fn (string $msg) => str_contains($msg, 'must not exceed'));
    }

    #[Test]
    public function it_returns_422_for_missing_price(): void
    {
        $this->postJson('/api/v1/discount', [
            'strategy' => 'fixed',
            'value'    => 10,
        ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['price']);
    }

    #[Test]
    public function it_returns_422_for_unknown_strategy(): void
    {
        $this->postJson('/api/v1/discount', [
            'price'    => 100,
            'strategy' => 'nonsense',
            'value'    => 10,
        ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['strategy']);
    }

    #[Test]
    public function it_requires_value_when_strategy_needs_it(): void
    {
        $this->postJson('/api/v1/discount', [
            'price'    => 100,
            'strategy' => 'percentage',
        ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['value']);
    }
}
