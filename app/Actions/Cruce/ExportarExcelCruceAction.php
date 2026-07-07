<?php

declare(strict_types=1);

namespace App\Actions\Cruce;

use App\Models\LoteCruce;
use Illuminate\Support\Facades\DB;

class ExportarExcelCruceAction
{
    // Columns per AC-014: A–X (24 columns)
    public const HEADERS = [
        'CODIGO',       // A - ingresante.codigo
        'DNI',          // B - personas.dni (from academia)
        'APELLIDOS',    // C - ingresante.apellidos
        'NOMBRES',      // D - ingresante.nombres
        'EAP',          // E - ingresante.eap
        'PUNTAJE',      // F - ingresante.puntaje
        'MERITO',       // G - ingresante.merito
        'OBSERVACION',  // H - ingresante.observacion
        'TIPO',         // I - ingresante.tipo
        'MODALIDAD',    // J - ingresante.modalidad
        'UNIVERSIDAD',  // K - ingresante.universidad
        'PERIODO',      // L - ingresante.periodo (from CSV)
        'FECHA',        // M - ingresante.fecha
        'ANIO',         // N - matriculas.anio (from academia)
        'SEDE',         // O - locales.nombre (from academia)
        'CICLO',        // P - periodos.ciclos (from academia)
        'F-MATRICULA',  // Q - alumno_matricula.fecha (from academia)
        'CEL-ALUMNO',   // R - personas.telefono (from academia)
        'CEL-APODERADO',// S - personas.telefono2 (from academia)
        'ESTADO',       // T - alumno_matricula.estado label (INV-06 hierarchy)
        'LISTA-1',      // U - 1 if periodo >= Verano 2024
        'LISTA-2',      // V - 1 if enrolled in active cycles around Feb 2026
        'LISTA-3',      // W - 1 if active (MATRICULADO/PAGADO/FINALIZADO) at Feb 27, 2026
        'AREA',         // X - EAP mapped to A-E per UNMSM rules
    ];

    // Estado label per INV-06 hierarchy (context-bridge.md, spec.md AC-007).
    // Must stay in sync with CruceIngresantesController::academiaAlumnos().
    private const ESTADO_LABELS = [
        0  => 'RETIRADO',
        2  => 'MATRICULADO',
        3  => 'PAGADO',
        9  => 'SUSPENDIDO',
        11 => 'ANULADO',
        12 => 'TRASLADADO',
        13 => 'STAND BY',
        14 => 'FINALIZADO',
    ];

    // Periods that qualify as "Verano 2024 or later" for LISTA-1
    // We compare period names, so we do it dynamically
    private const LISTA1_CUTOFF_KEYWORDS = ['VERANO 2024', 'REPASO 2024', 'MARZO 2024', 'ABRIL 2024', 'MAYO 2024', 'JUNIO 2024', 'JULIO 2024', 'AGOSTO 2024', 'SETIEMBRE 2024', 'OCTUBRE 2024', 'NOVIEMBRE 2024', 'DICIEMBRE 2024', 'VERANO 2025', 'REPASO 2025', 'MARZO 2025', 'ABRIL 2025', 'MAYO 2025', 'JUNIO 2025', 'JULIO 2025', 'AGOSTO 2025', 'SETIEMBRE 2025', 'OCTUBRE 2025', 'NOVIEMBRE 2025', 'DICIEMBRE 2025', 'VERANO 2026', 'REPASO 2026', 'MARZO 2026', 'ABRIL 2026', 'MAYO 2026'];

    // Periods that qualify for LISTA-2 (active around Feb 2026 or Oct 2025 cycles)
    private const LISTA2_KEYWORDS = ['OCTUBRE 2025', 'NOVIEMBRE 2025', 'DICIEMBRE 2025', 'VERANO 2026', 'REPASO 2026', 'ENERO 2026', 'FEBRERO 2026', 'MARZO 2026'];

    // States that are "active" for LISTA-3 (at Feb 27, 2026) per INV-06:
    // MATRICULADO (2), PAGADO (3), FINALIZADO (14).
    private const LISTA3_ACTIVE_ESTADOS = [2, 3, 14];

    /**
     * Eagerly loads academia data for a lote's matched alumni. Must be
     * called (and any exception caught) BEFORE the caller starts an HTTP
     * stream/download response, since `execute()`'s generator body would
     * otherwise only run this query lazily, after headers are already
     * flushed to the client (see Fix 1, pre-commit review: production
     * ERR_INVALID_RESPONSE when the academia connection failed mid-stream).
     */
    public function loadAcademiaDataFor(LoteCruce $lote): array
    {
        $alumnoIds = DB::table('ingresantes')
            ->where('lote_cruce_id', $lote->id)
            ->whereIn('estado_match', ['confirmado_automatico', 'confirmado_manual'])
            ->whereNotNull('alumno_id')
            ->pluck('alumno_id')
            ->unique()
            ->toArray();

        // Build academia data map: alumno_matricula.id => enriched row
        return $this->loadAcademiaData($alumnoIds);
    }

