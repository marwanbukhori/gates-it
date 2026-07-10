<?php

declare(strict_types=1);

namespace App\Http\Requests;

use App\Domain\Discount\Enums\DiscountStrategyType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

final class ApplyDiscountRequest extends FormRequest
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
            'price'    => ['required', 'numeric', 'gt:0'],
            'strategy' => ['required', 'string', Rule::enum(DiscountStrategyType::class)],
            'value'    => ['nullable', 'numeric'],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $strategy = DiscountStrategyType::tryFrom((string) $this->input('strategy'));
            if ($strategy === null) {
                return;
            }

            if ($strategy->requiresValue() && $this->input('value') === null) {
                $validator->errors()->add(
                    'value',
                    "The 'value' field is required for the '{$strategy->value}' strategy.",
                );
            }
        });
    }

    public function strategy(): DiscountStrategyType
    {
        return DiscountStrategyType::from((string) $this->validated('strategy'));
    }

    public function price(): float
    {
        return (float) $this->validated('price');
    }

    public function value(): ?float
    {
        $value = $this->validated('value');

        return $value === null ? null : (float) $value;
    }
}
