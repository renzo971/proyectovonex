<?php

declare(strict_types=1);

namespace App\Actions\Cruce;

use App\Models\Ingresante;
use App\Models\IngresanteCandidato;
use Illuminate\Support\Facades\DB;

class CalcularSimilitudesCabosAction
{
    private NormalizarTextoAction $normalizador;

    public function __construct(?NormalizarTextoAction $normalizador = null)
    {
        $this->normalizador = $normalizador ?? new NormalizarTextoAction();
    }

    public function execute(int $ingresanteId): array
    {
        $existing = IngresanteCandidato::where('ingresante_id', $ingresanteId)
            ->orderBy('ranking')
            ->get();

        if ($existing->isNotEmpty()) {
            $alumnoIds = $existing->pluck('alumno_id')->toArray();

            $nombres = [];
            if (!empty($alumnoIds)) {
                try {
                    $rows = DB::connection('academia')->select("
                        SELECT am.id, p.apellido_paterno, p.apellido_materno, p.nombres
                        FROM alumno_matricula am
                        JOIN alumnos a ON am.alumno_codigo = a.codigo
                        JOIN personas p ON a.persona_dni = p.dni
                        WHERE am.id IN (" . implode(',', $alumnoIds) . ")
                    ");
                    foreach ($rows as $row) {
                        $nombres[(int) $row->id] = $row;
                    }
                } catch (\Exception $e) {
                    // silent
                }
            }

            $candidates = $existing->map(function ($c) use ($nombres) {
                $data = $nombres[$c->alumno_id] ?? null;
                return [
                    'alumno_id' => $c->alumno_id,
                    'apellido_paterno' => $data->apellido_paterno ?? '',
                    'apellido_materno' => $data->apellido_materno ?? '',
                    'nombres' => $data->nombres ?? '',
                    'nombre_completo' => $data ? trim("{$data->apellido_paterno} {$data->apellido_materno}, {$data->nombres}") : "ID {$c->alumno_id}",
                    'porcentaje_similitud' => (float) $c->porcentaje_similitud,
                    'ranking' => (int) $c->ranking,
                ];
            })->toArray();

            return [
                'success' => true,
                'data' => [
                    'candidates' => $candidates,
                    'no_ingresado_option' => empty($candidates),
                ],
            ];
        }

        $ingresante = Ingresante::findOrFail($ingresanteId);

        $ingresanteFullName = $this->normalizador->execute(
            $ingresante->apellido_paterno . ' ' .
            $ingresante->apellido_materno . ' ' .
            $ingresante->nombres
        );

        try {
            $alumnos = DB::connection('academia')->select("
                SELECT am.id, p.apellido_paterno, p.apellido_materno, p.nombres
                FROM alumno_matricula am
                JOIN alumnos a ON am.alumno_codigo = a.codigo
                JOIN personas p ON a.persona_dni = p.dni
                WHERE am.estado IN (2, 3, 9, 13, 14)
                  AND am.estado_aula = 1
            ");
        } catch (\Exception $e) {
            return [
                'success' => false,
                'error' => 'Error de conexión con la BD academia.',
                'data' => ['candidates' => [], 'no_ingresado_option' => true],
            ];
        }

        $normPaterno = $this->normalizador->execute($ingresante->apellido_paterno ?? '');
        $initial = $normPaterno !== '' ? $normPaterno[0] : '';
        
        $lenA = strlen($ingresanteFullName);
        $bigramsAHash = [];
        for ($i = 0; $i < $lenA - 1; $i++) {
            $bg = $ingresanteFullName[$i] . $ingresanteFullName[$i+1];
            if (!isset($bigramsAHash[$bg])) {
                $bigramsAHash[$bg] = 0;
            }
            $bigramsAHash[$bg]++;
        }
        $countA = max(0, $lenA - 1);
        
        $scored = [];

        foreach ($alumnos as $alumno) {
            $aluNormPaterno = $this->normalizador->execute($alumno->apellido_paterno ?? '');
            
            if ($initial !== '' && ($aluNormPaterno === '' || $aluNormPaterno[0] !== $initial)) {
                continue;
            }
            
            $aluNormMaterno = $this->normalizador->execute($alumno->apellido_materno ?? '');
            $aluNormNombres = $this->normalizador->execute($alumno->nombres ?? '');
            $alumnoFullName = trim($aluNormPaterno . ' ' . $aluNormMaterno . ' ' . $aluNormNombres);
            
            $lenB = strlen($alumnoFullName);
            $bigramsBHash = [];
            for ($i = 0; $i < $lenB - 1; $i++) {
                $bg = $alumnoFullName[$i] . $alumnoFullName[$i+1];
                if (!isset($bigramsBHash[$bg])) {
                    $bigramsBHash[$bg] = 0;
                }
                $bigramsBHash[$bg]++;
            }
            $countB = max(0, $lenB - 1);
            
            $common = 0;
            if ($countA > 0 && $countB > 0) {
                foreach ($bigramsAHash as $bg => $count) {
                    if (isset($bigramsBHash[$bg])) {
                        $common += min($count, $bigramsBHash[$bg]);
                    }
                }
            }
            
            $diceCoeff = ($countA + $countB) > 0 ? (2.0 * $common) / ($countA + $countB) : 0.0;
            
            if ($diceCoeff < 0.25) {
                continue;
            }
            
            if (levenshtein($normPaterno, $aluNormPaterno) > 4) {
                continue;
            }
            
            $levDistance = levenshtein($ingresanteFullName, $alumnoFullName);
            $maxLen = max($lenA, $lenB);
            $levSimilarity = $maxLen === 0 ? 1.0 : 1.0 - ($levDistance / $maxLen);
            
            $similarity = ($levSimilarity * 0.6 + $diceCoeff * 0.4) * 100;

            if ($similarity >= 70.0) {
                $scored[] = [
                    'alumno_id' => (int) $alumno->id,
                    'porcentaje_similitud' => round($similarity, 2),
                    'apellido_paterno' => $aluNormPaterno,
                ];
            }
        }

        usort($scored, function ($a, $b) {
            if ($b['porcentaje_similitud'] !== $a['porcentaje_similitud']) {
                return $b['porcentaje_similitud'] <=> $a['porcentaje_similitud'];
            }
            return strcmp($a['apellido_paterno'], $b['apellido_paterno']);
        });

        $topCandidates = array_slice($scored, 0, 5);

        $data = [];
        foreach ($topCandidates as $idx => $candidate) {
            IngresanteCandidato::create([
                'ingresante_id' => $ingresanteId,
                'alumno_id' => $candidate['alumno_id'],
                'porcentaje_similitud' => $candidate['porcentaje_similitud'],
                'ranking' => $idx + 1,
            ]);

            $data[] = [
                'alumno_id' => $candidate['alumno_id'],
                'apellido_paterno' => $candidate['apellido_paterno'] ?? '',
                'apellido_materno' => $candidate['apellido_materno'] ?? '',
                'nombres' => $candidate['nombres'] ?? '',
                'nombre_completo' => trim(($candidate['apellido_paterno'] ?? '') . ' ' . ($candidate['apellido_materno'] ?? '') . ', ' . ($candidate['nombres'] ?? '')),
                'porcentaje_similitud' => $candidate['porcentaje_similitud'],
                'ranking' => $idx + 1,
            ];
        }

        return [
            'success' => true,
            'data' => [
                'candidates' => $data,
                'no_ingresado_option' => empty($data),
            ],
        ];
    }

    public function resolveArea(string $eap): string
    {
        $upper = mb_strtoupper($eap);

        $areaA = ['MEDICINA', 'OBSTETRICIA', 'ENFERMERIA', 'TECNOLOGIA MEDICA', 'ODONTOLOGIA', 'FARMACIA', 'VETERINARIA', 'PSICOLOGIA'];
        foreach ($areaA as $keyword) {
            if (str_contains($upper, $keyword)) {
                return 'Area A';
            }
        }

        $areaB = ['QUIMICA', 'BIOLOGICAS', 'FISICA', 'MATEMATICA', 'ESTADISTICA'];
        foreach ($areaB as $keyword) {
            if (str_contains($upper, $keyword)) {
                return 'Area B';
            }
        }

        $areaC = ['INGENIERIA', 'SOFTWARE', 'SISTEMAS', 'INDUSTRIAL', 'CIVIL'];
        foreach ($areaC as $keyword) {
            if (str_contains($upper, $keyword)) {
                return 'Area C';
            }
        }

        $areaD = ['ADMINISTRACION', 'NEGOCIOS', 'CONTABILIDAD', 'ECONOMIA'];
        foreach ($areaD as $keyword) {
            if (str_contains($upper, $keyword)) {
                return 'Area D';
            }
        }

        $areaE = ['DERECHO', 'POLITICA', 'LITERATURA', 'FILOSOFIA', 'COMUNICACION', 'ARTE', 'ARQUEOLOGIA', 'EDUCACION', 'HISTORIA', 'TRABAJO SOCIAL'];
        foreach ($areaE as $keyword) {
            if (str_contains($upper, $keyword)) {
                return 'Area E';
            }
        }

        return '';
    }

    public function calculateLista1(string $periodo): int
    {
        $normalized = $this->normalizador->execute($periodo);

        if (preg_match('/VERANO\s+20(2[4-9]|[3-9]\d)/', $normalized)) {
            return 1;
        }
        if (preg_match('/REPASO\s+20(2[4-9]|[3-9]\d)/', $normalized)) {
            return 1;
        }

        return 0;
    }

    public function calculateLista2(string $periodo, string $estado): int
    {
        $normalizedPeriodo = $this->normalizador->execute($periodo);
        $normalizedEstado = $this->normalizador->execute($estado);

        $allowlistPeriodos = [
            'VERANO 2026',
            'REPASO 2026',
            'OCTUBRE 2025',
        ];

        foreach ($allowlistPeriodos as $p) {
            if (str_contains($normalizedPeriodo, $p)) {
                return 1;
            }
        }

        return 0;
    }

    public function calculateLista3(string $estado, string $fechaReferencia = '2026-02-27'): int
    {
        $activeStates = ['MATRICULADO', 'PAGADO', 'FINALIZADO'];
        $normalizedEstado = $this->normalizador->execute($estado);

        return in_array($normalizedEstado, $activeStates, true) ? 1 : 0;
    }
}
