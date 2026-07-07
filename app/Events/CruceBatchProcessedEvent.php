<?php

declare(strict_types=1);

namespace App\Events;

use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class CruceBatchProcessedEvent
{
    use Dispatchable, SerializesModels;

    public int $loteId;
    public int $totalRegistros;
    public int $totalIngresantes;
    public int $totalNoIngresantes;

    public function __construct(int $loteId, int $totalRegistros, int $totalIngresantes, int $totalNoIngresantes)
    {
        $this->loteId = $loteId;
        $this->totalRegistros = $totalRegistros;
        $this->totalIngresantes = $totalIngresantes;
        $this->totalNoIngresantes = $totalNoIngresantes;
    }
}
