<?php

declare(strict_types=1);

use App\Http\Controllers\Api\AdoptionController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DiscountController;
use App\Http\Controllers\Api\PetController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::post('/discount', [DiscountController::class, 'apply'])
        ->name('api.v1.discount.apply');

    Route::post('/auth/register', [AuthController::class, 'register'])->name('api.v1.auth.register');
    Route::post('/auth/login', [AuthController::class, 'login'])->name('api.v1.auth.login');

    Route::get('/pets', [PetController::class, 'index'])->name('api.v1.pets.index');
    Route::get('/pets/{pet}', [PetController::class, 'show'])->name('api.v1.pets.show');

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::get('/me', [AuthController::class, 'me'])->name('api.v1.me');

        Route::get('/pets/{pet}/fee-quote', [AdoptionController::class, 'quote'])->name('api.v1.pets.fee-quote');
        Route::post('/pets/{pet}/adopt', [AdoptionController::class, 'adopt'])->name('api.v1.pets.adopt');
        Route::get('/me/adoptions', [AdoptionController::class, 'history'])->name('api.v1.me.adoptions');
    });
});
