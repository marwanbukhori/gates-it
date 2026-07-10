<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pets', function (Blueprint $table): void {
            $table->id();
            $table->string('name');
            $table->string('species');
            $table->string('breed')->nullable();
            $table->unsignedSmallInteger('age_years');
            $table->string('size');   // small | medium | large
            $table->string('gender'); // male | female
            $table->text('description')->nullable();
            $table->string('image_url')->nullable();
            $table->decimal('base_fee', 8, 2);
            $table->string('status')->default('available');
            $table->boolean('shelter_partner')->default(false);
            $table->timestamps();

            $table->index(['status', 'species', 'size']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pets');
    }
};
