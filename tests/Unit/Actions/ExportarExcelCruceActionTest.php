<?php

declare(strict_types=1);

namespace Tests\Unit\Actions;

use App\Actions\Cruce\ExportarExcelCruceAction;
use App\Models\Ingresante;
use App\Models\LoteCruce;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use PHPUnit\Framework\Attributes\Test;
use ReflectionMethod;
use Tests\TestCase;

/**
 * Test Suite: ExportarExcelCruceAction
 * Feature ID: 001-motor-cruce-ingresantes
 * Generated from: .specify/specs/001-motor-cruce-ingresantes/test-cases.md
 */
class ExportarExcelCruceActionTest extends TestCase
{
    private ExportarExcelCruceAction $action;

    protected function setUp(): void
    {
        parent::setUp();
        $this->action = new ExportarExcelCruceAction();
    }

    /**
     * Creates the minimal `academia` schema required by loadAcademiaData()'s
     * query (personas, alumnos, alumno_matricula, aulas, matriculas, periodos,
     * locales) directly on the test's academia connection.
     *
     * Note: AcademiaDbHelper (app/Actions/Cruce/AcademiaDbHelper.php) is used by
     * other Cruce actions' tests but creates a different, narrower schema (no
     * `periodos`/`locales` tables, no `personas.telefono2`) that does not satisfy
     * this action's query. Each test method gets a fresh sqlite ':memory:' academia
     * connection (empirically verified: schema does NOT persist across test
     * methods), so defining a local schema here is safe and does not collide with
     * other test classes.
     */
    private function setUpAcademiaSchema(): void
    {
        Schema::connection('academia')->create('personas', function ($table) {
            $table->string('dni')->primary();
            $table->string('telefono')->nullable();
            $table->string('telefono2')->nullable();
        });

        Schema::connection('academia')->create('alumnos', function ($table) {
            $table->string('codigo')->primary();
            $table->string('persona_dni');
        });

        Schema::connection('academia')->create('alumno_matricula', function ($table) {
            $table->id();
            $table->string('alumno_codigo');
            $table->unsignedBigInteger('aula_id');
            $table->smallInteger('estado');
            $table->timestamp('fecha')->useCurrent();
        });

        Schema::connection('academia')->create('aulas', function ($table) {
            $table->id();
            $table->unsignedBigInteger('matricula_id');
        });

        Schema::connection('academia')->create('periodos', function ($table) {
            $table->id();
            $table->string('nombre');
            $table->string('ciclos')->nullable();
        });

        Schema::connection('academia')->create('locales', function ($table) {
            $table->id();
            $table->string('nombre');
        });

        Schema::connection('academia')->create('matriculas', function ($table) {
            $table->id();
            $table->integer('anio')->nullable();
            $table->unsignedBigInteger('periodo_id');
            $table->unsignedBigInteger('local_id')->nullable();
        });

        DB::connection('academia')->table('periodos')->insert([
            'id' => 1, 'nombre' => 'VERANO 2024', 'ciclos' => '2024-I',
        ]);
        DB::connection('academia')->table('locales')->insert([
            'id' => 1, 'nombre' => 'SEDE CENTRAL',
        ]);
        DB::connection('academia')->table('matriculas')->insert([
            'id' => 1, 'anio' => 2024, 'periodo_id' => 1, 'local_id' => 1,
        ]);
        DB::connection('academia')->table('aulas')->insert([
            'id' => 1, 'matricula_id' => 1,
        ]);
    }

    /**
     * Seeds `$count` alumno_matricula rows (with matching alumnos/personas), all
     * pointing at the single shared aula/matricula/periodo/local seeded by
     * setUpAcademiaSchema(), and returns the list of am_id values seeded.
     */
    private function seedAlumnoMatriculas(int $count): array
    {
        $personas = [];
        $alumnos = [];
        $matriculasAlumno = [];
        $ids = [];

        for ($i = 1; $i <= $count; $i++) {
            $dni = 'DNI' . $i;
            $codigo = 'COD' . $i;

            $personas[] = ['dni' => $dni, 'telefono' => '9' . str_pad((string) $i, 8, '0', STR_PAD_LEFT), 'telefono2' => null];
            $alumnos[] = ['codigo' => $codigo, 'persona_dni' => $dni];
            $matriculasAlumno[] = ['id' => $i, 'alumno_codigo' => $codigo, 'aula_id' => 1, 'estado' => 2];
            $ids[] = $i;
        }

        DB::connection('academia')->table('personas')->insert($personas);
        DB::connection('academia')->table('alumnos')->insert($alumnos);
        DB::connection('academia')->table('alumno_matricula')->insert($matriculasAlumno);

        return $ids;
    }

