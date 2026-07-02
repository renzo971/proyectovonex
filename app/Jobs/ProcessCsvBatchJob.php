<?php

declare(strict_types=1);

namespace App\Jobs;

use App\Actions\Cruce\NormalizarTextoAction;
use App\Actions\Cruce\ProcesarCargaCsvAction;
use App\Actions\Cruce\RealizarCruceExactoAction;
use App\Events\CruceBatchFailedEvent;
use App\Events\CruceBatchProcessedEvent;
use App\Models\IngresanteCandidato;
use App\Models\LoteCruce;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Throwable;

class ProcessCsvBatchJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $timeout = 7200;

    public string $filePath;
    public array $fechas;

    public function __construct(string $filePath, array $fechas = [])
    {
        $this->filePath = $filePath;
        $this->fechas = $fechas;
        $this->onQueue('cruce');
    }

    public function handle(
        ProcesarCargaCsvAction $procesarCarga,
        RealizarCruceExactoAction $realizarCruce,
    ): void {
        $jobStart = microtime(true);

        $currentLimit = ini_get('memory_limit');
        if ($currentLimit !== '-1') {
            ini_set('memory_limit', '512M');
        }

        $result = $procesarCarga->execute($this->filePath);
        if (!$result['success']) {
            return;
        }
        $parseTime = microtime(true) - $jobStart;

        $alumnosIndex = null;

        foreach ($result['data']['lotes'] as $loteInfo) {
            $lote = LoteCruce::find($loteInfo['id']);
            if (!$lote) {
                continue;
            }

            $loteStart = microtime(true);
            $lote->update(['started_at' => now()]);

            try {
                if ($alumnosIndex === null) {
                    $loadStart = microtime(true);
                    $alumnosIndex = $realizarCruce->getActiveAlumnos();
                    $loadTime = microtime(true) - $loadStart;
                } else {
                    $loadTime = 0;
                }
                $exactStart = microtime(true);

                $cruceResult = $realizarCruce->executeBatch($lote, $alumnosIndex);

                if (!$cruceResult['success']) {
                    $lote->update(['estado' => 'paused']);
                    CruceBatchFailedEvent::dispatch(
                        $lote->id,
                        $cruceResult['error'] ?? 'Error desconocido en el cruce exacto'
                    );
                    continue;
                }
                $exactTime = microtime(true) - $exactStart;

                $fuzzyStart = microtime(true);
                $this->computeFuzzyCandidates($lote, $alumnosIndex);
                $fuzzyTime = microtime(true) - $fuzzyStart;

                $lote->update([
                    'estado' => 'completed',
                    'completed_at' => now(),
                ]);

                $totalTime = microtime(true) - $loteStart;

                logger()->info('Timing lote {lote_id}', [
                    'lote_id' => $lote->id,
                    'fecha' => $lote->fecha_examen,
                    'total_rows' => $lote->total_registros,
                    'total_ingresantes' => $lote->total_ingresantes,
                    'fases' => [
                        'parse_csv' => round($parseTime, 2),
                        'cargar_alumnos_db' => round($loadTime, 2),
                        'exact_match' => round($exactTime, 2),
                        'fuzzy_match' => round($fuzzyTime, 2),
                        'total_lote' => round($totalTime, 2),
                    ],
                    'memoria_mb' => round(memory_get_peak_usage(true) / 1048576, 1),
                ]);

                CruceBatchProcessedEvent::dispatch(
                    $lote->id,
                    $lote->total_registros,
                    $lote->total_ingresantes,
                    $lote->total_no_ingresantes,
                );
            } catch (Throwable $e) {
                $lote->update(['estado' => 'error']);

                CruceBatchFailedEvent::dispatch(
                    $lote->id,
                    $e->getMessage(),
                    $e,
                );

                throw $e;
            }
        }

        $jobTotal = microtime(true) - $jobStart;
        logger()->info('Timing job completo', [
            'filePath' => $this->filePath,
            'fechas' => $this->fechas,
            'total_segundos' => round($jobTotal, 2),
            'memoria_pico_mb' => round(memory_get_peak_usage(true) / 1048576, 1),
        ]);
    }

    public function failed(?Throwable $e): void {}

    private function computeFuzzyCandidates(LoteCruce $lote, ?array $alumnosIndex = null): void
    {
        $pendientes = $lote->ingresantes()
            ->where('estado_match', 'pendiente')
            ->get();

        if ($pendientes->isEmpty()) {
            return;
        }

        $alumnos = $alumnosIndex['alumnos'] ?? [];

        if (empty($alumnos)) {
            return;
        }

        $normalizer = app(NormalizarTextoAction::class);
        $processed = 0;
        $total = count($pendientes);

        $lote->updateQuietly([
            'total_pendientes' => $total,
            'fuzzy_procesados' => 0,
        ]);

        foreach ($pendientes as $ingresante) {
            $this->fuzzyMatchAndSave($ingresante, $alumnos, $normalizer);
            $processed++;

            if ($processed % 50 === 0 || $processed === $total) {
                $lote->updateQuietly(['fuzzy_procesados' => $processed]);
            }
        }

        logger()->info('Fuzzy candidates computed inline', [
            'lote_id' => $lote->id,
            'procesados' => $processed,
            'total' => $total,
        ]);
    }

    private function fuzzyMatchAndSave($ingresante, array $alumnos, NormalizarTextoAction $normalizer): void
    {
        $ingresanteFullName = $normalizer->execute(
            $ingresante->apellido_paterno . ' ' .
            $ingresante->apellido_materno . ' ' .
            $ingresante->nombres
        );

        $scored = [];

        foreach ($alumnos as $alumno) {
            $alumnoFullName = $normalizer->execute(
                ($alumno['apellido_paterno'] ?? '') . ' ' .
                ($alumno['apellido_materno'] ?? '') . ' ' .
                ($alumno['nombres'] ?? '')
            );

            $levDistance = levenshtein($ingresanteFullName, $alumnoFullName);
            $maxLen = max(mb_strlen($ingresanteFullName), mb_strlen($alumnoFullName));
            $levSimilarity = $maxLen === 0 ? 1.0 : 1.0 - ($levDistance / $maxLen);

            $lenA = mb_strlen($ingresanteFullName);
            $lenB = mb_strlen($alumnoFullName);
            $diceCoeff = 0.0;
            if ($lenA >= 2 && $lenB >= 2) {
                $bigramsA = [];
                for ($i = 0; $i < $lenA - 1; $i++) {
                    $bigramsA[] = mb_substr($ingresanteFullName, $i, 2);
                }
                $bigramsB = [];
                for ($i = 0; $i < $lenB - 1; $i++) {
                    $bigramsB[] = mb_substr($alumnoFullName, $i, 2);
                }
                $intersection = array_intersect($bigramsA, $bigramsB);
                $diceCoeff = (2.0 * count($intersection)) / (count($bigramsA) + count($bigramsB));
            }

            $similarity = ($levSimilarity * 0.6 + $diceCoeff * 0.4) * 100;

            if ($similarity >= 70.0) {
                $scored[] = [
                    'alumno_id' => (int) $alumno['id'],
                    'porcentaje_similitud' => round($similarity, 2),
                    'apellido_paterno' => $normalizer->execute($alumno['apellido_paterno'] ?? ''),
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

        IngresanteCandidato::where('ingresante_id', $ingresante->id)->delete();

        foreach ($topCandidates as $idx => $candidate) {
            IngresanteCandidato::create([
                'ingresante_id' => $ingresante->id,
                'alumno_id' => $candidate['alumno_id'],
                'porcentaje_similitud' => $candidate['porcentaje_similitud'],
                'ranking' => $idx + 1,
            ]);
        }

        if (!empty($topCandidates) && $topCandidates[0]['porcentaje_similitud'] >= 99.5) {
            $winner = $topCandidates[0];
            $ingresante->update([
                'alumno_id' => $winner['alumno_id'],
                'estado_match' => 'confirmado_manual',
            ]);
        }
    }
}
