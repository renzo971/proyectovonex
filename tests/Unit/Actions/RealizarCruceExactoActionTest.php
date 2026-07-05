<?php

declare(strict_types=1);

namespace Tests\Unit\Actions;

use App\Actions\Cruce\RealizarCruceExactoAction;
use App\Models\Ingresante;
use App\Models\LoteCruce;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

/**
 * Test Suite: RealizarCruceExactoAction
 * Feature ID: 001-motor-cruce-ingresantes
 * Generated from: .specify/specs/001-motor-cruce-ingresantes/test-cases.md
 */
class RealizarCruceExactoActionTest extends TestCase
{
    private RealizarCruceExactoAction $action;

    protected function setUp(): void
    {
        parent::setUp();
        $this->action = new RealizarCruceExactoAction();
    }

    /**
     * TC-006: Cruce exacto automático con 2 apellidos y 1 nombre
     * Traces to: US-003, AC-008, plan.md: RealizarCruceExactoAction
     * Type: Integration
     * Priority: P1
     */
    #[Test]
    public function tc006_performs_exact_match_with_two_surnames_and_one_name(): void
    {
        // Create a lote and ingresante
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'apellido_paterno' => 'LOPEZ',
            'apellido_materno' => 'GARCIA',
            'nombres' => 'JUAN',
            'estado_match' => 'pendiente',
        ]);

        $result = $this->action->execute($ingresante->id);

        expect($result['success'])->toBeTrue();
        expect($result['data']['estado_match'])->toBe('confirmado_automatico');
        expect($result['data']['alumno_id'])->not->toBeNull();
    }

    /**
     * TC-039: Solo RealizarCruceExactoAction puede asignar estado confirmado_automatico (INV-01)
     * Traces to: INV-01, US-003 AC-008
     * Type: Unit
     * Priority: P1
     */
    #[Test]
    public function tc0039_only_this_action_can_assign_confirmado_automatico(): void
    {
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'estado_match' => 'pendiente',
        ]);

        // Try to directly update estado_match — should be rejected
        $result = $ingresante->update(['estado_match' => 'confirmado_automatico']);

        // The invariant should prevent this
        expect($result)->toBeFalse();
        expect($ingresante->fresh()->estado_match)->toBe('pendiente');
    }

    /**
     * TC-003: Coincidencia estricta de CASTILLO TORIBIO DIEGO
     * Traces to: US-003, AC-008, test-cases.md TC-3
     * Type: Integration
     * Priority: P1
     */
    #[Test]
    public function tc003_strict_match_with_extra_middle_name(): void
    {
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'apellido_paterno' => 'CASTILLO',
            'apellido_materno' => 'TORIBIO',
            'nombres' => 'DIEGO',
            'estado_match' => 'pendiente',
        ]);

        $result = $this->action->execute($ingresante->id);

        expect($result['success'])->toBeTrue();
        expect($result['data']['estado_match'])->toBe('confirmado_automatico');
        expect($result['data']['alumno_nombre_completo'])->toContain('CASTILLO TORIBIO DIEGO');
    }
}
