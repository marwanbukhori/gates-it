<?php

declare(strict_types=1);

namespace App\Domain\Discount\Exceptions;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use RuntimeException;
use Symfony\Component\HttpFoundation\Response;

final class InvalidDiscountException extends RuntimeException
{
    public function __construct(
        string $message,
        public readonly string $field,
        public readonly mixed $value,
    ) {
        parent::__construct($message);
    }

    public static function percentageOutOfRange(float $value): self
    {
        return new self(
            "Percentage discount must be between 0 and 100, got {$value}.",
            field: 'value',
            value: $value,
        );
    }

    public static function fixedAmountExceedsPrice(float $amount, float $price): self
    {
        return new self(
            "Fixed discount amount ({$amount}) must not exceed the original price ({$price}).",
            field: 'value',
            value: $amount,
        );
    }

    /**
     * Render the exception as an RFC 7807-style problem+json response.
     */
    public function render(Request $request): JsonResponse
    {
        return response()->json(
            [
                'type'   => 'https://gates.local/errors/invalid-discount',
                'title'  => 'Invalid discount input',
                'status' => Response::HTTP_BAD_REQUEST,
                'detail' => $this->getMessage(),
                'errors' => [
                    $this->field => [$this->getMessage()],
                ],
            ],
            Response::HTTP_BAD_REQUEST,
            ['Content-Type' => 'application/problem+json'],
        );
    }
}
