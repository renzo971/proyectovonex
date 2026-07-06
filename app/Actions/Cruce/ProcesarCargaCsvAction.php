<?php

declare(strict_types=1);

namespace App\Actions\Cruce;

use App\Models\LoteCruce;
use App\Models\Ingresante;
use App\Models\NoIngresante;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ProcesarCargaCsvAction
{
    protected NormalizarTextoAction $normalizer;

    public function __construct()
    {
        $this->normalizer = new NormalizarTextoAction();
    }

    public function execute(string $path): array
    {
        if (!file_exists($path)) {
            return ['success' => false, 'error' => 'Archivo no encontrado'];
        }

        if (filesize($path) > 20 * 1024 * 1024) {
            return ['success' => false, 'error' => 'El archivo excede el límite de 20 MB'];
        }

        $content = file_get_contents($path);

        if (str_starts_with($content, "\xEF\xBB\xBF")) {
            $content = substr($content, 3);
        }

        $encoding = mb_detect_encoding($content, ['UTF-8', 'ISO-8859-1'], true);
        if (!$encoding) {
            return ['success' => false, 'error' => 'Codificación de archivo no soportada'];
        }
        if ($encoding !== 'UTF-8') {
            $content = mb_convert_encoding($content, 'UTF-8', $encoding);
        }

        $lines = preg_split('/\r\n|\r|\n/', $content);
        $lines = array_filter(array_map('trim', $lines));

        if (count($lines) < 1) {
            return ['success' => false, 'error' => 'Archivo CSV vacío'];
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
            return [
                'success' => false,
                'error' => 'Columnas requeridas faltantes: ' . implode(', ', $missingColumns)
            ];
        }

        $headerMap = array_flip($headers);

        $rows = [];
        $duplicatesRemoved = 0;
        $seenRows = [];

        $totalIngresantes = 0;
        $totalNoIngresantes = 0;
        $lotesCreated = [];
        $errors = [];

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
                $errors[] = 'Fila con nombres vacíos';
                continue;
            }

            $rowHash = md5(implode('|', $row));
            if (isset($seenRows[$rowHash])) {
                $duplicatesRemoved++;
                continue;
            }
            $seenRows[$rowHash] = true;

            $rows[] = $row;
        }

        $groupedByDate = [];
        foreach ($rows as $row) {
            $date = $row['FECHA'];
            $groupedByDate[$date][] = $row;
        }

        // Sort dates to ensure consistent processing order
        ksort($groupedByDate);

        DB::beginTransaction();
        try {
            foreach ($groupedByDate as $date => $dateRows) {
                $loteExists = LoteCruce::where('fecha_examen', $date)->exists();
                if ($loteExists) {
                    Log::info("Fecha de examen {$date} ya procesada. Saltando lote.");
                    continue;
                }

                $lote = LoteCruce::create([
                    'fecha_examen' => $date,
                    'estado' => 'completed',
                    'started_at' => now(),
                    'completed_at' => now(),
                ]);

                $loteIngresantes = 0;
                $loteNoIngresantes = 0;

                foreach ($dateRows as $row) {
                    $normalizedObservacion = $this->normalizer->execute($row['OBSERVACION']);
                    
                    $fullName = $row['APELLIDOS'] . ', ' . $row['NOMBRES'];
                    $splitNames = $this->normalizer->separar($fullName);

                    $modelData = [
                        'lote_cruce_id' => $lote->id,
                        'codigo' => $row['CODIGO'],
                        'apellidos' => $this->normalizer->execute($row['APELLIDOS']),
                        'apellido_paterno' => $splitNames['apellido_paterno'],
                        'apellido_materno' => $splitNames['apellido_materno'],
                        'nombres' => $splitNames['nombres'],
                        'eap' => $this->normalizer->execute($row['EAP']),
                        'puntaje' => floatval($row['PUNTAJE']),
                        'merito' => intval($row['MERITO']),
                        'observacion' => $normalizedObservacion,
                        'tipo' => $this->normalizer->execute($row['TIPO']),
                        'modalidad' => $this->normalizer->execute($row['MODALIDAD']),
                        'universidad' => $this->normalizer->execute($row['UNIVERSIDAD']),
                        'periodo' => $this->normalizer->execute($row['PERIODO']),
                        'fecha' => $date,
                    ];

                    if ($normalizedObservacion === 'ALCANZO VACANTE') {
                        $modelData['estado_match'] = 'pendiente';
                        Ingresante::create($modelData);
                        $loteIngresantes++;
                        $totalIngresantes++;
                    } else {
                        NoIngresante::create($modelData);
                        $loteNoIngresantes++;
                        $totalNoIngresantes++;
                    }
                }

                $lote->update([
                    'total_registros' => $loteIngresantes + $loteNoIngresantes,
                    'total_ingresantes' => $loteIngresantes,
                    'total_no_ingresantes' => $loteNoIngresantes,
                    'total_pendientes' => $loteIngresantes,
                ]);

                $lotesCreated[] = $lote;
            }

            DB::commit();
        } catch (\Exception $e) {
            DB::rollBack();
            throw $e;
        }

        return [
            'success' => true,
            'data' => [
                'total_registros' => $totalIngresantes + $totalNoIngresantes,
                'duplicates_removed' => $duplicatesRemoved,
                'total_ingresantes' => $totalIngresantes,
                'total_no_ingresantes' => $totalNoIngresantes,
                'lotes' => $lotesCreated,
                'errores' => $errors,
            ]
        ];
    }
}
