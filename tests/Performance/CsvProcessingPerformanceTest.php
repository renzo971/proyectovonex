<?php

declare(strict_types=1);

namespace Tests\Performance;

use App\Jobs\ProcessCsvBatchJob;
use App\Models\LoteCruce;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

/**
 * Test Suite: CSV Processing Performance
 * Feature ID: 001-motor-cruce-ingresantes
 * Generated from: .specify/specs/001-motor-cruce-ingresantes/test-cases.md
 */
class CsvProcessingPerformanceTest extends TestCase
{
    use RefreshDatabase;

    /**
     * TC-028: Procesar un CSV de ~27,000 filas en menos de 50 segundos
     * Traces to: NFR-001, plan.md: Redis Queue
     * Type: Performance
     * Priority: P1
     */
    #[Test]
    public function tc028_processes_27k_rows_in_under_50_seconds(): void
    {
        // Generate synthetic CSV with 27,000 rows
        $csvContent = $this->generateLargeCsv(27000);
        $path = $this->createTempCsv($csvContent, 'performance-27k.csv');

        $lote = LoteCruce::factory()->create([
            'fecha_examen' => '2026-05-17',
            'estado' => 'processing',
        ]);

        $startTime = microtime(true);

        $job = new ProcessCsvBatchJob($lote->id);
        $job->csvPath = $path;
        $job->handle();

        $elapsed = microtime(true) - $startTime;

        expect($elapsed)->toBeLessThanOrEqual(50);

        $lote->refresh();
        expect($lote->estado)->toBe('completed');
        expect($lote->total_registros)->toBe(27000);
    }

    private function generateLargeCsv(int $rows): string
    {
        $header = 'CODIGO,APELLIDOS,NOMBRES,EAP,PUNTAJE,MERITO,OBSERVACION,TIPO,MODALIDAD,UNIVERSIDAD,PERIODO,FECHA';
        $csv = $header . "\n";

        for ($i = 1; $i <= $rows; $i++) {
            $codigo = str_pad((string) $i, 6, '0', STR_PAD_LEFT);
            $apellido = 'APELLIDO' . strtoupper(dechex($i % 1000));
            $nombre = 'NOMBRE' . strtoupper(dechex($i % 500));
            $eap = ['MEDICINA HUMANA', 'DERECHO', 'ADMINISTRACION', 'INGENIERIA DE SOFTWARE', 'CIENCIAS BIOLOGICAS'][$i % 5];
            $puntaje = number_format(10 + ($i % 100) / 10, 3);
            $merito = $i % 200;
            $observacion = $i % 3 === 0 ? 'ALCANZO VACANTE' : 'NO ALCANZO VACANTE';
            $tipo = 'ORDINARIO';
            $modalidad = 'GENERAL';
            $universidad = 'UNMSM';
            $periodo = '2026-I';
            $fecha = '2026-05-17';

            $csv .= "{$codigo},{$apellido},{$nombre},{$eap},{$puntaje},{$merito},{$observacion},{$tipo},{$modalidad},{$universidad},{$periodo},{$fecha}\n";
        }

        return $csv;
    }
}
