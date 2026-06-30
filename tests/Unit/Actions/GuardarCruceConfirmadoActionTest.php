<?php

declare(strict_types=1);

namespace Tests\Unit\Actions;

use App\Actions\Cruce\GuardarCruceConfirmadoAction;
use App\Models\Ingresante;
use App\Models\LoteCruce;
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
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'estado_match' => 'pendiente',
        ]);

        $alumnoId = 123; // Mock academia alumno ID

        $result = $this->action->execute($ingresante->id, $alumnoId);

        expect($result['success'])->toBeTrue();
        expect($result['data']['estado_match'])->toBe('confirmado_manual');
        expect($result['data']['alumno_id'])->toBe($alumnoId);
    }
}
