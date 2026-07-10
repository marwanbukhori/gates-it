<?php

declare(strict_types=1);

namespace App\Providers;

use App\Domain\Discount\DiscountStrategyFactory;
use Illuminate\Support\ServiceProvider;

final class DiscountServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton(DiscountStrategyFactory::class);
    }
}
