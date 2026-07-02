<?php

declare(strict_types=1);

namespace App\Actions\Cruce;

use App\Models\Ingresante;
use App\Models\LoteCruce;
use App\Models\NoIngresante;

class ProcesarCargaCsvAction
{
    private NormalizarTextoAction $normalizador;

    public function __construct(?NormalizarTextoAction $normalizador = null)
    {
        $this->normalizador = $normalizador ?? new NormalizarTextoAction();
    }

    private const EXPECTED_HEADERS = [
        'CODIGO', 'APELLIDOS', 'NOMBRES', 'EAP', 'PUNTAJE', 'MERITO',
        'OBSERVACION', 'TIPO', 'MODALIDAD', 'UNIVERSIDAD', 'PERIODO', 'FECHA',
    ];

    public function execute(string $filePath): array
    {
        $content = file_get_contents($filePath);

        if ($content === false || trim($content) === '') {
            return ['success' => false, 'error' => 'El archivo está vacío.'];
        }

        if (str_starts_with($content, "\xEF\xBB\xBF")) {
            $content = substr($content, 3);
        }

        $lines = explode("\n", $content);
        $lines = array_map('trim', $lines);
        $lines = array_filter($lines, fn($l) => $l !== '');

        if (empty($lines)) {
            return ['success' => false, 'error' => 'El archivo está vacío.'];
        }

        $headers = str_getcsv($lines[0]);
        $headers = array_map('trim', $headers);

        $diff = array_diff(self::EXPECTED_HEADERS, $headers);
        if (!empty($diff)) {
            return ['success' => false, 'error' => 'Faltan columnas requeridas: ' . implode(', ', $diff)];
        }

        $headerIndex = array_flip($headers);
        $dataLines = array_slice($lines, 1);

        $rows = [];
        $errores = [];

        foreach ($dataLines as $lineNum => $line) {
            $values = str_getcsv($line);
            if (count($values) !== count($headers)) {
                continue;
            }

            $row = [];
            foreach ($headers as $idx => $header) {
                $row[$header] = trim($values[$idx] ?? '');
            }
            $rows[] = $row;
        }

        if (empty($rows)) {
            return ['success' => false, 'error' => 'El archivo no contiene datos.'];
        }

        $seen = [];
        $uniqueRows = [];
        $duplicatesRemoved = 0;

        foreach ($rows as $row) {
            $key = implode('|', $row);
            if (isset($seen[$key])) {
                $duplicatesRemoved++;
                continue;
            }
            $seen[$key] = true;
            $uniqueRows[] = $row;
        }

        $groups = [];
        foreach ($uniqueRows as $row) {
            $fecha = $row['FECHA'];
            if (!isset($groups[$fecha])) {
                $groups[$fecha] = [];
            }
            $groups[$fecha][] = $row;
        }

        $lotes = [];
        $totalIngresantes = 0;
        $totalNoIngresantes = 0;

        foreach ($groups as $fecha => $groupRows) {
            $existing = LoteCruce::where('fecha_examen', $fecha)->first();
            if ($existing) {
                continue;
            }

            $lote = LoteCruce::create([
                'fecha_examen' => $fecha,
                'total_registros' => count($groupRows),
                'estado' => 'processing',
            ]);

            $ingresantesCount = 0;
            $noIngresantesCount = 0;

            $validRows = [];
            foreach ($groupRows as $idx => $row) {
                if (empty($row['NOMBRES']) || empty($row['APELLIDOS'])) {
                    $errores[] = [
                        'fila' => $idx + 2,
                        'codigo' => $row['CODIGO'] ?? '',
                        'mensaje' => 'Campo NOMBRES o APELLIDOS vacío',
                    ];
                    continue;
                }
                $validRows[] = $row;
            }

            $normalizer = $this->normalizador;

            foreach ($validRows as $row) {
                $observacionNormalized = $normalizer->execute($row['OBSERVACION']);
                $splitNames = $normalizer->separar($row['APELLIDOS'] . ', ' . $row['NOMBRES']);

                $data = [
                    'lote_cruce_id' => $lote->id,
                    'codigo' => $row['CODIGO'],
                    'apellidos' => $row['APELLIDOS'],
                    'apellido_paterno' => $splitNames['apellido_paterno'],
                    'apellido_materno' => $splitNames['apellido_materno'],
                    'nombres' => $splitNames['nombres'],
                    'eap' => $row['EAP'],
                    'puntaje' => (float) $row['PUNTAJE'],
                    'merito' => (int) $row['MERITO'],
                    'observacion' => $row['OBSERVACION'],
                    'tipo' => $row['TIPO'],
                    'modalidad' => $row['MODALIDAD'],
                    'universidad' => $row['UNIVERSIDAD'],
                    'periodo' => $row['PERIODO'],
                    'fecha' => $row['FECHA'],
                ];

                if ($observacionNormalized === 'ALCANZO VACANTE') {
                    Ingresante::create($data);
                    $ingresantesCount++;
                } else {
                    NoIngresante::create($data);
                    $noIngresantesCount++;
                }
            }

            $lote->update([
                'total_ingresantes' => $ingresantesCount,
                'total_no_ingresantes' => $noIngresantesCount,
                'total_registros' => count($validRows),
            ]);

            $lotes[] = [
                'id' => $lote->id,
                'fecha_examen' => $fecha,
                'total_registros' => count($validRows),
            ];

            $totalIngresantes += $ingresantesCount;
            $totalNoIngresantes += $noIngresantesCount;
        }

        if (empty($lotes)) {
            return ['success' => false, 'error' => 'No se crearon lotes. Todas las fechas ya fueron procesadas.'];
        }

        return [
            'success' => true,
            'data' => [
                'total_registros' => count($uniqueRows),
                'duplicates_removed' => $duplicatesRemoved,
                'total_ingresantes' => $totalIngresantes,
                'total_no_ingresantes' => $totalNoIngresantes,
                'lotes' => $lotes,
                'errores' => $errores,
            ],
        ];
    }
}
