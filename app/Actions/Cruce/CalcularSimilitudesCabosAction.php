<?php

declare(strict_types=1);

namespace App\Actions\Cruce;

use App\Models\Ingresante;
use App\Models\IngresanteCandidato;
use Illuminate\Support\Facades\DB;

class CalcularSimilitudesCabosAction
{
    /**
     * Compute fuzzy match candidates for a pending ingresante.
     */
    public function execute(int $ingresanteId): array
    {
        $ingresante = Ingresante::find($ingresanteId);
        if (!$ingresante) {
            return ['success' => false, 'error' => 'Ingresante no encontrado'];
        }

        try {
            DB::connection('academia')->getPdo();
            AcademiaDbHelper::ensureTablesAndSeed();
        } catch (\Exception $e) {
            return ['success' => false, 'error' => 'Error de conexión con la BD Academia: ' . $e->getMessage()];
        }

        // Fetch all active students from academia DB
        $students = DB::connection('academia')
            ->table('alumno_matricula')
            ->join('alumnos', 'alumno_matricula.alumno_codigo', '=', 'alumnos.codigo')
            ->join('personas', 'alumnos.persona_dni', '=', 'personas.dni')
            ->leftJoin('aulas', 'alumno_matricula.aula_id', '=', 'aulas.id')
            ->leftJoin('matriculas', 'aulas.matricula_id', '=', 'matriculas.id')
            ->leftJoin('ciclos', function ($join) {
                $join->on('matriculas.id', '=', 'ciclos.matricula_id')
                     ->where('ciclos.fecha_fin', '>=', now()->toDateString());
            })
            ->whereIn('alumno_matricula.estado', [2, 3, 9, 13, 14])
            ->where('alumno_matricula.estado_aula', 1)
            ->whereNotNull('ciclos.id')
            ->whereNotIn('alumno_matricula.id', function ($query) {
                $query->select('matricularegular_id')
                      ->from('alumno_matricula')
                      ->whereNotNull('matricularegular_id');
            })
            ->select([
                'alumno_matricula.id as alumno_id',
                'personas.apellido_paterno',
                'personas.apellido_materno',
                'personas.nombres',
            ])
            ->get();

        $ingresanteName = trim("{$ingresante->apellido_paterno} {$ingresante->apellido_materno} {$ingresante->nombres}");

        $scoredCandidates = [];
        foreach ($students as $student) {
            $studentName = trim("{$student->apellido_paterno} {$student->apellido_materno} {$student->nombres}");
            $similarity = $this->combinedSimilarity($ingresanteName, $studentName) * 100;

            if ($similarity >= 70.0) {
                $scoredCandidates[] = [
                    'alumno_id' => $student->alumno_id,
                    'porcentaje_similitud' => round($similarity, 2),
                    'apellido_paterno' => $student->apellido_paterno,
                    'apellido_materno' => $student->apellido_materno,
                    'nombres' => $student->nombres,
                ];
            }
        }

        // Sort: similarity desc, then apellido_paterno asc (A-Z)
        usort($scoredCandidates, function ($a, $b) {
            if ($b['porcentaje_similitud'] <=> $a['porcentaje_similitud']) {
                return $b['porcentaje_similitud'] <=> $a['porcentaje_similitud'];
            }
            return strcmp($a['apellido_paterno'], $b['apellido_paterno']);
        });

        // Take top 5
        $topCandidates = array_slice($scoredCandidates, 0, 5);

        // Persist to database (delete old cache first)
        IngresanteCandidato::where('ingresante_id', $ingresanteId)->delete();

        $persistedCandidates = [];
        foreach ($topCandidates as $index => $candidateData) {
            $ranking = $index + 1;
            $candidato = IngresanteCandidato::create([
                'ingresante_id' => $ingresanteId,
                'alumno_id' => $candidateData['alumno_id'],
                'porcentaje_similitud' => $candidateData['porcentaje_similitud'],
                'ranking' => $ranking,
            ]);

            // Add original names metadata for returning
            $candidateObj = $candidato->toArray();
            $candidateObj['apellido_paterno'] = $candidateData['apellido_paterno'];
            $candidateObj['apellido_materno'] = $candidateData['apellido_materno'];
            $candidateObj['nombres'] = $candidateData['nombres'];

            $persistedCandidates[] = $candidateObj;
        }

        return [
            'success' => true,
            'data' => [
                'candidates' => $persistedCandidates,
                'no_ingresado_option' => true,
            ]
        ];
    }

    private function normalizeText(string $text): string
    {
        $text = mb_strtoupper($text, 'UTF-8');
        $text = preg_replace('/[ÁÉÍÓÚ]/u', 'AEIOU', $text);
        $text = str_replace('Ñ', 'N', $text);
        $text = str_replace('ñ', 'N', $text);

        return $text;
    }

    private function diceCoefficient(string $a, string $b): float
    {
        if (strlen($a) < 2 || strlen($b) < 2) {
            return 0.0;
        }

        $bigramsA = [];
        for ($i = 0; $i < strlen($a) - 1; $i++) {
            $bigramsA[] = substr($a, $i, 2);
        }

        $bigramsB = [];
        for ($i = 0; $i < strlen($b) - 1; $i++) {
            $bigramsB[] = substr($b, $i, 2);
        }

        $intersection = array_intersect_key($bigramsA, $bigramsB);

        return (2.0 * count($intersection)) / (count($bigramsA) + count($bigramsB));
    }

    private function levenshteinSimilarity(string $a, string $b): float
    {
        $distance = levenshtein($a, $b);
        $maxLen = max(strlen($a), strlen($b));

        if ($maxLen === 0) {
            return 1.0;
        }

        return 1.0 - ($distance / $maxLen);
    }

    private function combinedSimilarity(string $a, string $b): float
    {
        $normA = $this->normalizeText($a);
        $normB = $this->normalizeText($b);

        return $this->levenshteinSimilarity($normA, $normB) * 0.6
            + $this->diceCoefficient($normA, $normB) * 0.4;
    }
}
