<?php

declare(strict_types=1);

namespace Tests\Feature\Http\Controllers;

use App\Models\Ingresante;
use App\Models\IngresanteCandidato;
use App\Models\LoteCruce;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

/**
 * Test Suite: CruceIngresantesController::pendientes()
 * Feature ID: 001-motor-cruce-ingresantes
 * Generated from: .specify/specs/001-motor-cruce-ingresantes/tasks.md T024, plan.md DA-G1
 */
class CruceIngresantesPendientesTest extends TestCase
{
    /**
     * Builds the shared fixture for the ordering/AC scenarios:
     * - Ingresante A: apellido_paterno 'AAA', 2 candidatos (75% rank2, 82% rank1) -> count=2, max=82
     * - Ingresante B: apellido_paterno 'BBB', 1 candidato (90% rank1) -> count=1, max=90
     * - Ingresante D: apellido_paterno 'DDD', 1 candidato (70% rank1) -> count=1, max=70
     * - Ingresante C: apellido_paterno 'CCC', 0 candidatos -> count=0, max=0
     * - Control row: estado_match 'confirmado_automatico' -> must never appear in `data`
     */
    private function buildScenario(): LoteCruce
    {
        $lote = LoteCruce::factory()->create();

        $a = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'apellido_paterno' => 'AAA',
            'apellido_materno' => 'ZZZ',
            'estado_match' => 'pendiente',
        ]);
        IngresanteCandidato::factory()->create([
            'ingresante_id' => $a->id,
            'porcentaje_similitud' => 75.00,
            'ranking' => 2,
        ]);
        IngresanteCandidato::factory()->create([
            'ingresante_id' => $a->id,
            'porcentaje_similitud' => 82.00,
            'ranking' => 1,
        ]);

        $b = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'apellido_paterno' => 'BBB',
            'apellido_materno' => 'ZZZ',
            'estado_match' => 'pendiente',
        ]);
        IngresanteCandidato::factory()->create([
            'ingresante_id' => $b->id,
            'porcentaje_similitud' => 90.00,
            'ranking' => 1,
        ]);

        $d = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'apellido_paterno' => 'DDD',
            'apellido_materno' => 'ZZZ',
            'estado_match' => 'pendiente',
        ]);
        IngresanteCandidato::factory()->create([
            'ingresante_id' => $d->id,
            'porcentaje_similitud' => 70.00,
            'ranking' => 1,
        ]);

        Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'apellido_paterno' => 'CCC',
            'apellido_materno' => 'ZZZ',
            'estado_match' => 'pendiente',
        ]);

        Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'apellido_paterno' => 'XXX',
            'estado_match' => 'confirmado_automatico',
        ]);

        return $lote;
    }

    /**
     * AC-G1.1: every estado_match='pendiente' ingresante of the lote is returned,
     * including ones with zero candidates or only <80% candidates. Also guards
     * against a regression where a non-pendiente row leaks into the payload.
     */
    #[Test]
    public function acg11_returns_all_pendientes_regardless_of_candidate_similitud(): void
    {
        $lote = $this->buildScenario();

        $response = $this->getJson("/api/cruce/lotes/{$lote->id}/pendientes");

        $response->assertStatus(200);
        $apellidos = collect($response->json('data'))->pluck('apellido_paterno')->all();

        expect($apellidos)->toContain('AAA');
        expect($apellidos)->toContain('BBB');
        expect($apellidos)->toContain('CCC');
        expect($apellidos)->toContain('DDD');
        expect($apellidos)->not->toContain('XXX');
    }

    /**
     * AC-G1.2: ordering must be exactly candidatos_count DESC, max_similitud DESC,
     * apellido_paterno ASC, apellido_materno ASC (in that priority order).
     */
    #[Test]
    public function acg12_orders_by_count_then_max_similitud_then_apellidos(): void
    {
        $lote = $this->buildScenario();

        $response = $this->getJson("/api/cruce/lotes/{$lote->id}/pendientes");

        $apellidos = collect($response->json('data'))->pluck('apellido_paterno')->all();

        expect($apellidos)->toBe(['AAA', 'BBB', 'DDD', 'CCC']);
    }

    /**
     * AC-G1.2 (tie-break): two ingresantes with the SAME candidatos_count and
     * SAME max_similitud but different apellido_paterno must be ordered by
     * apellido_paterno ASC, proving the tie-break is explicit and not incidental.
     */
    #[Test]
    public function acg12_tie_break_orders_by_apellido_paterno_when_count_and_max_match(): void
    {
        $lote = LoteCruce::factory()->create();

        $second = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'apellido_paterno' => 'SEGUNDO',
            'apellido_materno' => 'ZZZ',
            'estado_match' => 'pendiente',
        ]);
        IngresanteCandidato::factory()->create([
            'ingresante_id' => $second->id,
            'porcentaje_similitud' => 85.00,
            'ranking' => 1,
        ]);

        $first = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'apellido_paterno' => 'PRIMERO',
            'apellido_materno' => 'ZZZ',
            'estado_match' => 'pendiente',
        ]);
        IngresanteCandidato::factory()->create([
            'ingresante_id' => $first->id,
            'porcentaje_similitud' => 85.00,
            'ranking' => 1,
        ]);

        $response = $this->getJson("/api/cruce/lotes/{$lote->id}/pendientes");

        $apellidos = collect($response->json('data'))->pluck('apellido_paterno')->all();

        expect($apellidos)->toBe(['PRIMERO', 'SEGUNDO']);
    }

    /**
     * AC-G1.3: an ingresante with zero candidates appears in the payload with
     * an empty `candidatos` array and `max_similitud = 0`, sorted after every
     * ingresante with at least one candidate.
     */
    #[Test]
    public function acg13_zero_candidate_row_has_empty_candidatos_and_zero_max(): void
    {
        $lote = $this->buildScenario();

        $response = $this->getJson("/api/cruce/lotes/{$lote->id}/pendientes");

        $rowC = collect($response->json('data'))->firstWhere('apellido_paterno', 'CCC');

        expect($rowC)->not->toBeNull();
        expect($rowC['candidatos'])->toBe([]);
        expect((float) $rowC['max_similitud'])->toBe(0.0);
    }

    /**
     * AC-G1.4: the eager-loaded `candidatos` relation includes ALL persisted
     * candidates for the ingresante (no >=80 filter), ordered by ranking.
     */
    #[Test]
    public function acg14_candidatos_relation_is_not_filtered_by_80_percent(): void
    {
        $lote = $this->buildScenario();

        $response = $this->getJson("/api/cruce/lotes/{$lote->id}/pendientes");

        $rowA = collect($response->json('data'))->firstWhere('apellido_paterno', 'AAA');

        expect($rowA['candidatos'])->toHaveCount(2);
        expect((float) $rowA['candidatos'][0]['porcentaje_similitud'])->toBe(82.0);
        expect((float) $rowA['candidatos'][1]['porcentaje_similitud'])->toBe(75.0);
    }

    /**
     * AC-G1.5: `meta.total` reflects the FULL pendiente population of the lote,
     * not the previous >=80%-filtered subset.
     */
    #[Test]
    public function acg15_meta_total_reflects_full_pendiente_population(): void
    {
        $lote = $this->buildScenario();

        $response = $this->getJson("/api/cruce/lotes/{$lote->id}/pendientes");

        expect($response->json('meta.total'))->toBe(4);
    }
}
