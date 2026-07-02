<?php

declare(strict_types=1);

namespace App\Actions\Cruce;

use App\Models\Ingresante;
use App\Models\IngresanteCandidato;
use App\Models\LoteCruce;
use Illuminate\Support\Facades\DB;

class GuardarCruceConfirmadoAction
{
    public function execute(int $ingresanteId, ?int $alumnoId = null): array
    {
        $ingresante = Ingresante::findOrFail($ingresanteId);

        if ($alumnoId !== null) {
            try {
                $exists = DB::connection('academia')
                    ->table('alumno_matricula')
                    ->where('id', $alumnoId)
                    ->exists();
            } catch (\Exception $e) {
                return [
                    'success' => false,
                    'error' => 'No se pudo verificar la existencia del alumno en la BD academia.',
                ];
            }

            if (!$exists) {
                return [
                    'success' => false,
                    'error' => 'El alumno seleccionado no existe en la base de datos.',
                    'http_status' => 404,
                ];
            }

            $candidato = IngresanteCandidato::where('ingresante_id', $ingresanteId)
                ->where('alumno_id', $alumnoId)
                ->first();

            $ingresante->update([
                'alumno_id' => $alumnoId,
                'estado_match' => 'confirmado_manual',
                'porcentaje_similitud' => $candidato?->porcentaje_similitud,
            ]);

            $lote = $ingresante->loteCruce;
            if ($lote) {
                $pendientes = $lote->ingresantes()
                    ->where('estado_match', 'pendiente')
                    ->count();
                $noIngresado = $lote->ingresantes()
                    ->where('estado_match', 'no_ingresado')
                    ->count();
                $lote->update([
                    'total_pendientes' => $pendientes,
                    'total_no_ingresado' => $noIngresado,
                ]);
            }

            return [
                'success' => true,
                'data' => [
                    'estado_match' => 'confirmado_manual',
                    'alumno_id' => $alumnoId,
                ],
            ];
        }

        $ingresante->update([
            'alumno_id' => null,
            'estado_match' => 'no_ingresado',
            'porcentaje_similitud' => null,
        ]);

        $lote = $ingresante->loteCruce;
        if ($lote) {
            $pendientes = $lote->ingresantes()
                ->where('estado_match', 'pendiente')
                ->count();
            $noIngresado = $lote->ingresantes()
                ->where('estado_match', 'no_ingresado')
                ->count();
            $lote->update([
                'total_pendientes' => $pendientes,
                'total_no_ingresado' => $noIngresado,
            ]);
        }

        return [
            'success' => true,
            'data' => [
                'estado_match' => 'no_ingresado',
                'alumno_id' => null,
            ],
        ];
    }
}
