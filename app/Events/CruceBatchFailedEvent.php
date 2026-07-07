<?php

declare(strict_types=1);

namespace App\Events;

use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;
use Throwable;

class CruceBatchFailedEvent
{
    use Dispatchable, SerializesModels;

    public int $loteId;
    public string $error;
    public ?Throwable $exception;

    public function __construct(int $loteId, string $error, ?Throwable $exception = null)
    {
        $this->loteId = $loteId;
        $this->error = $error;
        $this->exception = $exception;
    }
}
