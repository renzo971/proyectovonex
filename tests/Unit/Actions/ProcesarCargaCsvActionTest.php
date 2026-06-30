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

        // Verify only one lote created for the latest date
        $lotes = LoteCruce::all();
        expect($lotes)->toHaveCount(1);
        expect($lotes->first()->fecha_examen)->toBe('2026-05-17');
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
}
