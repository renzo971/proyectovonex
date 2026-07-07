<?php

declare(strict_types=1);

namespace Tests\Unit\Actions;

use App\Actions\Cruce\ResolverEstadoHierarchy;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

/**
 * Test Suite: ResolverEstadoHierarchy
 * Feature ID: 001-motor-cruce-ingresantes
 *
 * New shared helper (T036) extracting the INV-06 estado-hierarchy resolution
 * logic that RealizarCruceExactoAction and CalcularSimilitudesCabosAction
 * both need when the same person has multiple alumno_matricula records.
 *
 * Traces to: INV-06 (context-bridge.md), spec.md AC-007.
 */
class ResolverEstadoHierarchyTest extends TestCase
{
    /**
     * T036: pickBestEstado() must honor the exact INV-06 immutable order:
     * MATRICULADO(2) > PAGADO(3) > FINALIZADO(14) > SUSPENDIDO(9) >
     * RETIRADO(0) > TRASLADADO(12) > STAND BY(13) > ANULADO(11).
     */
    #[Test]
    public function t036_picks_best_estado_per_inv06_hierarchy(): void
    {
        $cases = [
            [[11, 13], 13],           // ANULADO, STAND BY -> STAND BY
            [[0, 12, 11], 0],         // RETIRADO, TRASLADADO, ANULADO -> RETIRADO
            [[9, 14], 14],            // SUSPENDIDO, FINALIZADO -> FINALIZADO
            [[2, 11, 0], 2],          // MATRICULADO, ANULADO, RETIRADO -> MATRICULADO
            [[11], 11],               // ANULADO alone -> ANULADO
            [[13], 13],               // STAND BY alone -> STAND BY
            [[9, 2, 3, 14, 0, 12, 13, 11], 2], // all present -> MATRICULADO wins
        ];

        foreach ($cases as [$estados, $expected]) {
            expect(ResolverEstadoHierarchy::pickBestEstado($estados))->toBe($expected);
        }
    }

    /**
     * T036: dedupeByIdentity() must collapse rows sharing the same identity
     * key down to a single row — the one with the highest INV-06 priority
     * estado — while leaving rows with distinct identities untouched.
     */
    #[Test]
    public function t036_dedupes_rows_by_identity_keeping_best_estado(): void
    {
        $rows = [
            ['name' => 'MENDOZA|SILVA|CARLOS', 'estado' => 9],  // SUSPENDIDO, appears first
            ['name' => 'MENDOZA|SILVA|CARLOS', 'estado' => 2],  // MATRICULADO, appears second
            ['name' => 'LOPEZ|GARCIA|JUAN', 'estado' => 3],     // distinct person, unaffected
        ];

        $result = ResolverEstadoHierarchy::dedupeByIdentity(
            $rows,
            static fn (array $row) => $row['name'],
            static fn (array $row) => $row['estado'],
        );

        expect($result)->toHaveCount(2);

        $mendoza = array_values(array_filter($result, static fn (array $row) => $row['name'] === 'MENDOZA|SILVA|CARLOS'));
        expect($mendoza)->toHaveCount(1);
        expect($mendoza[0]['estado'])->toBe(2);

        $lopez = array_values(array_filter($result, static fn (array $row) => $row['name'] === 'LOPEZ|GARCIA|JUAN'));
        expect($lopez)->toHaveCount(1);
        expect($lopez[0]['estado'])->toBe(3);
    }

    /**
     * T036: row order in the input must not matter — the best estado wins
     * regardless of whether it appears first or last among duplicates.
     */
    #[Test]
    public function t036_dedupe_is_order_independent(): void
    {
        $rowsBestFirst = [
            ['name' => 'A', 'estado' => 2],
            ['name' => 'A', 'estado' => 9],
        ];
        $rowsBestLast = [
            ['name' => 'A', 'estado' => 9],
            ['name' => 'A', 'estado' => 2],
        ];

        $accessor = static fn (array $row) => $row['estado'];
        $identity = static fn (array $row) => $row['name'];

        $resultBestFirst = array_values(ResolverEstadoHierarchy::dedupeByIdentity($rowsBestFirst, $identity, $accessor));
        $resultBestLast = array_values(ResolverEstadoHierarchy::dedupeByIdentity($rowsBestLast, $identity, $accessor));

        expect($resultBestFirst)->toHaveCount(1);
        expect($resultBestLast)->toHaveCount(1);
        expect($resultBestFirst[0]['estado'])->toBe(2);
        expect($resultBestLast[0]['estado'])->toBe(2);
    }

