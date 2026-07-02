<?php

declare(strict_types=1);

namespace Tests\Unit\Actions;

use App\Actions\Cruce\ProcesarCargaCsvAction;
use App\Models\LoteCruce;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

/**
 * Test Suite: ProcesarCargaCsvAction
 * Feature ID: 001-motor-cruce-ingresantes
 * Generated from: .specify/specs/001-motor-cruce-ingresantes/test-cases.md
 */
class ProcesarCargaCsvActionTest extends TestCase
{
    private ProcesarCargaCsvAction $action;

    protected function setUp(): void
    {
        parent::setUp();
        $this->action = new ProcesarCargaCsvAction();
    }

    /**
     * TC-001: Importar CSV con múltiples fechas de examen y duplicados en el mismo lote
     * Traces to: US-001, AC-001, plan.md: ProcesarCargaCsvAction / LoteCruce
     * Type: Integration
     * Priority: P1
     */
    #[Test]
    public function tc001_imports_csv_with_multiple_dates_and_removes_duplicates(): void
    {
        $csvContent = readFixture('duplicate-rows.csv');
        $path = $this->createTempCsv($csvContent, 'tc001-duplicates.csv');

        $result = $this->action->execute($path);

        expect($result['success'])->toBeTrue();
        expect($result['data']['total_registros'])->toBe(2);
        expect($result['data']['duplicates_removed'])->toBe(3);

        $lotes = LoteCruce::all();
        expect($lotes)->toHaveCount(2);
    }

    /**
     * TC-004: Filtrar OBSERVACION y enrutar a ingresantes / no_ingresantes
     * Traces to: US-001, AC-004, plan.md: ProcesarCargaCsvAction
     * Type: Integration
     * Priority: P1
     */
    #[Test]
    public function tc004_filters_observacion_and_routes_to_correct_tables(): void
    {
        $csvContent = readFixture('valid-sample.csv');
        $path = $this->createTempCsv($csvContent, 'tc004-filter.csv');

        $result = $this->action->execute($path);

        expect($result['success'])->toBeTrue();
        expect($result['data']['total_ingresantes'])->toBe(4);
        expect($result['data']['total_no_ingresantes'])->toBe(1);
    }

    /**
     * TC-043: Filas idénticas dentro del mismo CSV solo producen un registro en BD (INV-04)
     * Traces to: INV-04, CQ-002, US-001 AC-001
     * Type: Unit
     * Priority: P1
     */
    #[Test]
    public function tc0043_identical_rows_produce_single_record(): void
    {
        $csvContent = "CODIGO,APELLIDOS,NOMBRES,EAP,PUNTAJE,MERITO,OBSERVACION,TIPO,MODALIDAD,UNIVERSIDAD,PERIODO,FECHA\n";
        $csvContent .= "001,LOPEZ GARCIA,JUAN,MEDICINA HUMANA,15.500,10,ALCANZO VACANTE,ORDINARIO,GENERAL,UNMSM,2026-I,2026-05-17\n";
        $csvContent .= "001,LOPEZ GARCIA,JUAN,MEDICINA HUMANA,15.500,10,ALCANZO VACANTE,ORDINARIO,GENERAL,UNMSM,2026-I,2026-05-17\n";
        $csvContent .= "001,LOPEZ GARCIA,JUAN,MEDICINA HUMANA,15.500,10,ALCANZO VACANTE,ORDINARIO,GENERAL,UNMSM,2026-I,2026-05-17\n";

        $path = $this->createTempCsv($csvContent, 'tc043-identical.csv');

        $result = $this->action->execute($path);

        expect($result['success'])->toBeTrue();
        expect($result['data']['total_registros'])->toBe(1);
        expect($result['data']['duplicates_removed'])->toBe(2);
    }

    /**
     * TC-044: Valor crudo de OBSERVACION nunca es evaluado — solo el normalizado (INV-05)
     * Traces to: INV-05, CQ-001, US-001 AC-004
     * Type: Unit
     * Priority: P1
     */
    #[Test]
    public function tc0044_filter_operates_on_normalized_not_raw_value(): void
    {
        $csvContent = "CODIGO,APELLIDOS,NOMBRES,EAP,PUNTAJE,MERITO,OBSERVACION,TIPO,MODALIDAD,UNIVERSIDAD,PERIODO,FECHA\n";
        $csvContent .= "001,LOPEZ GARCIA,JUAN,MEDICINA HUMANA,15.500,10,alcanzó vacante,ORDINARIO,GENERAL,UNMSM,2026-I,2026-05-17\n";

        $path = $this->createTempCsv($csvContent, 'tc044-raw-observacion.csv');

        $result = $this->action->execute($path);

        // Should be routed to ingresantes because normalized value is ALCANZO VACANTE
        expect($result['success'])->toBeTrue();
        expect($result['data']['total_ingresantes'])->toBe(1);
        expect($result['data']['total_no_ingresantes'])->toBe(0);
    }

