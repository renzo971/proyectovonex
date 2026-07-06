<?php

declare(strict_types=1);

namespace App\Actions\Cruce;

use App\Models\Ingresante;

class GuardarCruceConfirmadoAction
{
    /**
     * Confirm a match manually or mark as no match.
     */
    public function execute(int $ingresanteId, ?int $alumnoId, bool $marcarNoIngresado = false): array
    {
        $ingresante = Ingresante::find($ingresanteId);
        if (!$ingresante) {
            return ['success' => false, 'error' => 'Ingresante no encontrado'];
        }

        $lote = $ingresante->loteCruce;

        if ($marcarNoIngresado) {
            $ingresante->update([
                'estado_match' => 'no_ingresado',
                'alumno_id' => null,
            ]);

            if ($lote) {
                $lote->decrement('total_pendientes');
                $lote->increment('total_no_ingresado');
            }
        } else {
            $ingresante->update([
                'estado_match' => 'confirmado_manual',
                'alumno_id' => $alumnoId,
            ]);

            if ($lote) {
                $lote->decrement('total_pendientes');
            }
        }

        return [
            'success' => true,
            'data' => $ingresante,
        ];
    }
}