    /**
     * T038: Correction (2026-07-07, PO verification against real production
     * data) — dedupeByIdentity() must resolve by RECENCY first when a
     * $dateAccessor is supplied, regardless of INV-06 hierarchy. A stale
     * historical record with a higher-priority estado (PAGADO=3, an older
     * date) must NOT outrank the person's real current record (RETIRADO=0,
     * a newer date), even though PAGADO ranks above RETIRADO in INV-06.
     *
     * This reproduces the exact production bug: a RETIRADO student was
     * exported/matched as PAGADO because a stale 2022 record won purely on
     * hierarchy, with no regard for recency.
     *
     * Traces to: INV-06 correction, tasks.md T038, production incident
     * (2026-07-07, PO-verified).
     */
    #[Test]
    public function t038_recency_wins_over_inv06_hierarchy_when_date_accessor_provided(): void
    {
        $rows = [
            ['name' => 'X', 'estado' => 3, 'fecha' => '2022-03-15'],  // PAGADO — OLD (stale)
            ['name' => 'X', 'estado' => 0, 'fecha' => '2026-01-10'],  // RETIRADO — NEWER (current, real status)
        ];

        $result = ResolverEstadoHierarchy::dedupeByIdentity(
            $rows,
            static fn (array $row) => $row['name'],
            static fn (array $row) => $row['estado'],
            static fn (array $row) => $row['fecha'],
        );

        expect($result)->toHaveCount(1);
        $winner = array_values($result)[0];
        expect($winner['estado'])->toBe(0);
        expect($winner['fecha'])->toBe('2026-01-10');
    }

    /**
     * T038: recency-first resolution must be order-independent — the most
     * recent row wins whether it appears first or last in the input, exactly
     * like the pre-existing hierarchy-only order-independence guarantee.
     */
    #[Test]
    public function t038_recency_resolution_is_order_independent(): void
    {
        $identity = static fn (array $row) => $row['name'];
        $estado = static fn (array $row) => $row['estado'];
        $fecha = static fn (array $row) => $row['fecha'];

        $newestFirst = [
            ['name' => 'A', 'estado' => 0, 'fecha' => '2026-01-10'],
            ['name' => 'A', 'estado' => 3, 'fecha' => '2022-03-15'],
        ];
        $newestLast = [
            ['name' => 'A', 'estado' => 3, 'fecha' => '2022-03-15'],
            ['name' => 'A', 'estado' => 0, 'fecha' => '2026-01-10'],
        ];

        $resultA = array_values(ResolverEstadoHierarchy::dedupeByIdentity($newestFirst, $identity, $estado, $fecha));
        $resultB = array_values(ResolverEstadoHierarchy::dedupeByIdentity($newestLast, $identity, $estado, $fecha));

        expect($resultA[0]['estado'])->toBe(0);
        expect($resultB[0]['estado'])->toBe(0);
    }

    /**
     * T038: a row with a usable date must always beat a row with no date at
     * all, regardless of hierarchy — an undated legacy row must never win
     * over a dated one just because its estado ranks higher.
     */
    #[Test]
    public function t038_dated_row_beats_undated_row_regardless_of_hierarchy(): void
    {
        $rows = [
            ['name' => 'A', 'estado' => 2, 'fecha' => null],       // MATRICULADO but undated
            ['name' => 'A', 'estado' => 0, 'fecha' => '2026-01-10'], // RETIRADO but dated
        ];

        $result = array_values(ResolverEstadoHierarchy::dedupeByIdentity(
            $rows,
            static fn (array $row) => $row['name'],
            static fn (array $row) => $row['estado'],
            static fn (array $row) => $row['fecha'],
        ));

        expect($result[0]['estado'])->toBe(0);
    }

    /**
     * T038: when both contending rows are tied on the exact same date (or
     * both lack a usable date entirely), INV-06 hierarchy is used as the
     * tie-break, exactly as it always has been.
     */
    #[Test]
    public function t038_falls_back_to_inv06_hierarchy_when_dates_tie_or_are_both_missing(): void
    {
        $sameDate = [
            ['name' => 'A', 'estado' => 9, 'fecha' => '2026-01-10'],  // SUSPENDIDO
            ['name' => 'A', 'estado' => 2, 'fecha' => '2026-01-10'],  // MATRICULADO — same date, higher hierarchy
        ];
        $bothUndated = [
            ['name' => 'B', 'estado' => 9, 'fecha' => null],
            ['name' => 'B', 'estado' => 2, 'fecha' => null],
        ];

        $identity = static fn (array $row) => $row['name'];
        $estado = static fn (array $row) => $row['estado'];
        $fecha = static fn (array $row) => $row['fecha'];

        $resultSameDate = array_values(ResolverEstadoHierarchy::dedupeByIdentity($sameDate, $identity, $estado, $fecha));
        $resultBothUndated = array_values(ResolverEstadoHierarchy::dedupeByIdentity($bothUndated, $identity, $estado, $fecha));

        expect($resultSameDate[0]['estado'])->toBe(2);
        expect($resultBothUndated[0]['estado'])->toBe(2);
    }

    /**
     * T038: omitting $dateAccessor entirely must preserve the exact
     * pre-existing hierarchy-only behavior (backward compatibility guard —
     * no caller is forced to adopt recency).
     */
    #[Test]
    public function t038_hierarchy_only_behavior_is_unchanged_when_date_accessor_omitted(): void
    {
        $rows = [
            ['name' => 'A', 'estado' => 9],  // SUSPENDIDO, appears first
            ['name' => 'A', 'estado' => 2],  // MATRICULADO, appears second
        ];

        $result = array_values(ResolverEstadoHierarchy::dedupeByIdentity(
            $rows,
            static fn (array $row) => $row['name'],
            static fn (array $row) => $row['estado'],
        ));

        expect($result)->toHaveCount(1);
        expect($result[0]['estado'])->toBe(2);
    }
}
