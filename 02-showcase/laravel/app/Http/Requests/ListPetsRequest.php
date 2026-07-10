<?php

declare(strict_types=1);

namespace App\Http\Requests;

use App\Enums\PetStatus;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class ListPetsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'species' => ['nullable', 'string', 'max:50'],
            'size'    => ['nullable', 'string', Rule::in(['small', 'medium', 'large'])],
            'status'  => ['nullable', Rule::enum(PetStatus::class)],
            'senior'  => ['nullable', 'boolean'],
            'q'       => ['nullable', 'string', 'max:100'],
        ];
    }
}
