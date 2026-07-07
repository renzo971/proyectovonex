<?php

declare(strict_types=1);

namespace Tests\Feature\Http\Controllers;

use App\Models\Ingresante;
use App\Models\LoteCruce;
use Illuminate\Support\Facades\DB;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

/**
 * Test Suite: CruceIngresantesController::exportar()
 * Feature ID: 001-motor-cruce-ingresantes
 *
 * T031 (pre-commit review fix): before this fix, `exportar()` called
 * `response()->streamDownload(...)` unconditionally, which sends HTTP
 * headers (200 OK, text/csv) to the client BEFORE the streamed body
 * callback (and therefore before `ExportarExcelCruceAction::execute()`'s
 * generator body, including its academia data load) ever runs. If the
 * academia connection failed, the client had already received a 200 +
 * CSV headers and then got a truncated/corrupted response
 * (`ERR_INVALID_RESPONSE` in the browser) instead of a clean error.
 *
 * These tests force the academia connection to fail and assert the
 * response is a clean JSON 500 — never a started/streamed CSV response.
 */
class CruceIngresantesExportarTest extends TestCase
{
    /**
     * The academia data load must be eager and catchable BEFORE
     * streamDownload() is invoked, so a broken academia connection
     * surfaces as a normal JSON 500 error response instead of a
     * truncated stream.
     *
     * Uses estado_match='confirmado_manual' (not 'confirmado_automatico')
     * since Ingresante::booted()'s INV-01 guard silently blocks saving
     * 'confirmado_automatico' unless Ingresante::$allowAutomaticConfirm is
     * set, which is outside the scope of this fix.
     */
    #[Test]
    public function exportar_returns_clean_json_500_when_academia_fails_before_streaming(): void
    {
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-06-10']);
        Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'estado_match' => 'confirmado_manual',
            'alumno_id' => 1,
        ]);

        config(['database.connections.academia.database' => '/nonexistent-dir-xyz/does-not-exist.sqlite']);
        DB::purge('academia');

        $response = $this->get("/api/cruce/lotes/{$lote->id}/exportar");

        $response->assertStatus(500);
        $response->assertJson(['success' => false]);

        // Prove the stream never started: no CSV content-type/disposition,
        // the JSON error body is the entire response.
        expect((string) $response->headers->get('Content-Type'))->not->toContain('text/csv');
        expect($response->headers->get('Content-Disposition'))->toBeNull();
        expect($response->getContent())->not->toStartWith(chr(0xEF) . chr(0xBB) . chr(0xBF));
    }

    /**
     * Regression guard: when the academia connection is healthy (and no
     * confirmed ingresante references it), exportar() still returns a
     * normal streamed CSV, not the new error branch.
     */
    #[Test]
    public function exportar_still_streams_csv_when_no_academia_lookup_is_needed(): void
    {
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-06-11']);
        Ingresante::factory()->create([
            'lote_cruce_id' => $lote->id,
            'estado_match' => 'confirmado_manual',
            'alumno_id' => null,
        ]);

        $response = $this->get("/api/cruce/lotes/{$lote->id}/exportar");

        $response->assertStatus(200);
        expect((string) $response->headers->get('Content-Type'))->toContain('text/csv');
    }
}
