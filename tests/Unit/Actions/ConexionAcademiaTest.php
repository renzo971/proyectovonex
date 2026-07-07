<?php

declare(strict_types=1);

namespace Tests\Unit\Actions;

use App\Actions\Cruce\AcademiaDbHelper;
use App\Actions\Cruce\RealizarCruceExactoAction;
use App\Models\Ingresante;
use App\Models\LoteCruce;
use Illuminate\Support\Facades\DB;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

/**
 * Test Suite: Conexión a BD Academia y Jerarquía de Estados
 * Feature ID: 001-motor-cruce-ingresantes
 * Generated from: feature-motor-cruce-grupoV2/test-cases.md
 */
class ConexionAcademiaTest extends TestCase
{
    /**
     * TC-004: Tolerancia a fallos de red/base de datos
     * Traces to: US-002, AC-005, test-cases.md TC-4
     * Type: Integration
     * Priority: P1
     */
    #[Test]
    public function tc004_handles_database_connection_failure(): void
    {
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'estado_match' => 'pendiente',
        ]);

        $action = new RealizarCruceExactoAction();

        // Should fail gracefully when academia DB connection is not available
        $result = $action->execute($ingresante->id);

        expect($result['success'])->toBeFalse();
        expect($result['error'])->toContain('Error de conexión con la BD');

        $lote->refresh();
        expect($lote->estado)->toBe('En Pausa');
    }

    /**
     * TC-005: Desempate por jerarquía estricta de estados
     * Traces to: US-002, AC-007, test-cases.md TC-5
     * Type: Integration
     * Priority: P1
     */
    #[Test]
    public function tc005_resolve_status_hierarchy_for_PEREZ_RUIZ_ANA(): void
    {
        $statuses = ['TRASLADADO', 'SUSPENDIDO', 'MATRICULADO'];
        $resolved = resolveStatusHierarchy($statuses);
        expect($resolved)->toBe('MATRICULADO');
    }

    /**
     * TC-006: Exclusión de estados no permitidos
     * Traces to: US-002, AC-007, test-cases.md TC-6
     * Type: Unit
     * Priority: P1
     */
    #[Test]
    public function tc006_excludes_disallowed_statuses(): void
    {
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);

        // Simulated: record with status "DEUDOR EXCLUIDO" should not appear in enriched data
        $allowedStatuses = [
            'MATRICULADO', 'PAGADO', 'FINALIZADO', 'SUSPENDIDO',
            'RETIRADO', 'TRASLADADO', 'STAND BY', 'ANULADO',
        ];

        $disallowedStatus = 'DEUDOR EXCLUIDO';
        expect(in_array($disallowedStatus, $allowedStatuses, true))->toBeFalse();

        $resolved = resolveStatusHierarchy([$disallowedStatus]);
        expect($resolved)->not->toBe('DEUDOR EXCLUIDO');
    }

    /**
     * T036: Regression for a real production bug — a person re-enrolled
     * across periods ends up with more than one `alumno_matricula` row for
     * the same `dni` (same real person, e.g. a new `alumno.codigo` issued
     * for the new enrollment period). `getActiveAlumnos()`'s query has no
     * `ORDER BY`, and previously appended every matching row under the same
     * `by_name` key with no hierarchy resolution, so exact-match resolution
     * picked whichever row the DB happened to return first — not the
     * INV-06-highest-priority estado (reported symptom: matched students
     * showing up mostly as SUSPENDIDO).
     *
     * The lower-priority SUSPENDIDO(9) row is seeded with a lower id (and
     * thus returned first with no ORDER BY) so a naive "first row wins"
     * implementation would fail this test; resolution must depend on the
     * INV-06 hierarchy, not row order.
     *
     * Identity for dedup purposes is `dni`, not the normalized full name —
     * see `it_does_not_merge_two_different_people_sharing_identical_normalized_full_name`
     * below for the companion regression covering the opposite failure mode
     * (two distinct people who happen to share a name must NOT be merged).
     *
     * Traces to: INV-06, US-002 AC-007, test-cases.md TC-005.
     */
    #[Test]
    public function t036_resolves_duplicate_person_records_by_inv06_hierarchy_not_row_order(): void
    {
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'apellido_paterno' => 'MENDOZA',
            'apellido_materno' => 'SILVA',
            'nombres' => 'CARLOS',
            'estado_match' => 'pendiente',
        ]);

        AcademiaDbHelper::ensureTablesAndSeed();

        DB::connection('academia')->table('personas')->insert([
            'dni' => '90000001', 'nombres' => 'CARLOS', 'apellido_paterno' => 'MENDOZA', 'apellido_materno' => 'SILVA',
        ]);
        DB::connection('academia')->table('alumnos')->insert([
            ['codigo' => 'ALUD01', 'persona_dni' => '90000001'],
            ['codigo' => 'ALUD02', 'persona_dni' => '90000001'],
        ]);
        DB::connection('academia')->table('alumno_matricula')->insert([
            ['id' => 900, 'alumno_codigo' => 'ALUD01', 'aula_id' => 1, 'estado' => 9, 'estado_aula' => 1], // SUSPENDIDO — inserted first
            ['id' => 901, 'alumno_codigo' => 'ALUD02', 'aula_id' => 2, 'estado' => 2, 'estado_aula' => 1], // MATRICULADO — inserted second
        ]);

        $action = new RealizarCruceExactoAction();
        $result = $action->execute($ingresante->id);

        expect($result['success'])->toBeTrue();
        expect($result['data']['estado_match'])->toBe('confirmado_automatico');
        expect($result['data']['alumno_id'])->toBe(901);
    }

    /**
     * Regression for the companion CRITICAL bug found in code review of
     * T036: `dedupeByIdentity()` must key on `dni` (personas.dni), never on
     * the normalized full name. Two DISTINCT real students who happen to
     * share an identical normalized name (a real possibility with common
     * Peruvian surnames) must both survive `getActiveAlumnos()` — a
     * name-keyed identity would deterministically drop one of them on every
     * run, turning a rare coincidental name collision into a systematic
     * wrong-person match.
     *
     * Both rows use the same (tied) MATRICULADO(2) estado on purpose: this
     * isolates the identity-key bug from the INV-06 hierarchy tie-break
     * (tracked separately as T037) — even with no estado difference to hide
     * behind, both distinct dnis must remain present.
     *
     * Traces to: INV-06, US-002 AC-007, test-cases.md TC-005 (code review
     * follow-up, 2026-07-07).
     */
    #[Test]
    public function it_does_not_merge_two_different_people_sharing_identical_normalized_full_name(): void
    {
        AcademiaDbHelper::ensureTablesAndSeed();

        DB::connection('academia')->table('personas')->insert([
            ['dni' => '95000001', 'nombres' => 'LUIS', 'apellido_paterno' => 'RAMOS', 'apellido_materno' => 'QUISPE'],
            ['dni' => '95000002', 'nombres' => 'LUIS', 'apellido_paterno' => 'RAMOS', 'apellido_materno' => 'QUISPE'],
        ]);
        DB::connection('academia')->table('alumnos')->insert([
            ['codigo' => 'ALUX01', 'persona_dni' => '95000001'],
            ['codigo' => 'ALUX02', 'persona_dni' => '95000002'],
        ]);
        DB::connection('academia')->table('alumno_matricula')->insert([
            ['id' => 950, 'alumno_codigo' => 'ALUX01', 'aula_id' => 1, 'estado' => 2, 'estado_aula' => 1], // MATRICULADO
            ['id' => 951, 'alumno_codigo' => 'ALUX02', 'aula_id' => 2, 'estado' => 2, 'estado_aula' => 1], // MATRICULADO
        ]);

        $action = new RealizarCruceExactoAction();
        $index = $action->getActiveAlumnos();

        $matchedIds = collect($index['alumnos'])
            ->filter(static fn (array $alumno) => in_array($alumno['id'], [950, 951], true))
            ->pluck('id')
            ->all();
        sort($matchedIds);

        expect($matchedIds)->toBe([950, 951]);
    }

    /**
     * T038: Correction (2026-07-07, PO verification against real production
     * data) — reproduces the production bug at the `getActiveAlumnos()`
     * candidate-pool level: a person re-enrolled across periods has an OLD
     * `alumno_matricula` record (2022) with estado PAGADO(3) and a NEWER
     * record with estado SUSPENDIDO(9). PAGADO outranks SUSPENDIDO in INV-06
     * hierarchy, so the hierarchy-only resolution from T036 incorrectly
     * resolved to the stale PAGADO record. `getActiveAlumnos()` must now
     * resolve to the MOST RECENT record by `am.fecha`, regardless of which
     * estado ranks higher in INV-06.
     *
     * NOTE — scope boundary found during this fix: `ESTADOS_ACTIVOS = [2, 3,
     * 9, 13, 14]` (this class, `CalcularSimilitudesCabosAction`'s fallback
     * query, and `CruceIngresantesController::academiaAlumnos()`) excludes
     * RETIRADO(0)/ANULADO(11)/TRASLADADO(12) from the SQL `WHERE` clause
     * BEFORE dedup ever runs. This test therefore uses PAGADO(3) vs
     * SUSPENDIDO(9) — both already inside that filter — to exercise the
     * actual reachable dedup code path. If a person's ONLY historical record
     * inside the active-estado filter is stale (e.g. an old PAGADO row) and
     * their true current status lives in a RETIRADO/ANULADO/TRASLADADO row
     * that the SQL filter excludes entirely, this recency-first dedup fix
     * cannot surface that — the row never reaches `dedupeByIdentity()` in
     * the first place. Widening `ESTADOS_ACTIVOS` to also treat those codes
     * as "activo" for candidate-pool purposes is a separate, larger business
     * rule change (it would also make previously-unmatchable
     * RETIRADO/ANULADO/TRASLADADO people become match candidates) and is
     * intentionally NOT made here; flagged for product/architecture
     * follow-up.
     *
     * The old/PAGADO row is seeded with a lower id AND an earlier `fecha` so
     * neither "first row wins" nor "hierarchy-only wins" would pass this
     * test — only recency-first resolution does.
     *
     * Traces to: INV-06 correction, tasks.md T038, production incident
     * (2026-07-07, PO-verified against real production data).
     */
    #[Test]
    public function t038_resolves_to_most_recent_record_over_higher_hierarchy_estado(): void
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
            'dni' => '97000001', 'nombres' => 'ANDREA', 'apellido_paterno' => 'FLORES', 'apellido_materno' => 'VEGA',
        ]);
        DB::connection('academia')->table('alumnos')->insert([
            ['codigo' => 'ALUR01', 'persona_dni' => '97000001'],
            ['codigo' => 'ALUR02', 'persona_dni' => '97000001'],
        ]);
        DB::connection('academia')->table('alumno_matricula')->insert([
            ['id' => 970, 'alumno_codigo' => 'ALUR01', 'aula_id' => 1, 'estado' => 3, 'estado_aula' => 1, 'fecha' => '2022-03-15 00:00:00'], // PAGADO — OLD (stale), lower id
            ['id' => 971, 'alumno_codigo' => 'ALUR02', 'aula_id' => 2, 'estado' => 9, 'estado_aula' => 1, 'fecha' => '2026-01-10 00:00:00'], // SUSPENDIDO — NEWER, real current status
        ]);

        $action = new RealizarCruceExactoAction();
        $result = $action->execute($ingresante->id);

        expect($result['success'])->toBeTrue();
        expect($result['data']['estado_match'])->toBe('confirmado_automatico');
        expect($result['data']['alumno_id'])->toBe(971);
    }

    /**
     * T039: Scope-boundary follow-up to T038 (PO decision, 2026-07-07) —
     * `ESTADOS_ACTIVOS` is widened to also include RETIRADO(0) as a valid
     * matching candidate (ANULADO(11) and TRASLADADO(12) stay excluded,
     * deliberately). This reproduces the ORIGINAL reported production bug
     * end-to-end at the level T038 could not reach: a person has an OLD
     * `alumno_matricula` record (PAGADO(3), 2022) and a NEWER record with
     * estado RETIRADO(0). Before this fix, the RETIRADO row never entered
     * the candidate pool at all (filtered out by the SQL `WHERE estado IN
     * (...)` clause), so the stale PAGADO record always won — the T038
     * recency-first dedup had nothing to compare it against. Now RETIRADO
     * is a candidate, and recency-first resolution must pick it because
     * it is the newer record.
     *
     * Traces to: tasks.md T039, T038 scope-boundary note, PO decision
     * (2026-07-07, explicit approval of RETIRADO only; ANULADO/TRASLADADO
     * rejected for this widening).
     */
    #[Test]
    public function t039_widened_active_estados_surfaces_retirado_as_matching_candidate(): void
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
            'dni' => '97000003', 'nombres' => 'DIEGO', 'apellido_paterno' => 'CASTRO', 'apellido_materno' => 'MEJIA',
        ]);
        DB::connection('academia')->table('alumnos')->insert([
            ['codigo' => 'ALUT01', 'persona_dni' => '97000003'],
            ['codigo' => 'ALUT02', 'persona_dni' => '97000003'],
        ]);
        DB::connection('academia')->table('alumno_matricula')->insert([
            ['id' => 990, 'alumno_codigo' => 'ALUT01', 'aula_id' => 1, 'estado' => 3, 'estado_aula' => 1, 'fecha' => '2022-03-15 00:00:00'], // PAGADO — OLD (stale), lower id
            ['id' => 991, 'alumno_codigo' => 'ALUT02', 'aula_id' => 2, 'estado' => 0, 'estado_aula' => 1, 'fecha' => '2026-01-10 00:00:00'], // RETIRADO — NEWER, real current status
        ]);

        $action = new RealizarCruceExactoAction();
        $result = $action->execute($ingresante->id);

        expect($result['success'])->toBeTrue();
        expect($result['data']['estado_match'])->toBe('confirmado_automatico');
        expect($result['data']['alumno_id'])->toBe(991);
    }
}