    /**
     * Builds a sparse-keyed array shaped like the real caller's
     * `DB::table('ingresantes')->...->pluck('alumno_id')->unique()->toArray()`
     * output: a plucked Collection has sequential 0-based keys, and ->unique()
     * removes duplicate values while KEEPING the original key of the first
     * occurrence — so once at least one duplicate is removed, the remaining
     * keys are no longer contiguous (gaps appear where duplicates were removed).
     */
    private function toSparseKeyedArray(array $sequentialIds): array
    {
        $sparse = [];
        $key = 0;

        foreach ($sequentialIds as $i => $id) {
            $sparse[$key] = $id;
            // introduce a gap every few elements, simulating removed duplicates
            $key += ($i % 5 === 4) ? 2 : 1;
        }

        return $sparse;
    }

    private function invokeLoadAcademiaData(array $alumnoMatriculaIds): array
    {
        $method = new ReflectionMethod(ExportarExcelCruceAction::class, 'loadAcademiaData');
        $method->setAccessible(true);

        return $method->invoke($this->action, $alumnoMatriculaIds);
    }

    private function invokeBuildPgArrayLiteral(array $ids): string
    {
        $method = new ReflectionMethod(ExportarExcelCruceAction::class, 'buildPgArrayLiteral');
        $method->setAccessible(true);

        return $method->invoke($this->action, $ids);
    }

    /**
     * TC-034: Mapeo de EAP a AREA académica en UNMSM
     * Traces to: US-005, AC-014, plan.md: ExportarExcelCruceAction
     * Type: Unit
     * Priority: P1
     */
    #[Test]
    public function tc034_maps_eap_to_academic_area(): void
    {
        $testCases = [
            'MEDICINA HUMANA' => 'Area A',
            'CIENCIAS BIOLOGICAS' => 'Area B',
            'INGENIERIA DE SOFTWARE' => 'Area C',
            'ADMINISTRACION' => 'Area D',
            'DERECHO' => 'Area E',
        ];

        foreach ($testCases as $eap => $expectedArea) {
            $result = $this->action->resolveArea($eap);
            expect($result)->toBe($expectedArea);
        }
    }

    /**
     * TC-035: Validación de la estructura de 24 columnas del reporte final
     * Traces to: US-005, AC-014
     * Type: Integration
     * Priority: P1
     */
    #[Test]
    public function tc035_validates_24_column_structure(): void
    {
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
        Ingresante::factory()->count(3)->create([
            'lote_cruce_id' => $lote->id,
            'estado_match' => 'confirmado_automatico',
        ]);

        $result = $this->action->execute($lote->id);

        expect($result['success'])->toBeTrue();
        expect($result['data']['column_count'])->toBe(24);
    }

    /**
     * TC-036: Cálculo de LISTA - 1 (Cachimbos Históricos)
     * Traces to: US-005, AC-014
     * Type: Unit
     * Priority: P1
     */
    #[Test]
    public function tc036_calculates_lista_1_cachimbos_historicos(): void
    {
        $testCases = [
            'Verano 2024' => 1,
            'Verano 2025' => 1,
            'Anual 2023' => 0,
            'Repaso 2025' => 1,
        ];

        foreach ($testCases as $periodo => $expected) {
            $result = $this->action->calculateLista1($periodo);
            expect($result)->toBe($expected);
        }
    }

