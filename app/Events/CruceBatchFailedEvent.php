<?php

declare(strict_types=1);

namespace App\Events;

use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;
use Throwable;

class CruceBatchFailedEvent
{
    use Dispatchable, SerializesModels;

    public function __construct(
        public int $loteId,
        public string $error,
        public ?Throwable $exception = null,
    ) {}
}
