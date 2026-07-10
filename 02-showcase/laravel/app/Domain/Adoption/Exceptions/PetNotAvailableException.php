<?php

declare(strict_types=1);

namespace App\Domain\Adoption\Exceptions;

use App\Models\Pet;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use RuntimeException;
use Symfony\Component\HttpFoundation\Response;

final class PetNotAvailableException extends RuntimeException
{
    public function __construct(public readonly int $petId)
    {
        parent::__construct("Pet {$petId} is not available for adoption.");
    }

    public static function for(Pet $pet): self
    {
        return new self((int) $pet->id);
    }

    public function render(Request $request): JsonResponse
    {
        return response()->json(
            [
                'type'   => 'https://pawmise.local/errors/pet-not-available',
                'title'  => 'Pet not available',
                'status' => Response::HTTP_CONFLICT,
                'detail' => $this->getMessage(),
            ],
            Response::HTTP_CONFLICT,
            ['Content-Type' => 'application/problem+json'],
        );
    }
}
