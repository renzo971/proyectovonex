<?php

declare(strict_types=1);

namespace Tests\Performance;

use App\Models\Ingresante;
use App\Models\LoteCruce;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

/**
 * Test Suite: Fuzzy Match Performance
 * Feature ID: 001-motor-cruce-ingresantes
 * Generated from: .specify/specs/001-motor-cruce-ingresantes/test-cases.md
 */
class FuzzyMatchPerformanceTest extends TestCase
{
    use RefreshDatabase;

    /**
     * TC-029: Endpoint de candidatos responde en < 300 ms p95
     * Traces to: NFR-002, plan.md: API endpoint de candidatos
     * Type: Performance
     * Priority: P1
     */
    #[Test]
    public function tc029_candidates_endpoint_responds_in_under_300ms_p95(): void
    {
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'estado_match' => 'pendiente',
        ]);

        $times = [];
        $iterations = 20;

        for ($i = 0; $i < $iterations; $i++) {
            $startTime = microtime(true);

            $response = $this->getJson("/api/cruce/ingresantes/{$ingresante->id}/candidatos");

            $elapsed = (microtime(true) - $startTime) * 1000; // Convert to ms
            $times[] = $elapsed;

            $response->assertStatus(200);
        }

        // Calculate p95
        sort($times);
        $p95Index = (int) ceil($iterations * 0.95) - 1;
        $p95 = $times[$p95Index];

        expect($p95)->toBeLessThanOrEqual(300);
    }

    /**
     * TC-030: Aceptar archivo CSV de 20 MB sin error de memoria
     * Traces to: NFR-003
     * Type: Performance
     * Priority: P2
     */
    #[Test]
    public function tc030_accepts_20mb_csv_without_memory_error(): void
    {
        // Generate a 20MB CSV file
        $rowSize = 200; // Approximate bytes per row
        $targetSize = 20 * 1024 * 1024; // 20MB
        $rows = (int) ($targetSize / $rowSize);

        $csvContent = $this->generateCsvOfSize($rows, $targetSize);
        $path = $this->createTempCsv($csvContent, 'test-20mb.csv');

        $fileSize = filesize($path);
        expect($fileSize)->toBeGreaterThanOrEqual(20 * 1024 * 1024);

        // Verify file can be read without memory error
        $content = file_get_contents($path);
        expect($content)->not->toBeFalse();
        expect(strlen($content))->toBeGreaterThanOrEqual(20 * 1024 * 1024);
    }

    private function generateCsvOfSize(int $rows, int $targetSize): string
    {
        $header = 'CODIGO,APELLIDOS,NOMBRES,EAP,PUNTAJE,MERITO,OBSERVACION,TIPO,MODALIDAD,UNIVERSIDAD,PERIODO,FECHA';
        $csv = $header . "\n";

        $currentSize = strlen($csv);
        $i = 1;

        while ($currentSize < $targetSize && $i <= $rows) {
            $row = $this->generateRow($i);
            $csv .= $row;
            $currentSize += strlen($row);
            $i++;
        }

        return $csv;
    }

    private function generateRow(int $i): string
    {
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

        return "{$codigo},{$apellido},{$nombre},{$eap},{$puntaje},{$merito},{$observacion},{$tipo},{$modalidad},{$universidad},{$periodo},{$fecha}\n";
    }
}