    /**
     * Streams enriched rows for a lote. `$academiaData` must be pre-loaded
     * via `loadAcademiaDataFor()` BEFORE calling this method — no academia
     * DB access happens inside this generator body, so it is safe to call
     * from within a streamDownload() callback.
     */
    public function execute(LoteCruce $lote, array $academiaData): \Generator
    {
        $ingresantes = DB::table('ingresantes')
            ->where('lote_cruce_id', $lote->id)
            ->whereIn('estado_match', ['confirmado_automatico', 'confirmado_manual'])
            ->orderBy('apellidos')
            ->orderBy('nombres')
            ->cursor();

        foreach ($ingresantes as $ing) {
            $academia = isset($ing->alumno_id) ? ($academiaData[$ing->alumno_id] ?? null) : null;

            yield $this->buildRow($ing, $academia);
        }
    }

    /**
     * Maximum number of ids per chunk for the non-Postgres (e.g. sqlite test) IN() fallback.
     * Keeps each query well under typical driver bound-parameter ceilings.
     */
    private const FALLBACK_CHUNK_SIZE = 900;

    private function loadAcademiaData(array $alumnoMatriculaIds): array
    {
        if (empty($alumnoMatriculaIds)) {
            return [];
        }

        $connection = DB::connection('academia');

        $selectSql = "
            SELECT
                am.id                   AS am_id,
                p.dni,
                p.telefono              AS cel_alumno,
                p.telefono2             AS cel_apoderado,
                am.estado               AS am_estado,
                am.fecha                AS fecha_matricula,
                m.anio,
                l.nombre                AS local_nombre,
                per.nombre              AS periodo_nombre,
                per.ciclos              AS ciclo
            FROM alumno_matricula am
            JOIN alumnos a            ON a.codigo = am.alumno_codigo
            JOIN personas p           ON p.dni = a.persona_dni
            JOIN aulas au             ON au.id = am.aula_id
            JOIN matriculas m         ON m.id = au.matricula_id
            JOIN periodos per         ON per.id = m.periodo_id
            LEFT JOIN locales l       ON l.id = m.local_id
            WHERE am.id %s
        ";

        if ($connection->getDriverName() === 'pgsql') {
            // Single bound parameter regardless of list size — avoids Laravel's
            // Illuminate\Database\Connection::bindValues() positional binding
            // (binds non-string keys at position $key + 1), which throws
            // SQLSTATE[HY093] once the ids array has non-sequential keys
            // (e.g. after ->pluck()->unique()->toArray()) and/or exceeds the
            // number of literal "?" placeholders actually present in the SQL.
            $rows = $connection->select(
                sprintf($selectSql, '= ANY(?::bigint[])'),
                [$this->buildPgArrayLiteral($alumnoMatriculaIds)]
            );
        } else {
            // Non-Postgres fallback (e.g. sqlite in-memory used by the test suite,
            // see phpunit.xml DB_ACADEMIA_DRIVER=sqlite): Postgres' ANY(?::bigint[])
            // array literal isn't understood here, so keep a chunked IN (...) query.
            // array_values() re-indexes to sequential integer keys first, which is
            // itself enough to fix the positional-binding bug for this driver;
            // chunking is an extra safety margin against the driver's own bound
            // parameter ceiling on very large lists.
            $ids = array_values($alumnoMatriculaIds);
            $rows = [];

            foreach (array_chunk($ids, self::FALLBACK_CHUNK_SIZE) as $chunk) {
                $placeholders = implode(',', array_fill(0, count($chunk), '?'));
                $rows = array_merge(
                    $rows,
                    $connection->select(sprintf($selectSql, "IN ({$placeholders})"), $chunk)
                );
            }
        }

        $map = [];
        foreach ($rows as $row) {
            $map[(int) $row->am_id] = $row;
        }

        return $map;
    }

    /**
     * Builds a Postgres `bigint[]` array literal (e.g. "{1,2,3}") from a
     * list of ids, independent of any DB connection/driver so it can be
     * unit-tested directly (Fix 2, pre-commit review: the pgsql query path
     * itself has no test coverage since phpunit.xml forces the sqlite
     * fallback driver for the academia connection).
     *
     * Values are coerced via array_map('intval', ...) so the method is
     * safe-by-construction rather than relying on callers to only ever
     * pass clean integers.
     */
    private function buildPgArrayLiteral(array $ids): string
    {
        return '{' . implode(',', array_map('intval', $ids)) . '}';
    }

