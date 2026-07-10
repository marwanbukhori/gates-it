<?php

declare(strict_types=1);

return [
    'currency' => 'MYR',

    // Repeat-adopter reward. Uses the existing LoyaltyDiscount strategy (15% off).
    'loyalty' => [
        'threshold'  => 3,     // prior completed adoptions required to qualify
        'percentage' => 15.0,  // documented for transparency; LoyaltyDiscount is fixed at 15%
    ],

    // Encourage senior-pet adoption.
    'senior' => [
        'age_years'  => 8,     // a pet is "senior" at or above this age
        'percentage' => 30.0,  // percent off the base adoption fee
    ],

    // Shelter-partner fee waiver (fixed amount off).
    'shelter_partner' => [
        'waiver' => 50.0,      // MYR off the base adoption fee
    ],
];
