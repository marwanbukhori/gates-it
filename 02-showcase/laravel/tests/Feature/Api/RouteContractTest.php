<?php

declare(strict_types=1);

namespace Tests\Feature\Api;

use Illuminate\Support\Facades\Route;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

final class RouteContractTest extends TestCase
{
    #[Test]
    public function all_documented_v1_routes_are_registered(): void
    {
        $expected = [
            'api.v1.discount.apply',
            'api.v1.auth.register',
            'api.v1.auth.login',
            'api.v1.me',
            'api.v1.pets.index',
            'api.v1.pets.show',
            'api.v1.pets.fee-quote',
            'api.v1.pets.adopt',
            'api.v1.me.adoptions',
        ];

        $registered = collect(Route::getRoutes()->getRoutesByName())->keys();

        foreach ($expected as $name) {
            $this->assertTrue($registered->contains($name), "Missing route: {$name}");
        }
    }
}
