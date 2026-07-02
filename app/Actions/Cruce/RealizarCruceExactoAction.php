<?php

declare(strict_types=1);

namespace App\Actions\Cruce;

use App\Models\Ingresante;
use App\Models\LoteCruce;
use Illuminate\Support\Facades\DB;

class RealizarCruceExactoAction
{
    private NormalizarTextoAction $normalizador;

    private const ESTADOS_ACTIVOS = [2, 3, 9, 13, 14];

    public function __construct(?NormalizarTextoAction $normalizador = null)
    {
        $this->normalizador = $normalizador ?? new NormalizarTextoAction();
    }

    public function execute(int $ingresanteId): array
    {
        try {
            DB::connection('academia')->select('SELECT 1');
        } catch (\Exception $e) {
            $ingresante = Ingresante::find($ingresanteId);
            if ($ingresante) {
                $lote = $ingresante->loteCruce;
                if ($lote) {
                    $lote->update(['estado' => 'paused']);
                }
            }

            return [
                'success' => false,
                'error' => 'Error de conexión con la BD academia.',
            ];
        }

        $ingresante = Ingresante::findOrFail($ingresanteId);

        $alumnosIndex = $this->getActiveAlumnos();

        $matched = $this->findMatchByName($ingresante, $alumnosIndex['alumnos'], $alumnosIndex['by_name']);

        if ($matched) {
            $ingresante->updateQuietly([
                'alumno_id' => $matched['id'],
                'estado_match' => 'confirmado_automatico',
                'porcentaje_similitud' => 100.00,
            ]);

            $lote = $ingresante->loteCruce;
            if ($lote) {
                $lote->increment('total_match_exacto');
            }

            $nombreCompleto = ($matched['apellido_paterno'] ?? '') . ' ' .
                ($matched['apellido_materno'] ?? '') . ' ' .
                ($matched['nombres'] ?? '');

            return [
                'success' => true,
                'data' => [
                    'estado_match' => 'confirmado_automatico',
                    'alumno_id' => $matched['id'],
                    'alumno_nombre_completo' => trim($nombreCompleto),
                ],
            ];
        }

        $ingresante->update([
            'estado_match' => 'pendiente',
        ]);

        return [
            'success' => true,
            'data' => [
                'estado_match' => 'pendiente',
                'alumno_id' => null,
            ],
        ];
    }

    public function executeBatch(LoteCruce $lote, ?array $alumnosIndex = null): array
    {
        try {
            DB::connection('academia')->select('SELECT 1');
        } catch (\Exception $e) {
            $lote->update(['estado' => 'paused']);
            return [
                'success' => false,
                'error' => 'Error de conexión con la BD academia.',
            ];
        }

        if ($alumnosIndex === null) {
            $alumnosIndex = $this->getActiveAlumnos();
        }

        $ingresantes = $lote->ingresantes()
            ->where('estado_match', 'pendiente')
            ->get();

        $alumnos = $alumnosIndex['alumnos'];
        $byName = $alumnosIndex['by_name'];

        $matchCount = 0;

        foreach ($ingresantes as $ingresante) {
            $matched = $this->findMatchByName($ingresante, $alumnos, $byName);

            if ($matched) {
                $ingresante->updateQuietly([
                    'alumno_id' => $matched['id'],
                    'estado_match' => 'confirmado_automatico',
                    'porcentaje_similitud' => 100.00,
                ]);
                $matchCount++;
            }
        }

        $lote->update([
            'total_match_exacto' => $matchCount,
        ]);

        return [
            'success' => true,
            'data' => [
                'total_matched' => $matchCount,
            ],
        ];
    }

    private function findMatchByName(Ingresante $ingresante, array $alumnos, array $byName): ?array
    {
        $normalizedPaterno = $this->normalizador->execute($ingresante->apellido_paterno);
        $normalizedMaterno = $this->normalizador->execute($ingresante->apellido_materno);
        $normalizedNombres = $this->normalizador->execute($ingresante->nombres);

        $key = $normalizedPaterno . '|' . $normalizedMaterno;
        $indices = $byName[$key] ?? [];

        if (empty($indices)) {
            return null;
        }

        $nombreTokens = explode(' ', $normalizedNombres);

        foreach ($indices as $idx) {
            $candidate = $alumnos[$idx];
            $candidateNombres = $this->normalizador->execute($candidate['nombres']);
            $candidateTokens = explode(' ', $candidateNombres);

            foreach ($nombreTokens as $nameToken) {
                if (in_array($nameToken, $candidateTokens, true)) {
                    return $candidate;
                }
            }
        }

        return null;
    }

    public function getActiveAlumnos(): array
    {
        $estados = implode(',', self::ESTADOS_ACTIVOS);

        $rows = DB::connection('academia')->select("
            SELECT am.id, p.apellido_paterno, p.apellido_materno, p.nombres, am.estado
            FROM alumno_matricula am
            JOIN alumnos a ON am.alumno_codigo = a.codigo
            JOIN personas p ON a.persona_dni = p.dni
            WHERE am.estado IN ({$estados})
              AND am.estado_aula = 1
        ");

        $alumnos = [];
        $byName = [];

        foreach ($rows as $row) {
            $idx = count($alumnos);
            $alumnos[] = [
                'id' => (int) $row->id,
                'apellido_paterno' => $row->apellido_paterno,
                'apellido_materno' => $row->apellido_materno,
                'nombres' => $row->nombres,
                'estado' => (int) $row->estado,
            ];

            $nameKey = $this->normalizador->execute($row->apellido_paterno) . '|'
                     . $this->normalizador->execute($row->apellido_materno);
            $byName[$nameKey][] = $idx;
        }

        return ['alumnos' => $alumnos, 'by_name' => $byName];
    }
}
