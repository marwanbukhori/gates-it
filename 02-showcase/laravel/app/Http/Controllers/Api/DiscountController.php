<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Domain\Discount\DiscountService;
use App\Domain\Discount\DiscountStrategyFactory;
use App\Http\Controllers\Controller;
use App\Http\Requests\ApplyDiscountRequest;
use App\Http\Resources\DiscountedPriceResource;

final class DiscountController extends Controller
{
    public function __construct(
        private readonly DiscountStrategyFactory $factory,
    ) {
    }

    public function apply(ApplyDiscountRequest $request): DiscountedPriceResource
    {
        $strategy = $this->factory->make($request->strategy(), $request->value());
        $service  = new DiscountService($strategy);
        $final    = $service->applyDiscount($request->price());

        return new DiscountedPriceResource(
            originalPrice: $request->price(),
            finalPrice: $final,
            strategy: $request->strategy(),
        );
    }
}
