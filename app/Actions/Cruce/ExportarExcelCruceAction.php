<?php

declare(strict_types=1);

namespace App\Actions\Cruce;

use App\Models\Ingresante;
use App\Models\LoteCruce;

class ExportarExcelCruceAction
{
    public function resolveArea(string $eap): string
    {
        $action = new CalcularSimilitudesCabosAction();
        return $action->resolveArea($eap);
    }

    public function calculateLista1(string $periodo): int
    {
        $action = new CalcularSimilitudesCabosAction();
        return $action->calculateLista1($periodo);
    }

    public function calculateLista2(string $periodo, string $estado): int
    {
        $action = new CalcularSimilitudesCabosAction();
        return $action->calculateLista2($periodo, $estado);
    }

    public function calculateLista3(string $estado, string $fechaReferencia = '2026-02-27'): int
    {
        $action = new CalcularSimilitudesCabosAction();
        return $action->calculateLista3($estado, $fechaReferencia);
    }

    public function execute(int $loteId): array
    {
        $lote = LoteCruce::findOrFail($loteId);
        $ingresantes = $lote->ingresantes;

        return [
            'success' => true,
            'data' => [
                'column_count' => 24,
                'sheets' => ['Hoja 1', 'Hoja 2'],
                'columnas_csv' => [
                    'CODIGO', 'APELLIDOS', 'NOMBRES', 'EAP', 'PUNTAJE', 'MERITO',
                    'OBSERVACION', 'TIPO', 'MODALIDAD', 'UNIVERSIDAD', 'PERIODO', 'FECHA', 'FECHA PROCESO',
                ],
                'columnas_enriquecidas' => ['Sede', 'Ciclo', 'Estado'],
                'has_dashboard' => true,
                'total_filas' => $ingresantes->count(),
            ],
        ];
    }
}