    /**
     * TC-001: Agrupación por lotes de fechas múltiples
     * Traces to: US-001, AC-001, test-cases.md TC-1
     * Type: Integration
     * Priority: P1
     */
    #[Test]
    public function tc001_groups_rows_by_exam_date_into_separate_batches(): void
    {
        $rows = [];
        for ($i = 0; $i < 100; $i++) {
            $rows[] = $this->validCsvRow(['CODIGO' => sprintf('00%d', $i + 1), 'FECHA' => '2026-03-14']);
        }
        for ($i = 0; $i < 100; $i++) {
            $rows[] = $this->validCsvRow(['CODIGO' => sprintf('01%d', $i + 1), 'FECHA' => '2026-03-15']);
        }
        $csv = $this->buildCsv($rows);
        $path = $this->createTempCsv($csv, 'tc001-two-dates.csv');

        $result = $this->action->execute($path);

        expect($result['success'])->toBeTrue();
        expect($result['data']['lotes'])->toHaveCount(2);
        expect($result['data']['lotes'][0]['total_registros'])->toBe(100);
        expect($result['data']['lotes'][1]['total_registros'])->toBe(100);
    }

    /**
     * TC-008: Filtrado por campo OBSERVACION - solo ALCANZO VACANTE
     * Traces to: US-001, AC-004, test-cases.md TC-8
     * Type: Integration
     * Priority: P1
     */
    #[Test]
    public function tc008_filters_only_observacion_ALCANZO_VACANTE(): void
    {
        $rows = [
            $this->validCsvRow(['CODIGO' => '001', 'OBSERVACION' => 'ALCANZO VACANTE']),
            $this->validCsvRow(['CODIGO' => '002', 'OBSERVACION' => 'NO INGRESÓ']),
            $this->validCsvRow(['CODIGO' => '003', 'OBSERVACION' => 'RETIRO DE VACANTE']),
            $this->validCsvRow(['CODIGO' => '004', 'OBSERVACION' => 'ALCANZO VACANTE']),
        ];
        $csv = $this->buildCsv($rows);
        $path = $this->createTempCsv($csv, 'tc008-observacion-filter.csv');

        $result = $this->action->execute($path);

        expect($result['success'])->toBeTrue();
        expect($result['data']['total_ingresantes'])->toBe(2);
        expect($result['data']['total_no_ingresantes'])->toBe(2);
    }

    /**
     * TC-011: Manejo de campos vacíos en CSV - nombres vacío
     * Traces to: US-001, EC-001, test-cases.md TC-11
     * Type: Integration
     * Priority: P1
     */
    #[Test]
    public function tc011_handles_empty_nombres_field(): void
    {
        $rows = [
            ['001', 'LOPEZ GARCIA', '', 'MEDICINA HUMANA', '15.500', '10', 'ALCANZO VACANTE', 'ORDINARIO', 'GENERAL', 'UNMSM', '2026-I', '2026-03-14'],
            ['002', 'PEREZ RUIZ', 'ANA', 'DERECHO', '14.000', '20', 'ALCANZO VACANTE', 'ORDINARIO', 'GENERAL', 'UNMSM', '2026-I', '2026-03-14'],
        ];
        $csv = $this->buildCsv($rows);
        $path = $this->createTempCsv($csv, 'tc011-empty-nombres.csv');

        $result = $this->action->execute($path);

        expect($result['success'])->toBeTrue();
        expect($result['data']['total_ingresantes'])->toBe(1);
        expect($result['data']['errores'])->toHaveCount(1);
    }

    /**
     * TC-012: Validación de estructura de columnas - falta OBSERVACION
     * Traces to: US-001, EC-002, test-cases.md TC-12
     * Type: Integration
     * Priority: P1
     */
    #[Test]
    public function tc012_rejects_csv_without_required_columns(): void
    {
        $csvContent = "NOMBRES,FECHA_EXAMEN\nJUAN,2026-03-14\n";
        $path = $this->createTempCsv($csvContent, 'tc012-missing-columns.csv');

        $result = $this->action->execute($path);

        expect($result['success'])->toBeFalse();
        expect($result['error'])->toContain('OBSERVACION');
    }
}
