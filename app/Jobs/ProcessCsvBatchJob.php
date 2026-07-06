<?php

declare(strict_types=1);

namespace App\Jobs;

use App\Models\LoteCruce;
use App\Models\Ingresante;
use App\Models\NoIngresante;
use App\Actions\Cruce\NormalizarTextoAction;
use App\Actions\Cruce\RealizarCruceExactoAction;
use App\Actions\Cruce\CalcularSimilitudesCabosAction;
use App\Actions\Cruce\AcademiaDbHelper;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ProcessCsvBatchJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $loteId;
    public string $csvPath = '';

    public function __construct(int $loteId)
    {
        $this->loteId = $loteId;
    }

    public function handle(): void
    {
        $lote = LoteCruce::find($this->loteId);
        if (!$lote) {
            Log::error("ProcessCsvBatchJob: Lote {$this->loteId} no encontrado.");
            return;
        }

        $lote->update(['estado' => 'processing', 'started_at' => now()]);

        if (!file_exists($this->csvPath)) {
            $lote->update(['estado' => 'error']);
            Log::error("ProcessCsvBatchJob: Archivo {$this->csvPath} no existe.");
            return;
        }

        try {
            $content = file_get_contents($this->csvPath);

            // UTF-8 BOM
            if (str_starts_with($content, "\xEF\xBB\xBF")) {
                $content = substr($content, 3);
            }

            // Encoding check
            $encoding = mb_detect_encoding($content, ['UTF-8', 'ISO-8859-1'], true);
            if (!$encoding) {
                $lote->update(['estado' => 'error']);
                return;
            }
            if ($encoding !== 'UTF-8') {
                $content = mb_convert_encoding($content, 'UTF-8', $encoding);
            }

            $lines = preg_split('/\r\n|\r|\n/', $content);
            $lines = array_filter(array_map('trim', $lines));

            if (count($lines) < 1) {
                $lote->update(['estado' => 'error']);
                return;
            }

            $headersLine = array_shift($lines);
            $headers = str_getcsv($headersLine);
            $headers = array_map(function ($h) {
                return trim(mb_strtoupper($h, 'UTF-8'));
            }, $headers);

            $requiredColumns = [
                'CODIGO', 'APELLIDOS', 'NOMBRES', 'EAP', 'PUNTAJE', 'MERITO',
                'OBSERVACION', 'TIPO', 'MODALIDAD', 'UNIVERSIDAD', 'PERIODO', 'FECHA'
            ];

            $missingColumns = array_diff($requiredColumns, $headers);
            if (!empty($missingColumns)) {
                $lote->update(['estado' => 'error']);
                return;
            }

            $headerMap = array_flip($headers);

            $normalizer = new NormalizarTextoAction();

            $ingresantesToInsert = [];
            $noIngresantesToInsert = [];
            $seenRows = [];

            foreach ($lines as $line) {
                $data = str_getcsv($line);
                if (count($data) < count($requiredColumns)) {
                    continue;
                }

                $row = [];
                foreach ($requiredColumns as $col) {
                    $row[$col] = trim($data[$headerMap[$col]] ?? '');
                }

                if ($row['NOMBRES'] === '') {
                    continue;
                }

                $rowHash = md5(implode('|', $row));
                if (isset($seenRows[$rowHash])) {
                    continue;
                }
                $seenRows[$rowHash] = true;

                $normalizedObservacion = $normalizer->execute($row['OBSERVACION']);
                $fullName = $row['APELLIDOS'] . ', ' . $row['NOMBRES'];
                $splitNames = $normalizer->separar($fullName);

                $nowStr = now()->toDateTimeString();

                if ($normalizedObservacion === 'ALCANZO VACANTE') {
                    $ingresantesToInsert[] = [
                        'lote_cruce_id' => $lote->id,
                        'codigo' => $row['CODIGO'],
                        'apellidos' => $normalizer->execute($row['APELLIDOS']),
                        'apellido_paterno' => $splitNames['apellido_paterno'],
                        'apellido_materno' => $splitNames['apellido_materno'],
                        'nombres' => $splitNames['nombres'],
                        'eap' => $normalizer->execute($row['EAP']),
                        'puntaje' => floatval($row['PUNTAJE']),
                        'merito' => intval($row['MERITO']),
                        'observacion' => $normalizedObservacion,
                        'tipo' => $normalizer->execute($row['TIPO']),
                        'modalidad' => $normalizer->execute($row['MODALIDAD']),
                        'universidad' => $normalizer->execute($row['UNIVERSIDAD']),
                        'periodo' => $normalizer->execute($row['PERIODO']),
                        'fecha' => $lote->fecha_examen->format('Y-m-d'),
                        'estado_match' => 'pendiente',
                        'porcentaje_similitud' => null,
                        'created_at' => $nowStr,
                        'updated_at' => $nowStr,
                    ];
                } else {
                    $noIngresantesToInsert[] = [
                        'lote_cruce_id' => $lote->id,
                        'codigo' => $row['CODIGO'],
                        'apellidos' => $normalizer->execute($row['APELLIDOS']),
                        'apellido_paterno' => $splitNames['apellido_paterno'],
                        'apellido_materno' => $splitNames['apellido_materno'],
                        'nombres' => $splitNames['nombres'],
                        'eap' => $normalizer->execute($row['EAP']),
                        'puntaje' => floatval($row['PUNTAJE']),
                        'merito' => intval($row['MERITO']),
                        'observacion' => $normalizedObservacion,
                        'tipo' => $normalizer->execute($row['TIPO']),
                        'modalidad' => $normalizer->execute($row['MODALIDAD']),
                        'universidad' => $normalizer->execute($row['UNIVERSIDAD']),
                        'periodo' => $normalizer->execute($row['PERIODO']),
                        'fecha' => $lote->fecha_examen->format('Y-m-d'),
                        'created_at' => $nowStr,
                    ];
                }
            }

            // Bulk inserts in chunks for speed
            DB::transaction(function () use ($ingresantesToInsert, $noIngresantesToInsert) {
                foreach (array_chunk($ingresantesToInsert, 1000) as $chunk) {
                    DB::table('ingresantes')->insert($chunk);
                }
                foreach (array_chunk($noIngresantesToInsert, 1000) as $chunk) {
                    DB::table('no_ingresantes')->insert($chunk);
                }
            });

            $totalIngresantes = count($ingresantesToInsert);
            $totalNoIngresantes = count($noIngresantesToInsert);

            $lote->update([
                'total_registros' => $totalIngresantes + $totalNoIngresantes,
                'total_ingresantes' => $totalIngresantes,
                'total_no_ingresantes' => $totalNoIngresantes,
                'total_pendientes' => $totalIngresantes,
            ]);

            // Perform matching phase
            AcademiaDbHelper::ensureTablesAndSeed();

            // Preload active students to prevent N+1 queries (T023)
            $preloadedStudents = DB::connection('academia')
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

            $cruceExactoAction = new RealizarCruceExactoAction();
            $fuzzyAction = new CalcularSimilitudesCabosAction();

            // Get inserted ingresantes ids
            $insertedIngresantes = Ingresante::where('lote_cruce_id', $lote->id)->get();

            foreach ($insertedIngresantes as $ingresante) {
                // Try exact match first
                $exactResult = $cruceExactoAction->execute($ingresante->id, $preloadedStudents);
                if (!$exactResult['success']) {
                    // Try fuzzy match calculation
                    $fuzzyAction->execute($ingresante->id);
                }
            }

            $lote->update([
                'estado' => 'completed',
                'completed_at' => now(),
            ]);

        } catch (\Exception $e) {
            Log::error("ProcessCsvBatchJob error: " . $e->getMessage());
            $lote->update(['estado' => 'error']);
            throw $e;
        }
    }
}
