<?php

declare(strict_types=1);

namespace Tests\Unit\Actions;

use App\Actions\Cruce\ExportarExcelCruceAction;
use App\Models\Ingresante;
use App\Models\LoteCruce;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

/**
 * Test Suite: ExportarExcelCruceAction
 * Feature ID: 001-motor-cruce-ingresantes
 * Generated from: .specify/specs/001-motor-cruce-ingresantes/test-cases.md
 */
class ExportarExcelCruceActionTest extends TestCase
{
    private ExportarExcelCruceAction $action;

    protected function setUp(): void
    {
        parent::setUp();
        $this->action = new ExportarExcelCruceAction();
    }

    /**
     * TC-034: Mapeo de EAP a AREA académica en UNMSM
     * Traces to: US-005, AC-014, plan.md: ExportarExcelCruceAction
     * Type: Unit
     * Priority: P1
     */
    #[Test]
    public function tc034_maps_eap_to_academic_area(): void
    {
        $testCases = [
            'MEDICINA HUMANA' => 'Area A',
            'CIENCIAS BIOLOGICAS' => 'Area B',
            'INGENIERIA DE SOFTWARE' => 'Area C',
            'ADMINISTRACION' => 'Area D',
            'DERECHO' => 'Area E',
        ];

        foreach ($testCases as $eap => $expectedArea) {
            $result = $this->action->resolveArea($eap);
            expect($result)->toBe($expectedArea);
        }
    }

    /**
     * TC-035: Validación de la estructura de 24 columnas del reporte final
     * Traces to: US-005, AC-014
     * Type: Integration
     * Priority: P1
     */
    #[Test]
    public function tc035_validates_24_column_structure(): void
    {
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
        Ingresante::factory()->count(3)->create([
            'lote_cruce_id' => $lote->id,
            'estado_match' => 'confirmado_automatico',
        ]);

        $result = $this->action->execute($lote->id);

        expect($result['success'])->toBeTrue();
        expect($result['data']['column_count'])->toBe(24);
    }

    /**
     * TC-036: Cálculo de LISTA - 1 (Cachimbos Históricos)
     * Traces to: US-005, AC-014
     * Type: Unit
     * Priority: P1
     */
    #[Test]
    public function tc036_calculates_lista_1_cachimbos_historicos(): void
    {
        $testCases = [
            'Verano 2024' => 1,
            'Verano 2025' => 1,
            'Anual 2023' => 0,
            'Repaso 2025' => 1,
        ];

        foreach ($testCases as $periodo => $expected) {
            $result = $this->action->calculateLista1($periodo);
            expect($result)->toBe($expected);
        }
    }

    /**
     * TC-037: Cálculo de LISTA - 2 (Cachimbos Temporada)
     * Traces to: US-005, AC-014
     * Type: Unit
     * Priority: P1
     */
    #[Test]
    public function tc037_calculates_lista_2_cachimbos_temporada(): void
    {
        $testCases = [
            ['periodo' => 'VERANO 2026', 'estado' => 'RETIRADO', 'expected' => 1],
            ['periodo' => 'OCTUBRE 2025', 'estado' => 'SUSPENDIDO', 'expected' => 1],
            ['periodo' => 'ANUAL 2025', 'estado' => 'MATRICULADO', 'expected' => 0],
        ];

        foreach ($testCases as $case) {
            $result = $this->action->calculateLista2($case['periodo'], $case['estado']);
            expect($result)->toBe($case['expected']);
        }
    }

    /**
     * TC-038: Cálculo de LISTA - 3 (Cachimbos Activos a Febrero 2026)
     * Traces to: US-005, AC-014
     * Type: Unit
     * Priority: P1
     */
    #[Test]
    public function tc038_calculates_lista_3_cachimbos_activos_febrero_2026(): void
    {
        $testCases = [
            ['estado' => 'MATRICULADO', 'expected' => 1],
            ['estado' => 'PAGADO', 'expected' => 1],
            ['estado' => 'FINALIZADO', 'expected' => 1],
            ['estado' => 'RETIRADO', 'expected' => 0],
            ['estado' => 'SUSPENDIDO', 'expected' => 0],
            ['estado' => 'ANULADO', 'expected' => 0],
        ];

        foreach ($testCases as $case) {
            $result = $this->action->calculateLista3($case['estado'], '2026-02-27');
            expect($result)->toBe($case['expected']);
        }
    }

    /**
     * TC-007: Integridad estructural del Excel - Hoja 1 y Hoja 2
     * Traces to: US-005, AC-014, AC-015, test-cases.md TC-7
     * Type: Integration
     * Priority: P1
     */
    #[Test]
    public function tc007_excel_contains_dual_sheet_structure(): void
    {
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
        Ingresante::factory()->count(20)->create([
            'lote_cruce_id' => $lote->id,
        ]);

        $result = $this->action->execute($lote->id);

        expect($result['success'])->toBeTrue();
        expect($result['data']['sheets'])->toContain('Hoja 1');
        expect($result['data']['sheets'])->toContain('Hoja 2');
        expect($result['data']['columnas_csv'])->toHaveCount(13); // A-M
        expect($result['data']['columnas_enriquecidas'])->toContain('Sede');
        expect($result['data']['columnas_enriquecidas'])->toContain('Ciclo');
        expect($result['data']['columnas_enriquecidas'])->toContain('Estado');
        expect($result['data']['has_dashboard'])->toBeTrue();
    }
}
