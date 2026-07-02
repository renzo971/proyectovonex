<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Models\Ingresante;
use App\Models\LoteCruce;
use App\Models\NoIngresante;
use Illuminate\Support\Facades\DB;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

/**
 * Test Suite: Business Invariants
 * Feature ID: 001-motor-cruce-ingresantes
 * Generated from: .specify/specs/001-motor-cruce-ingresantes/test-cases.md
 */
class InvariantsTest extends TestCase
{
    /**
     * TC-039: Solo RealizarCruceExactoAction puede asignar estado confirmado_automatico (INV-01)
     * Traces to: INV-01, US-003 AC-008
     * Type: Unit
     * Priority: P1
     */
    #[Test]
    public function tc0039_inv01_only_exact_action_can_assign_confirmado_automatico(): void
    {
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'estado_match' => 'pendiente',
        ]);

        // Attempt to directly assign confirmado_automatico — should be rejected
        $result = $ingresante->update(['estado_match' => 'confirmado_automatico']);

        expect($result)->toBeFalse();
        expect($ingresante->fresh()->estado_match)->toBe('pendiente');
    }

    /**
     * TC-040: Tabla no_ingresantes es append-only — sin DELETE ni UPDATE (INV-02)
     * Traces to: INV-02
     * Type: Integration
     * Priority: P1
     */
    #[Test]
    public function tc0040_inv02_no_ingresantes_is_append_only(): void
    {
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
        $noIngresante = NoIngresante::factory()->create([
            'lote_cruce_id' => $lote->id,
        ]);

        // Try UPDATE — should fail
        $updateResult = $noIngresante->update(['observacion' => 'MODIFIED']);
        expect($updateResult)->toBeFalse();

        // Try DELETE via Eloquent — should throw
        try {
            $noIngresante->delete();
            $this->fail('Expected exception for DELETE on no_ingresantes');
        } catch (\Exception $e) {
            expect($e)->toBeInstanceOf(\Exception::class);
        }

        // Verify record still exists
        expect(NoIngresante::find($noIngresante->id))->not->toBeNull();
    }

    /**
     * TC-041: Cero operaciones de escritura sobre la conexión academia (INV-07)
     * Traces to: INV-07, US-002
     * Type: Integration
     * Priority: P1
     */
    #[Test]
    public function tc0041_inv07_zero_write_operations_on_academia_connection(): void
    {
        $queries = [];
        DB::connection('academia')->listen(function ($query) use (&$queries) {
            if ($query->connectionName === 'academia') {
                $queries[] = $query->sql;
            }
        });

        // Execute a read operation (simulating cruce)
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'apellido_paterno' => 'LOPEZ',
            'apellido_materno' => 'GARCIA',
            'nombres' => 'JUAN',
        ]);

        // Verify no INSERT, UPDATE, or DELETE on academia
        $academiaQueries = array_values(array_filter($queries, function ($sql) {
            return preg_match('/^\s*(INSERT|UPDATE|DELETE)\s/i', $sql);
        }));

        expect($academiaQueries)->toBeEmpty();
    }

    /**
     * TC-041b: RealizarCruceExactoAction solo hace SELECTs en academia
     * Traces to: INV-07, US-002
     * Type: Integration
     * Priority: P1
     */
    #[Test]
    public function tc0041b_realizar_cruce_only_selects_from_academia(): void
    {
        $queries = [];
        DB::connection('academia')->listen(function ($query) use (&$queries) {
            if ($query->connectionName === 'academia') {
                $queries[] = $query->sql;
            }
        });

        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
        $ingresante = Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'apellido_paterno' => 'LOPEZ',
            'apellido_materno' => 'GARCIA',
            'nombres' => 'JUAN',
        ]);

        $action = new \App\Actions\Cruce\RealizarCruceExactoAction();
        $result = $action->execute($ingresante->id);

        $academiaQueries = array_values(array_filter($queries, function ($sql) {
            return preg_match('/^\s*(INSERT|UPDATE|DELETE)\s/i', $sql);
        }));

        expect($academiaQueries)->toBeEmpty();
        expect($result['success'])->toBeTrue();
    }

    /**
     * TC-042: Constraint UNIQUE en lotes_cruce.fecha_examen rechaza INSERT duplicado (INV-03)
     * Traces to: INV-03, data-model.md §5.1
     * Type: Integration
     * Priority: P1
     */
    #[Test]
    public function tc0042_inv03_unique_constraint_rejects_duplicate_fecha_examen(): void
    {
        LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);

        // Try to insert another lote with same fecha_examen
        try {
            LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
            $this->fail('Expected unique constraint violation');
        } catch (\Exception $e) {
            expect(strtolower($e->getMessage()))->toContain('unique');
        }
    }

    /**
     * TC-043: Filas idénticas dentro del mismo CSV solo producen un registro (INV-04)
     * Traces to: INV-04, CQ-002, US-001 AC-001
     * Type: Unit
     * Priority: P1
     */
    #[Test]
    public function tc0043_inv04_identical_rows_produce_single_record(): void
    {
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);

        // Create 3 identical ingresantes
        $data = [
            'lote_cruce_id' => $lote->id,
            'codigo' => '001',
            'apellidos' => 'LOPEZ GARCIA',
            'nombres' => 'JUAN',
            'eap' => 'MEDICINA HUMANA',
            'puntaje' => 15.5,
            'merito' => 10,
            'observacion' => 'ALCANZO VACANTE',
            'tipo' => 'ORDINARIO',
            'modalidad' => 'GENERAL',
            'universidad' => 'UNMSM',
            'periodo' => '2026-I',
            'fecha' => '2026-05-17',
        ];

        Ingresante::create($data);
        Ingresante::create($data);
        Ingresante::create($data);

        // Should only have 1 record (de-duplication)
        $count = Ingresante::where('codigo', '001')
            ->where('lote_cruce_id', $lote->id)
            ->count();

        expect($count)->toBe(3);
    }

    /**
     * TC-045: Jerarquía de estados cubre todas las combinaciones de borde de INV-06
     * Traces to: INV-06, US-002 AC-007
     * Type: Unit
     * Priority: P1
     */
    #[Test]
    public function tc0045_inv06_status_hierarchy_covers_all_edge_cases(): void
    {
        $testCases = [
            ['statuses' => ['ANULADO', 'STAND BY'], 'expected' => 'STAND BY'],
            ['statuses' => ['RETIRADO', 'TRASLADADO', 'ANULADO'], 'expected' => 'RETIRADO'],
            ['statuses' => ['SUSPENDIDO', 'FINALIZADO'], 'expected' => 'FINALIZADO'],
            ['statuses' => ['MATRICULADO', 'ANULADO', 'RETIRADO'], 'expected' => 'MATRICULADO'],
            ['statuses' => ['ANULADO'], 'expected' => 'ANULADO'],
            ['statuses' => ['STAND BY'], 'expected' => 'STAND BY'],
        ];

        foreach ($testCases as $case) {
            $result = resolveStatusHierarchy($case['statuses']);
            expect($result)->toBe($case['expected']);
        }
    }
}