    /**
     * TC-037: Cálculo de LISTA - 2 (Cachimbos Temporada)
     * Traces to: US-005, AC-014
     * Type: Unit
     * Priority: P1
     */
    #[Test]
    public function tc037_calculates_lista_2_cachimbos_temporada(): void
    {
        $testCases = [
            ['periodo' => 'VERANO 2026', 'estado' => 'RETIRADO', 'expected' => 1],
            ['periodo' => 'OCTUBRE 2025', 'estado' => 'SUSPENDIDO', 'expected' => 1],
            ['periodo' => 'ANUAL 2025', 'estado' => 'MATRICULADO', 'expected' => 0],
        ];

        foreach ($testCases as $case) {
            $result = $this->action->calculateLista2($case['periodo'], $case['estado']);
            expect($result)->toBe($case['expected']);
        }
    }

    /**
     * TC-038: Cálculo de LISTA - 3 (Cachimbos Activos a Febrero 2026)
     * Traces to: US-005, AC-014
     * Type: Unit
     * Priority: P1
     */
    #[Test]
    public function tc038_calculates_lista_3_cachimbos_activos_febrero_2026(): void
    {
        $testCases = [
            ['estado' => 'MATRICULADO', 'expected' => 1],
            ['estado' => 'PAGADO', 'expected' => 1],
            ['estado' => 'FINALIZADO', 'expected' => 1],
            ['estado' => 'RETIRADO', 'expected' => 0],
            ['estado' => 'SUSPENDIDO', 'expected' => 0],
            ['estado' => 'ANULADO', 'expected' => 0],
        ];

        foreach ($testCases as $case) {
            $result = $this->action->calculateLista3($case['estado'], '2026-02-27');
            expect($result)->toBe($case['expected']);
        }
    }

    /**
     * TC-007: Integridad estructural del Excel - Hoja 1 y Hoja 2
     * Traces to: US-005, AC-014, AC-015, test-cases.md TC-7
     * Type: Integration
     * Priority: P1
     */
    #[Test]
    public function tc007_excel_contains_dual_sheet_structure(): void
    {
        $lote = LoteCruce::factory()->create(['fecha_examen' => '2026-05-17']);
        Ingresante::factory()->count(20)->create([
            'lote_cruce_id' => $lote->id,
        ]);

        $result = $this->action->execute($lote->id);

        expect($result['success'])->toBeTrue();
        expect($result['data']['sheets'])->toContain('Hoja 1');
        expect($result['data']['sheets'])->toContain('Hoja 2');
        expect($result['data']['columnas_csv'])->toHaveCount(13); // A-M
        expect($result['data']['columnas_enriquecidas'])->toContain('Sede');
        expect($result['data']['columnas_enriquecidas'])->toContain('Ciclo');
        expect($result['data']['columnas_enriquecidas'])->toContain('Estado');
        expect($result['data']['has_dashboard'])->toBeTrue();
    }

    /**
     * T030: loadAcademiaData() must not throw "Invalid parameter number" /
     * "column index out of range" for large id lists with non-sequential
     * (gapped) integer keys, e.g. the shape produced in production by
     * DB::table('ingresantes')->...->pluck('alumno_id')->unique()->toArray().
     *
     * Root cause: Illuminate\Database\Connection::bindValues() binds
     * non-string array keys at PDO position ($key + 1). A manual "?"-per-id
     * IN (...) query only has as many "?" placeholders as count($ids), so once
     * duplicates are removed by ->unique() (which preserves original, now
     * non-contiguous, keys) the max key can exceed the placeholder count,
     * causing PDO to reject the bind position. Reproduced here at production
     * incident scale (~1300 ids) via the academia connection's real driver
     * (sqlite in this test environment; pgsql in production) so the fixed
     * driver-aware branch in loadAcademiaData() is exercised for real.
     *
     * Traces to: production incident on GET /api/cruce/lotes/3/exportar
     * (T030, discovered live during QA of 001-motor-cruce-ingresantes).
     */
    #[Test]
    public function t030_load_academia_data_handles_large_gapped_key_id_lists(): void
    {
        $this->setUpAcademiaSchema();
        $sequentialIds = $this->seedAlumnoMatriculas(1300);
        $sparseIds = $this->toSparseKeyedArray($sequentialIds);

        // Sanity-check the fixture actually has non-sequential keys, otherwise
        // this test would not exercise the bug at all.
        expect(array_keys($sparseIds))->not->toBe(range(0, count($sparseIds) - 1));

        $result = $this->invokeLoadAcademiaData($sparseIds);

        expect($result)->toHaveCount(1300);
        expect($result[1]->dni)->toBe('DNI1');
        expect($result[1300]->dni)->toBe('DNI1300');
    }

