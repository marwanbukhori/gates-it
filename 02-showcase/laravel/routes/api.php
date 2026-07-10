<?php

declare(strict_types=1);

use App\Http\Controllers\Api\DiscountController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::post('/discount', [DiscountController::class, 'apply'])
        ->name('api.v1.discount.apply');
});