    private function buildRow(object $ing, ?object $academia): array
    {
        $eap = (string) ($ing->eap ?? '');

        return [
            $ing->codigo,
            $academia?->dni ?? '',
            $ing->apellidos,
            $ing->nombres,
            $eap,
            $ing->puntaje,
            $ing->merito,
            $ing->observacion,
            $ing->tipo,
            $ing->modalidad,
            $ing->universidad,
            $ing->periodo,
            $ing->fecha,
            $academia?->anio ?? '',
            $academia?->local_nombre ?? '',
            $academia?->ciclo ?? '',
            $academia?->fecha_matricula ?? '',
            $academia?->cel_alumno ?? '',
            $academia?->cel_apoderado ?? '',
            $this->resolveEstado($academia),
            $this->calcLista1($academia),
            $this->calcLista2($academia),
            $this->calcLista3($academia),
            $this->resolveArea($eap),
        ];
    }

    private function resolveEstado(?object $academia): string
    {
        if ($academia === null) {
            return '';
        }

        return self::ESTADO_LABELS[(int) $academia->am_estado] ?? (string) $academia->am_estado;
    }

    private function calcLista1(?object $academia): int
    {
        if ($academia === null) {
            return 0;
        }

        $periodoNombre = strtoupper(trim((string) ($academia->periodo_nombre ?? '')));

        foreach (self::LISTA1_CUTOFF_KEYWORDS as $keyword) {
            if (str_contains($periodoNombre, $keyword)) {
                return 1;
            }
        }

        return 0;
    }

    private function calcLista2(?object $academia): int
    {
        if ($academia === null) {
            return 0;
        }

        $periodoNombre = strtoupper(trim((string) ($academia->periodo_nombre ?? '')));

        // LISTA-2 is period-only: unlike LISTA-3 it does not filter by
        // estado, so students who are RETIRADO (0) or SUSPENDIDO (9) in one
        // of the qualifying cycles are still counted, per spec (tasks.md
        // LISTA-2 definition).
        foreach (self::LISTA2_KEYWORDS as $keyword) {
            if (str_contains($periodoNombre, $keyword)) {
                return 1;
            }
        }

        return 0;
    }

    private function calcLista3(?object $academia): int
    {
        if ($academia === null) {
            return 0;
        }

        $estado = (int) ($academia->am_estado ?? 0);

        // Active as of Feb 27, 2026 per INV-06: MATRICULADO (2), PAGADO (3), FINALIZADO (14)
        if (!in_array($estado, self::LISTA3_ACTIVE_ESTADOS, true)) {
            return 0;
        }

        $periodoNombre = strtoupper(trim((string) ($academia->periodo_nombre ?? '')));

        // Must be in a cycle that was active on Feb 27, 2026
        foreach (self::LISTA2_KEYWORDS as $keyword) {
            if (str_contains($periodoNombre, $keyword)) {
                return 1;
            }
        }

        return 0;
    }

    private function resolveArea(string $eap): string
    {
        $eapUpper = strtoupper($eap);

        // Area A: Ciencias de la Salud
        foreach (['MEDICINA', 'OBSTETRICIA', 'ENFERMERIA', 'TECNOLOGIA MEDICA', 'ODONTOLOGIA', 'FARMACIA', 'VETERINARIA', 'PSICOLOGIA'] as $kw) {
            if (str_contains($eapUpper, $kw)) {
                return 'A';
            }
        }

        // Area B: Ciencias Básicas
        foreach (['QUIMICA', 'BIOLOGICAS', 'FISICA', 'MATEMATICA', 'ESTADISTICA'] as $kw) {
            if (str_contains($eapUpper, $kw)) {
                return 'B';
            }
        }

        // Area C: Ingenierías
        foreach (['INGENIERIA', 'SOFTWARE', 'SISTEMAS', 'INDUSTRIAL', 'CIVIL'] as $kw) {
            if (str_contains($eapUpper, $kw)) {
                return 'C';
            }
        }

        // Area D: Ciencias Económicas y de la Gestión
        foreach (['ADMINISTRACION', 'NEGOCIOS', 'CONTABILIDAD', 'ECONOMIA'] as $kw) {
            if (str_contains($eapUpper, $kw)) {
                return 'D';
            }
        }

        // Area E: Humanidades y Ciencias Jurídicas y Sociales
        foreach (['DERECHO', 'POLITICA', 'LITERATURA', 'FILOSOFIA', 'COMUNICACION', 'ARTE', 'ARQUEOLOGIA', 'EDUCACION', 'HISTORIA', 'TRABAJO SOCIAL'] as $kw) {
            if (str_contains($eapUpper, $kw)) {
                return 'E';
            }
        }

        return '';
    }
}
