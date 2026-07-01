<?php

declare(strict_types=1);

namespace Tests\Unit\Actions;

use App\Actions\Cruce\RealizarCruceExactoAction;
use App\Models\Ingresante;
use App\Models\LoteCruce;
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
}
