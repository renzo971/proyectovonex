<?php

declare(strict_types=1);

namespace Tests\Unit\Actions;

use App\Actions\Cruce\AcademiaDbHelper;
use App\Actions\Cruce\GuardarCruceConfirmadoAction;
use App\Models\Ingresante;
use App\Models\LoteCruce;
use Illuminate\Support\Facades\DB;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

/**
 * Test Suite: GuardarCruceConfirmadoAction
 * Feature ID: 001-motor-cruce-ingresantes
 * Generated from: .specify/specs/001-motor-cruce-ingresantes/test-cases.md
 */
class GuardarCruceConfirmadoActionTest extends TestCase
{
    private GuardarCruceConfirmadoAction $action;

    protected function setUp(): void
    {
        parent::setUp();
        $this->action = new GuardarCruceConfirmadoAction();
    }

    /**
     * TC-009: Interfaz pendiente muestra candidato ordenado y confirma match manual
     * Traces to: US-004, AC-011, AC-012, AC-013, plan.md: UnmatchedRow.jsx, api.js
     * Type: E2E
     * Priority: P1
     */
    #[Test]
    public function tc009_confirms_manual_match_from_assisted_validation(): void
    {
        // Existence of alumno_id is now enforced (AC-G3.3), so the fixture must
        // reference a real seeded academia record instead of an arbitrary id.
        AcademiaDbHelper::ensureTablesAndSeed();
        $alumnoId = DB::connection('academia')->table('alumno_matricula')->orderBy('id')->value('id');

        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'estado_match' => 'pendiente',
        ]);

        $result = $this->action->execute($ingresante->id, $alumnoId);

        expect($result['success'])->toBeTrue();
        expect($result['data']['estado_match'])->toBe('confirmado_manual');
        expect($result['data']['alumno_id'])->toBe($alumnoId);
    }

    /**
     * TC-010: Validación asistida - confirmar match manual desde UI React
     * Traces to: US-004, AC-011, AC-012, test-cases.md TC-10
     * Type: Integration
     * Priority: P1
     */
    #[Test]
    public function tc010_confirms_manual_match_via_api_endpoint(): void
    {
        // Existence of alumno_id is now enforced (AC-G3.3), so the fixture must
        // reference a real seeded academia record instead of an arbitrary id.
        AcademiaDbHelper::ensureTablesAndSeed();
        $alumnoId = DB::connection('academia')->table('alumno_matricula')->orderBy('id')->value('id');

        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'apellido_paterno' => 'GONZALES',
            'apellido_materno' => 'DE LA FLOR',
            'nombres' => 'PEDRO',
            'estado_match' => 'pendiente',
        ]);

        $response = $this->postJson("/api/cruce/{$ingresante->id}/confirmar", [
            'alumno_id' => $alumnoId,
        ]);

        $response->assertStatus(200);
        $response->assertJson([
            'success' => true,
            'data' => [
                'estado_match' => 'confirmado_manual',
            ],
        ]);
    }

    /**
     * AC-G3.1 / AC-G3.2: marcar_no_ingresado=true with no alumno_id in payload
     * forwards to the Action's no-match branch: estado_match='no_ingresado',
     * alumno_id=null, lote total_pendientes -1, total_no_ingresado +1.
     */
    #[Test]
    public function acg31_acg32_marcar_no_ingresado_true_sets_no_ingresado_and_updates_lote_counters(): void
    {
        $lote = LoteCruce::factory()->create([
            'fecha_examen' => '2026-06-01',
            'total_pendientes' => 1,
            'total_no_ingresado' => 0,
        ]);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'estado_match' => 'pendiente',
        ]);

        $response = $this->postJson("/api/cruce/{$ingresante->id}/confirmar", [
            'marcar_no_ingresado' => true,
        ]);

        $response->assertStatus(200);

        $ingresante->refresh();
        $lote->refresh();

        expect($ingresante->estado_match)->toBe('no_ingresado');
        expect($ingresante->alumno_id)->toBeNull();
        expect($lote->total_pendientes)->toBe(0);
        expect($lote->total_no_ingresado)->toBe(1);
    }

    /**
     * AC-G3.2: when marcar_no_ingresado=true, ANY alumno_id present in the
     * payload must be ignored/discarded — never persisted.
     */
    #[Test]
    public function acg32_marcar_no_ingresado_true_ignores_alumno_id_if_present(): void
    {
        $lote = LoteCruce::factory()->create([
            'fecha_examen' => '2026-06-02',
            'total_pendientes' => 1,
        ]);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'estado_match' => 'pendiente',
        ]);

        $response = $this->postJson("/api/cruce/{$ingresante->id}/confirmar", [
            'marcar_no_ingresado' => true,
            'alumno_id' => 12345,
        ]);

        $response->assertStatus(200);

        $ingresante->refresh();

        expect($ingresante->alumno_id)->toBeNull();
    }

    /**
     * AC-G3.3: marcar_no_ingresado absent and no alumno_id in the payload must
     * return HTTP 422 (Laravel's standard validation error) and leave the
     * ingresante's state unchanged.
     */
    #[Test]
    public function acg33_missing_alumno_id_returns_422_and_leaves_state_unchanged(): void
    {
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-06-03']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'estado_match' => 'pendiente',
        ]);

        $response = $this->postJson("/api/cruce/{$ingresante->id}/confirmar", []);

        $response->assertStatus(422);

        $ingresante->refresh();
        expect($ingresante->estado_match)->toBe('pendiente');
    }

    /**
     * AC-G3.3: marcar_no_ingresado absent, alumno_id present but does NOT exist
     * in the seeded academia data must return HTTP 404 without calling the
     * Action, so the ingresante state is provably unchanged.
     */
    #[Test]
    public function acg33_nonexistent_alumno_id_returns_404_and_leaves_state_unchanged(): void
    {
        AcademiaDbHelper::ensureTablesAndSeed();

        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-06-04']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'estado_match' => 'pendiente',
        ]);

        $response = $this->postJson("/api/cruce/{$ingresante->id}/confirmar", [
            'alumno_id' => 99999999,
        ]);

        $response->assertStatus(404);
        $response->assertJson([
            'success' => false,
            'error' => 'El alumno seleccionado no existe en la base de datos.',
        ]);

        $ingresante->refresh();
        expect($ingresante->estado_match)->toBe('pendiente');
    }

    /**
     * AC-G3.4: posting alumno_id=0 with marcar_no_ingresado absent must return
     * 404 (not a corrupt 200 success with alumno_id null/0 persisted).
     */
    #[Test]
    public function acg34_alumno_id_zero_returns_404_not_a_corrupt_success(): void
    {
        AcademiaDbHelper::ensureTablesAndSeed();

        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-06-05']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'estado_match' => 'pendiente',
        ]);

        $response = $this->postJson("/api/cruce/{$ingresante->id}/confirmar", [
            'alumno_id' => 0,
        ]);

        $response->assertStatus(404);

        $ingresante->refresh();
        expect($ingresante->estado_match)->toBe('pendiente');
        expect($ingresante->alumno_id)->toBeNull();
    }

    /**
     * AC-G3.3 (happy path): marcar_no_ingresado absent, alumno_id present and
     * DOES exist in seeded academia data -> HTTP 200, confirmado_manual
     * persisted with that real alumno_id.
     */
    #[Test]
    public function acg33_existing_alumno_id_confirms_manual_match(): void
    {
        AcademiaDbHelper::ensureTablesAndSeed();

        $realAlumnoId = DB::connection('academia')->table('alumno_matricula')->orderBy('id')->value('id');
        expect($realAlumnoId)->not->toBeNull();

        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-06-06']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'estado_match' => 'pendiente',
        ]);

        $response = $this->postJson("/api/cruce/{$ingresante->id}/confirmar", [
            'alumno_id' => $realAlumnoId,
        ]);

        $response->assertStatus(200);

        $ingresante->refresh();
        expect($ingresante->estado_match)->toBe('confirmado_manual');
        expect($ingresante->alumno_id)->toBe($realAlumnoId);
    }

    /**
     * ERR-003 / graceful degradation: if the academia connection fails while
     * validating alumno_id, confirmar must return a structured JSON error
     * (not an uncaught QueryException), and the ingresante state must be
     * left unchanged.
     */
    #[Test]
    public function acg_confirmar_returns_graceful_error_when_academia_connection_fails(): void
    {
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-06-07']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'estado_match' => 'pendiente',
        ]);

        config(['database.connections.academia.database' => '/nonexistent-dir-xyz/does-not-exist.sqlite']);
        DB::purge('academia');

        $response = $this->postJson("/api/cruce/{$ingresante->id}/confirmar", [
            'alumno_id' => 1,
        ]);

        $response->assertStatus(500);
        $response->assertJson(['success' => false]);

        $ingresante->refresh();
        expect($ingresante->estado_match)->toBe('pendiente');
    }

    /**
     * AC-G3.3 (active-matrícula filter): an alumno_id that exists in
     * alumno_matricula but belongs to a retired/annulled matrícula (estado
     * outside the active set) must be rejected exactly like a nonexistent
     * alumno_id — 404 / ERR-006 — never confirmed as a match.
     */
    #[Test]
    public function acg_confirmar_rejects_alumno_id_with_inactive_estado(): void
    {
        AcademiaDbHelper::ensureTablesAndSeed();

        $retiredId = 9001;
        DB::connection('academia')->table('alumno_matricula')->insert([
            'id' => $retiredId,
            'alumno_codigo' => 'ALU001',
            'aula_id' => 1,
            'estado' => 11, // ANULADO — outside the active estado set
            'estado_aula' => 1,
        ]);

        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-06-08']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'estado_match' => 'pendiente',
        ]);

        $response = $this->postJson("/api/cruce/{$ingresante->id}/confirmar", [
            'alumno_id' => $retiredId,
        ]);

        $response->assertStatus(404);
        $response->assertJson([
            'success' => false,
            'error' => 'El alumno seleccionado no existe en la base de datos.',
        ]);

        $ingresante->refresh();
        expect($ingresante->estado_match)->toBe('pendiente');
    }

    /**
     * AC-G3.3 (active-matrícula filter): an alumno_id that exists with an
     * allowed estado but whose estado_aula != 1 must also be rejected as
     * invalid — the aula must be active, not just the enrollment estado.
     */
    #[Test]
    public function acg_confirmar_rejects_alumno_id_with_inactive_estado_aula(): void
    {
        AcademiaDbHelper::ensureTablesAndSeed();

        $inactiveAulaId = 9002;
        DB::connection('academia')->table('alumno_matricula')->insert([
            'id' => $inactiveAulaId,
            'alumno_codigo' => 'ALU001',
            'aula_id' => 1,
            'estado' => 2, // MATRICULADO — allowed estado
            'estado_aula' => 0, // inactive aula
        ]);

        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-06-09']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'estado_match' => 'pendiente',
        ]);

        $response = $this->postJson("/api/cruce/{$ingresante->id}/confirmar", [
            'alumno_id' => $inactiveAulaId,
        ]);

        $response->assertStatus(404);
        $response->assertJson([
            'success' => false,
            'error' => 'El alumno seleccionado no existe en la base de datos.',
        ]);

        $ingresante->refresh();
        expect($ingresante->estado_match)->toBe('pendiente');
    }
}
