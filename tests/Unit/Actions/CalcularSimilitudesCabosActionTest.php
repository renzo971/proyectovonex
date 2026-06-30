<?php

declare(strict_types=1);

namespace Tests\Unit\Actions;

use App\Actions\Cruce\CalcularSimilitudesCabosAction;
use App\Models\Ingresante;
use App\Models\LoteCruce;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

/**
 * Test Suite: CalcularSimilitudesCabosAction
 * Feature ID: 001-motor-cruce-ingresantes
 * Generated from: .specify/specs/001-motor-cruce-ingresantes/test-cases.md
 */
class CalcularSimilitudesCabosActionTest extends TestCase
{
    private CalcularSimilitudesCabosAction $action;

    protected function setUp(): void
    {
        parent::setUp();
        $this->action = new CalcularSimilitudesCabosAction();
    }

    /**
     * TC-007: Cálculo de similitud difusa y top 5 candidatos ordenados
     * Traces to: US-003, AC-009, plan.md: CalcularSimilitudesCabosAction
     * Type: Unit / Integration
     * Priority: P1
     */
    #[Test]
    public function tc007_calculates_fuzzy_similarity_and_returns_top_5_candidates(): void
    {
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'apellido_paterno' => 'RAMOS',
            'apellido_materno' => 'LOPEZ',
            'nombres' => 'JHON',
            'estado_match' => 'pendiente',
        ]);

        $result = $this->action->execute($ingresante->id);

        expect($result['success'])->toBeTrue();
        expect($result['data']['candidates'])->toBeArray();
        expect($result['data']['candidates'])->toHaveCount(5);

        // Verify ordering (highest similarity first)
        $candidates = $result['data']['candidates'];
        for ($i = 0; $i < count($candidates) - 1; $i++) {
            expect($candidates[$i]['porcentaje_similitud'])
                ->toBeGreaterThanOrEqual($candidates[$i + 1]['porcentaje_similitud']);
        }
    }

    /**
     * TC-008: Ningún candidato supera el umbral de similitud y se expone opción "No Ingresado"
     * Traces to: US-003, AC-010, plan.md: CalcularSimilitudesCabosAction
     * Type: Integration
     * Priority: P1
     */
    #[Test]
    public function tc008_no_candidates_above_threshold_shows_no_ingresado_option(): void
    {
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'apellido_paterno' => 'XXXXX',
            'apellido_materno' => 'YYYYY',
            'nombres' => 'ZZZZZ',
            'estado_match' => 'pendiente',
        ]);

        $result = $this->action->execute($ingresante->id);

        expect($result['success'])->toBeTrue();
        expect($result['data']['candidates'])->toBeEmpty();
        expect($result['data']['no_ingresado_option'])->toBeTrue();
    }

    /**
     * TC-017: Limitar candidatos a 5 y desempatar por apellido paterno
     * Traces to: EC-005
     * Type: Unit
     * Priority: P2
     */
    #[Test]
    public function tc017_limits_candidates_to_5_and_ties_by_surname(): void
    {
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'apellido_paterno' => 'GARCIA',
            'apellido_materno' => 'LOPEZ',
            'nombres' => 'MARIA',
            'estado_match' => 'pendiente',
        ]);

        $result = $this->action->execute($ingresante->id);

        expect($result['success'])->toBeTrue();
        expect($result['data']['candidates'])->toHaveCount(5);

        // Verify tie-breaking by apellido_paterno alphabetically
        $candidates = $result['data']['candidates'];
        $surnames = array_column($candidates, 'apellido_paterno');
        $sortedSurnames = $surnames;
        sort($sortedSurnames);
        expect($surnames)->toBe($sortedSurnames);
    }
}