    /**
     * T030: small-scale regression guard — a handful of ids (including a
     * non-sequential-key shape) must still return the exact same enriched
     * data as before the fix (no behavior regression from the driver-aware
     * rewrite of loadAcademiaData()).
     */
    #[Test]
    public function t030_load_academia_data_small_scale_returns_correct_data(): void
    {
        $this->setUpAcademiaSchema();
        $sequentialIds = $this->seedAlumnoMatriculas(4);
        $sparseIds = $this->toSparseKeyedArray($sequentialIds);

        $result = $this->invokeLoadAcademiaData($sparseIds);

        expect($result)->toHaveCount(4);
        foreach ([1, 2, 3, 4] as $id) {
            expect($result[$id]->dni)->toBe('DNI' . $id);
            expect($result[$id]->am_estado)->toBe(2);
            expect($result[$id]->periodo_nombre)->toBe('VERANO 2024');
            expect($result[$id]->local_nombre)->toBe('SEDE CENTRAL');
        }
    }

    /**
     * T030: empty id list must short-circuit to an empty map without touching
     * the academia connection (unchanged behavior from before the fix).
     */
    #[Test]
    public function t030_load_academia_data_returns_empty_map_for_empty_ids(): void
    {
        $result = $this->invokeLoadAcademiaData([]);

        expect($result)->toBe([]);
    }

    /**
     * Fix 2 (pre-commit review, CRITICAL): the actual production code path
     * (`= ANY(?::bigint[])` against pgsql) never runs under the test suite
     * because phpunit.xml forces DB_ACADEMIA_DRIVER=sqlite. The pgsql branch
     * only ever "verified" this string-building logic by code inspection.
     * Extracting it into a pure, driver-independent method lets us test the
     * exact literal Postgres expects for a bigint[] parameter directly,
     * without needing a real Postgres connection.
     */
    #[Test]
    public function build_pg_array_literal_formats_ids_as_curly_brace_csv_with_no_spaces(): void
    {
        $result = $this->invokeBuildPgArrayLiteral([1, 2, 3]);

        expect($result)->toBe('{1,2,3}');
    }

    /**
     * Defensive: empty input is handled safely even though callers already
     * short-circuit before reaching this method — never emit a malformed
     * literal like "{}".
     */
    #[Test]
    public function build_pg_array_literal_handles_empty_array_defensively(): void
    {
        $result = $this->invokeBuildPgArrayLiteral([]);

        expect($result)->toBe('{}');
    }

    /**
     * Reuses the same gapped-key fixture shape as T030 (produced by
     * ->pluck('alumno_id')->unique()->toArray()) to confirm the literal
     * builder ignores array keys entirely and only cares about values, in
     * the exact order/format Postgres expects.
     */
    #[Test]
    public function build_pg_array_literal_handles_large_gapped_key_array(): void
    {
        $sequentialIds = range(1, 1300);
        $sparseIds = $this->toSparseKeyedArray($sequentialIds);

        $result = $this->invokeBuildPgArrayLiteral($sparseIds);

        expect($result)->toStartWith('{1,2,3,');
        expect($result)->toEndWith(',1299,1300}');
        expect(substr_count($result, ','))->toBe(1299);
        expect($result)->not->toContain(' ');
    }

    /**
     * Defensive-by-construction (SUGGESTION from the pre-commit review): the
     * method must coerce values to int itself via array_map('intval', ...)
     * rather than relying on caller discipline, so a stray numeric string
     * still produces a clean bigint[] literal instead of quoted garbage.
     */
    #[Test]
    public function build_pg_array_literal_coerces_values_to_int(): void
    {
        $result = $this->invokeBuildPgArrayLiteral(['5', '10', 3]);

        expect($result)->toBe('{5,10,3}');
    }
}
