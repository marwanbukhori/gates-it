<?php

declare(strict_types=1);

namespace App\Enums;

enum PetStatus: string
{
    case Available = 'available';
    case Pending   = 'pending';
    case Adopted   = 'adopted';
}
