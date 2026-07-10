<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Domain\Adoption\AdoptionFeeCalculator;
use App\Domain\Adoption\Exceptions\PetNotAvailableException;
use App\Enums\PetStatus;
use App\Http\Controllers\Controller;
use App\Http\Resources\AdoptionResource;
use App\Http\Resources\FeeBreakdownResource;
use App\Models\Adoption;
use App\Models\Pet;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

final class AdoptionController extends Controller
{
    public function __construct(private readonly AdoptionFeeCalculator $calculator)
    {
    }

    public function quote(Pet $pet, Request $request): FeeBreakdownResource
    {
        return new FeeBreakdownResource(
            $this->calculator->quote($pet, $request->user()),
        );
    }

    public function adopt(Pet $pet, Request $request): JsonResponse
    {
        $user = $request->user();

        $adoption = DB::transaction(function () use ($pet, $user): Adoption {
            $locked = Pet::query()->whereKey($pet->id)->lockForUpdate()->firstOrFail();

            if ($locked->status !== PetStatus::Available) {
                throw PetNotAvailableException::for($locked);
            }

            $breakdown = $this->calculator->quote($locked, $user);

            $adoption = Adoption::create([
                'user_id'         => $user->id,
                'pet_id'          => $locked->id,
                'base_fee'        => $breakdown->baseFee,
                'discount_type'   => $breakdown->discountType?->value,
                'discount_amount' => $breakdown->discountAmount,
                'final_fee'       => $breakdown->finalFee,
                'adopted_at'      => now(),
            ]);

            $locked->update(['status' => PetStatus::Adopted]);
            $user->increment('adoptions_count');

            return $adoption;
        });

        return (new AdoptionResource($adoption->load('pet')))
            ->response()
            ->setStatusCode(Response::HTTP_CREATED);
    }

    public function history(Request $request): AnonymousResourceCollection
    {
        $adoptions = $request->user()
            ->adoptions()
            ->with('pet')
            ->latest('adopted_at')
            ->paginate(15);

        return AdoptionResource::collection($adoptions);
    }
}
