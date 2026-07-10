<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\ListPetsRequest;
use App\Http\Resources\PetResource;
use App\Models\Pet;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

final class PetController extends Controller
{
    public function index(ListPetsRequest $request): AnonymousResourceCollection
    {
        $seniorAge = (int) config('pawmise.senior.age_years');

        $pets = Pet::query()
            ->when($request->validated('species'), fn ($q, $v) => $q->where('species', $v))
            ->when($request->validated('size'), fn ($q, $v) => $q->where('size', $v))
            ->when($request->validated('status'), fn ($q, $v) => $q->where('status', $v))
            ->when($request->validated('q'), fn ($q, $v) => $q->where('name', 'like', "%{$v}%"))
            ->when($request->boolean('senior'), fn ($q) => $q->where('age_years', '>=', $seniorAge))
            ->orderByDesc('id')
            ->paginate(15);

        return PetResource::collection($pets);
    }

    public function show(Pet $pet): PetResource
    {
        return new PetResource($pet);
    }
}
