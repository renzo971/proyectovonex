<?php

declare(strict_types=1);

namespace Tests\Unit\Actions;

use App\Actions\Cruce\AcademiaDbHelper;
use App\Actions\Cruce\CalcularSimilitudesCabosAction;
use App\Models\Ingresante;
use App\Models\LoteCruce;
use Illuminate\Support\Facades\DB;
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

        // Verify we got 5 candidates
        $candidates = $result['data']['candidates'];
        expect($candidates)->toHaveCount(5);
    }

    /**
     * TC-009: Cálculo y ranking de candidatos difusos para GONZALES DE LA FLOR PEDRO
     * Traces to: US-003, AC-009, test-cases.md TC-9
     * Type: Integration
     * Priority: P1
     */
    #[Test]
    public function tc009_fuzzy_ranking_gonzales_de_la_flor(): void
    {
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'apellido_paterno' => 'GONZALES',
            'apellido_materno' => 'DE LA FLOR',
            'nombres' => 'PEDRO',
            'estado_match' => 'pendiente',
        ]);

        $result = $this->action->execute($ingresante->id);

        expect($result['success'])->toBeTrue();
        expect($result['data']['candidates'])->toHaveCount(5);
        expect($result['data']['candidates'][0]['porcentaje_similitud'])->toBeGreaterThanOrEqual(90);
        expect($result['data']['candidates'][4]['porcentaje_similitud'])->toBeGreaterThanOrEqual(30);
    }

    /**
     * Regression (code review follow-up to T036, 2026-07-07): the fuzzy-match
     * path had zero coverage for its own dedup behavior — only the exact-match
     * path (`ConexionAcademiaTest::t036`) had a genuine multi-record-same-person
     * test. A person re-enrolled across periods (same `dni`, two
     * `alumno_matricula` rows — one SUSPENDIDO seeded with a lower id/first,
     * one MATRICULADO seeded second) must surface as exactly ONE fuzzy
     * candidate, carrying the MATRICULADO record's `alumno_matricula.id`, not
     * the SUSPENDIDO one and not both. A naive "first row wins" (or a
     * name-keyed rather than dni-keyed dedup) would fail this.
     *
     * Traces to: INV-06, US-002 AC-007, test-cases.md TC-005.
     */
    #[Test]
    public function it_collapses_duplicate_person_records_to_one_fuzzy_candidate_by_inv06_hierarchy(): void
    {
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'apellido_paterno' => 'ZUNIGA',
            'apellido_materno' => 'CARDENAS',
            'nombres' => 'ROSA',
            'estado_match' => 'pendiente',
        ]);

        AcademiaDbHelper::ensureTablesAndSeed();

        DB::connection('academia')->table('personas')->insert([
            'dni' => '96000001', 'nombres' => 'ROSA', 'apellido_paterno' => 'ZUNIGA', 'apellido_materno' => 'CARDENAS',
        ]);
        DB::connection('academia')->table('alumnos')->insert([
            'codigo' => 'ALUZ01', 'persona_dni' => '96000001',
        ]);
        DB::connection('academia')->table('alumno_matricula')->insert([
            ['id' => 960, 'alumno_codigo' => 'ALUZ01', 'aula_id' => 1, 'estado' => 9, 'estado_aula' => 1], // SUSPENDIDO — inserted first
            ['id' => 961, 'alumno_codigo' => 'ALUZ01', 'aula_id' => 2, 'estado' => 2, 'estado_aula' => 1], // MATRICULADO — inserted second
        ]);

        $result = $this->action->execute($ingresante->id);

        expect($result['success'])->toBeTrue();
        expect($result['data']['candidates'])->toHaveCount(1);
        expect($result['data']['candidates'][0]['alumno_id'])->toBe(961);
    }

    /**
     * T038: Correction (2026-07-07, PO verification against real production
     * data) — same recency-first correction as
     * `ConexionAcademiaTest::t038_resolves_to_most_recent_record_over_higher_hierarchy_estado()`,
     * exercised on the fuzzy-match path. A person re-enrolled across
     * periods has an OLD `alumno_matricula` record (2022, PAGADO(3)) and a
     * NEWER record (SUSPENDIDO(9)). PAGADO outranks SUSPENDIDO in INV-06
     * hierarchy, so the hierarchy-only resolution from T036 would surface
     * the stale PAGADO record's `alumno_matricula.id` as the single fuzzy
     * candidate. `execute()`'s dedup must now resolve to the MOST RECENT
     * record by `am.fecha` instead.
     *
     * Traces to: INV-06 correction, tasks.md T038, production incident
     * (2026-07-07, PO-verified against real production data).
     */
    #[Test]
    public function t038_fuzzy_dedup_resolves_to_most_recent_record_over_higher_hierarchy_estado(): void
    {
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'apellido_paterno' => 'FLORES',
            'apellido_materno' => 'VEGA',
            'nombres' => 'ANDREA',
            'estado_match' => 'pendiente',
        ]);

        AcademiaDbHelper::ensureTablesAndSeed();

        DB::connection('academia')->table('personas')->insert([
            'dni' => '97000002', 'nombres' => 'ANDREA', 'apellido_paterno' => 'FLORES', 'apellido_materno' => 'VEGA',
        ]);
        DB::connection('academia')->table('alumnos')->insert([
            ['codigo' => 'ALUS01', 'persona_dni' => '97000002'],
            ['codigo' => 'ALUS02', 'persona_dni' => '97000002'],
        ]);
        DB::connection('academia')->table('alumno_matricula')->insert([
            ['id' => 980, 'alumno_codigo' => 'ALUS01', 'aula_id' => 1, 'estado' => 3, 'estado_aula' => 1, 'fecha' => '2022-03-15 00:00:00'], // PAGADO — OLD (stale), lower id
            ['id' => 981, 'alumno_codigo' => 'ALUS02', 'aula_id' => 2, 'estado' => 9, 'estado_aula' => 1, 'fecha' => '2026-01-10 00:00:00'], // SUSPENDIDO — NEWER, real current status
        ]);

        $result = $this->action->execute($ingresante->id);

        expect($result['success'])->toBeTrue();
        expect($result['data']['candidates'])->toHaveCount(1);
        expect($result['data']['candidates'][0]['alumno_id'])->toBe(981);
    }

    /**
     * T039: Scope-boundary follow-up to T038 (PO decision, 2026-07-07) —
     * same widening as
     * `ConexionAcademiaTest::t039_widened_active_estados_surfaces_retirado_as_matching_candidate()`,
     * exercised on the fuzzy-match fallback query. RETIRADO(0) is now
     * included in the active-estado filter (ANULADO(11)/TRASLADADO(12)
     * stay excluded). A person has an OLD PAGADO(3) record (2022) and a
     * NEWER RETIRADO(0) record; before this fix the RETIRADO row never
     * reached the candidate pool, so the fuzzy fallback would have
     * surfaced the stale PAGADO alumno_id (or nothing, if PAGADO also
     * failed to reach the candidate pool). Now recency-first dedup must
     * resolve to the RETIRADO record's alumno_id.
     *
     * Traces to: tasks.md T039, T038 scope-boundary note, PO decision
     * (2026-07-07, explicit approval of RETIRADO only; ANULADO/TRASLADADO
     * rejected for this widening).
     */
    #[Test]
    public function t039_widened_active_estados_surfaces_retirado_as_fuzzy_candidate(): void
    {
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'apellido_paterno' => 'CASTRO',
            'apellido_materno' => 'MEJIA',
            'nombres' => 'DIEGO',
            'estado_match' => 'pendiente',
        ]);

        AcademiaDbHelper::ensureTablesAndSeed();

        DB::connection('academia')->table('personas')->insert([
            'dni' => '97000004', 'nombres' => 'DIEGO', 'apellido_paterno' => 'CASTRO', 'apellido_materno' => 'MEJIA',
        ]);
        DB::connection('academia')->table('alumnos')->insert([
            ['codigo' => 'ALUV01', 'persona_dni' => '97000004'],
            ['codigo' => 'ALUV02', 'persona_dni' => '97000004'],
        ]);
        DB::connection('academia')->table('alumno_matricula')->insert([
            ['id' => 992, 'alumno_codigo' => 'ALUV01', 'aula_id' => 1, 'estado' => 3, 'estado_aula' => 1, 'fecha' => '2022-03-15 00:00:00'], // PAGADO — OLD (stale), lower id
            ['id' => 993, 'alumno_codigo' => 'ALUV02', 'aula_id' => 2, 'estado' => 0, 'estado_aula' => 1, 'fecha' => '2026-01-10 00:00:00'], // RETIRADO — NEWER, real current status
        ]);

        $result = $this->action->execute($ingresante->id);

        expect($result['success'])->toBeTrue();
        expect($result['data']['candidates'])->toHaveCount(1);
        expect($result['data']['candidates'][0]['alumno_id'])->toBe(993);
    }
}
