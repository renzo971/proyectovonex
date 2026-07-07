<?php

declare(strict_types=1);

namespace App\Actions\Cruce;

use App\Models\Ingresante;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class GuardarCruceConfirmadoAction
{
    /**
     * Estados de matrícula considerados activos para validación de cruce.
     * Debe coincidir con el filtro usado en CalcularSimilitudesCabosAction
     * y RealizarCruceExactoAction (MATRICULADO, PAGADO, SUSPENDIDO, STAND BY, FINALIZADO).
     */
    private const ESTADOS_ACTIVOS = [2, 3, 9, 13, 14];

    private const ALUMNO_INVALIDO_MENSAJE = 'El alumno seleccionado no existe en la base de datos.';

    private const ACADEMIA_CONEXION_ERROR_MENSAJE = 'No se pudo establecer conexión con la base de datos de la academia. Contacte al administrador del sistema.';

    /**
     * Confirm a match manually or mark as no match.
     */
    public function execute(int $ingresanteId, ?int $alumnoId, bool $marcarNoIngresado = false): array
    {
        $ingresante = Ingresante::find($ingresanteId);
        if (!$ingresante) {
            return ['success' => false, 'error' => 'Ingresante no encontrado'];
        }

        if (!$marcarNoIngresado) {
            $validacion = $this->validarAlumnoId($alumnoId);
            if (!$validacion['success']) {
                return $validacion;
            }
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

    /**
     * Validate that alumno_id references an existing, active matrícula in
     * the academia database (same active-matrícula filter used elsewhere
     * in the cruce pipeline). Returns a controller-ready result shape on
     * failure (success/error/http_status), matching ERR-006 (invalid
     * alumno_id) and ERR-003 (academia connection unavailable).
     */
    private function validarAlumnoId(?int $alumnoId): array
    {
        if (!$alumnoId) {
            return [
                'success' => false,
                'error' => self::ALUMNO_INVALIDO_MENSAJE,
                'http_status' => 404,
            ];
        }

        try {
            $existe = DB::connection('academia')
                ->table('alumno_matricula')
                ->where('id', $alumnoId)
                ->whereIn('estado', self::ESTADOS_ACTIVOS)
                ->where('estado_aula', 1)
                ->exists();
        } catch (\Exception $e) {
            Log::error('Fallo de validación de alumno_id contra academia: ' . $e->getMessage(), ['exception' => $e]);

            return [
                'success' => false,
                'error' => self::ACADEMIA_CONEXION_ERROR_MENSAJE,
                'http_status' => 500,
            ];
        }

        if (!$existe) {
            return [
                'success' => false,
                'error' => self::ALUMNO_INVALIDO_MENSAJE,
                'http_status' => 404,
            ];
        }

        return ['success' => true];
    }
}
