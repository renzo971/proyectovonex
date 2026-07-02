<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Actions\Cruce\CalcularSimilitudesCabosAction;
use App\Actions\Cruce\GuardarCruceConfirmadoAction;
use App\Actions\Cruce\ProcesarCargaCsvAction;
use App\Jobs\ProcessCsvBatchJob;
use App\Models\Ingresante;
use App\Models\LoteCruce;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class CruceIngresantesController extends Controller
{
    public function upload(Request $request): JsonResponse
    {
        if (!$request->hasFile('file')) {
            return response()->json([
                'success' => false,
                'error' => 'No se envió ningún archivo.',
            ], 422);
        }

        $file = $request->file('file');

        if ($file->getSize() > 20 * 1024 * 1024) {
            return response()->json([
                'success' => false,
                'error' => 'El archivo supera el tamaño máximo permitido (20 MB).',
            ], 413);
        }

        if (!$file->getClientOriginalExtension() === 'csv' && $file->getMimeType() !== 'text/csv') {
            return response()->json([
                'success' => false,
                'error' => 'El archivo debe ser un CSV.',
            ], 422);
        }

        $path = $file->store('csv-uploads');

        ProcessCsvBatchJob::dispatch(Storage::path($path));

        return response()->json([
            'success' => true,
            'estado' => 'processing',
            'message' => 'Archivo encolado para procesamiento.',
        ], 202);
    }

    public function health(): JsonResponse
    {
        $checks = [];

        $checks[] = [
            'name' => 'conexion_academia',
            'status' => 'checking',
        ];

        try {
            DB::connection('academia')->select('SELECT 1 AS alive');
            $checks[] = [
                'name' => 'conexion_academia',
                'status' => 'ok',
                'message' => 'Conexión exitosa a BD academia',
            ];
        } catch (\Exception $e) {
            $checks[] = [
                'name' => 'conexion_academia',
                'status' => 'error',
                'message' => $e->getMessage(),
            ];
        }

        $checks[] = [
            'name' => 'consulta_alumnos',
            'status' => 'checking',
        ];

        try {
            $count = DB::connection('academia')
                ->table('alumno_matricula')
                ->whereIn('estado', [2, 3, 9, 13])
                ->where('estado_aula', 1)
                ->count();

            $checks[] = [
                'name' => 'consulta_alumnos',
                'status' => 'ok',
                'message' => "{$count} alumnos activos encontrados",
            ];
        } catch (\Exception $e) {
            $checks[] = [
                'name' => 'consulta_alumnos',
                'status' => 'error',
                'message' => $e->getMessage(),
            ];
        }

        $allOk = collect($checks)->every(fn ($c) => ($c['status'] ?? '') === 'ok');

        return response()->json([
            'success' => $allOk,
            'checks' => $checks,
            'timestamp' => now()->toIso8601String(),
        ]);
    }

    public function academiaAlumnos(): JsonResponse
    {
        try {
            $alumnos = DB::connection('academia')->select("
                SELECT
                    am.id AS alumno_id,
                    p.apellido_paterno,
                    p.apellido_materno,
                    p.nombres,
                    p.dni,
                    am.estado,
                    am.estado_aula
                FROM alumno_matricula am
                JOIN alumnos a ON am.alumno_codigo = a.codigo
                JOIN personas p ON a.persona_dni = p.dni
                WHERE am.estado IN (2, 3, 9, 13, 14)
                  AND am.estado_aula = 1
                ORDER BY p.apellido_paterno, p.apellido_materno, p.nombres
                LIMIT 50
            ");

            $estados = [
                0 => 'RETIRADO',
                2 => 'MATRICULADO',
                3 => 'PAGADO',
                9 => 'SUSPENDIDO',
                11 => 'ANULADO',
                12 => 'TRASLADADO',
                13 => 'STAND BY',
                14 => 'FINALIZADO',
            ];

            $data = array_map(function ($row) use ($estados) {
                return [
                    'alumno_id' => (int) $row->alumno_id,
                    'apellido_paterno' => $row->apellido_paterno,
                    'apellido_materno' => $row->apellido_materno,
                    'nombres' => $row->nombres,
                    'dni' => $row->dni,
                    'estado_num' => (int) $row->estado,
                    'estado_texto' => $estados[(int) $row->estado] ?? 'DESCONOCIDO',
                ];
            }, $alumnos);

            return response()->json([
                'success' => true,
                'total' => count($data),
                'data' => $data,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function candidatos(int $id): JsonResponse
    {
        $ingresante = Ingresante::findOrFail($id);

        $action = app(CalcularSimilitudesCabosAction::class);
        $result = $action->execute($id);

        if (!$result['success']) {
            return response()->json($result, 500);
        }

        $candidates = array_map(function ($c) {
            return [
                'alumno_id' => $c['alumno_id'],
                'nombre_completo' => $c['nombre_completo'] ?? '',
                'apellido_paterno' => $c['apellido_paterno'] ?? '',
                'apellido_materno' => $c['apellido_materno'] ?? '',
                'nombres' => $c['nombres'] ?? '',
                'porcentaje_similitud' => $c['porcentaje_similitud'],
            ];
        }, $result['data']['candidates']);

        return response()->json([
            'success' => true,
            'data' => [
                'candidates' => $candidates,
                'no_ingresado_option' => $result['data']['no_ingresado_option'],
            ],
        ]);
    }

    public function confirmar(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'alumno_id' => 'nullable|integer',
        ]);

        $action = app(GuardarCruceConfirmadoAction::class);
        $result = $action->execute($id, $request->integer('alumno_id'));

        $status = isset($result['http_status']) ? $result['http_status'] : ($result['success'] ? 200 : 422);

        return response()->json($result, $status);
    }

    public function lotes(Request $request): JsonResponse
    {
        $query = LoteCruce::query();

        $q = trim((string) $request->query('q', ''));
        if ($q !== '') {
            $like = '%' . str_replace(['%', '_'], ['\\%', '\\_'], $q) . '%';
            $query->where('fecha_examen', 'ilike', $like);
        }

        $lotes = $query->orderBy('created_at', 'desc')
            ->paginate($request->integer('per_page', 50));

        return response()->json([
            'success' => true,
            'data' => $lotes->items(),
            'meta' => [
                'current_page' => $lotes->currentPage(),
                'last_page' => $lotes->lastPage(),
                'per_page' => $lotes->perPage(),
                'total' => $lotes->total(),
            ],
        ]);
    }

    public function loteStatus(int $loteId): JsonResponse
    {
        $lote = LoteCruce::findOrFail($loteId);

        $data = $lote->toArray();
        $data['fuzzy_progress'] = null;

        if (($lote->total_pendientes ?? 0) > 0) {
            $processed = min($lote->fuzzy_procesados ?? 0, $lote->total_pendientes);
            $data['fuzzy_progress'] = round(($processed / $lote->total_pendientes) * 100, 1);
        }

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }

    public function pendientes(Request $request, int $loteId): JsonResponse
    {
        $lote = LoteCruce::findOrFail($loteId);

        $query = $lote->ingresantes()
            ->where('estado_match', 'pendiente');

        $q = trim((string) $request->query('q', ''));
        if ($q !== '') {
            $like = '%' . str_replace(['%', '_'], ['\\%', '\\_'], $q) . '%';
            $query->where(function ($w) use ($like) {
                $w->where('codigo', 'ilike', $like)
                    ->orWhere('apellido_paterno', 'ilike', $like)
                    ->orWhere('apellido_materno', 'ilike', $like)
                    ->orWhere('nombres', 'ilike', $like)
                    ->orWhere('apellidos', 'ilike', $like)
                    ->orWhere('eap', 'ilike', $like);
            });
        }

        $pendientes = $query
            ->withCount('ingresanteCandidatos')
            ->addSelect([
                'max_similitud' => \App\Models\IngresanteCandidato::selectRaw('COALESCE(MAX(porcentaje_similitud), 0)')
                    ->whereColumn('ingresante_id', 'ingresantes.id'),
            ])
            ->orderByDesc('ingresante_candidatos_count')
            ->orderByDesc('max_similitud')
            ->orderBy('apellido_paterno')
            ->orderBy('apellido_materno')
            ->paginate($request->integer('per_page', 50));

        return response()->json([
            'success' => true,
            'data' => $pendientes->items(),
            'meta' => [
                'current_page' => $pendientes->currentPage(),
                'last_page' => $pendientes->lastPage(),
                'per_page' => $pendientes->perPage(),
                'total' => $pendientes->total(),
            ],
        ]);
    }

    public function limpiar(): JsonResponse
    {
        try {
            DB::statement('TRUNCATE TABLE ingresante_candidatos, no_ingresantes, ingresantes, lotes_cruce RESTART IDENTITY CASCADE');

            return response()->json([
                'success' => true,
                'message' => 'Base de datos de cruce limpiada correctamente.',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function reprocesar(int $loteId): JsonResponse
    {
        $lote = LoteCruce::findOrFail($loteId);

        try {
            $action = app(\App\Actions\Cruce\RealizarCruceExactoAction::class);
            $result = $action->executeBatch($lote);

            if (!$result['success']) {
                return response()->json([
                    'success' => false,
                    'error' => $result['error'] ?? 'Error en matching exacto',
                ], 500);
            }

            $pendientes = $lote->ingresantes()
                ->where('estado_match', 'pendiente')
                ->get();

            $fuzzyAction = app(\App\Actions\Cruce\CalcularSimilitudesCabosAction::class);
            $computados = 0;

            foreach ($pendientes as $ingresante) {
                $fuzzyAction->execute($ingresante->id);
                $computados++;
            }

            $lote->update([
                'estado' => 'completed',
                'completed_at' => now(),
                'total_match_exacto' => $lote->ingresantes()->where('estado_match', 'confirmado_automatico')->count(),
                'total_pendientes' => $lote->ingresantes()->where('estado_match', 'pendiente')->count(),
            ]);

            return response()->json([
                'success' => true,
                'data' => [
                    'exact_match' => $result['data']['total_matched'] ?? 0,
                    'fuzzy_computados' => $computados,
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
