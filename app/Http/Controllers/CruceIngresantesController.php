<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Models\LoteCruce;
use App\Models\Ingresante;
use App\Jobs\ProcessCsvBatchJob;
use App\Actions\Cruce\NormalizarTextoAction;
use App\Actions\Cruce\CalcularSimilitudesCabosAction;
use App\Actions\Cruce\GuardarCruceConfirmadoAction;
use App\Actions\Cruce\ExportarExcelCruceAction;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class CruceIngresantesController extends Controller
{
    protected NormalizarTextoAction $normalizer;

    public function __construct()
    {
        $this->normalizer = new NormalizarTextoAction();
    }

    /**
     * Upload and enqueue CSV batch processing.
     */
    public function upload(Request $request): JsonResponse
    {
        if (!$request->hasFile('file')) {
            return response()->json(['success' => false, 'error' => 'No se subió ningún archivo'], 422);
        }

        $file = $request->file('file');

        // Size check (20MB limit)
        if ($file->getSize() > 20 * 1024 * 1024) {
            return response()->json(['success' => false, 'error' => 'El archivo supera el tamaño máximo permitido (20 MB).'], 413);
        }

        $path = $file->getRealPath();
        $content = file_get_contents($path);

        // UTF-8 BOM
        if (str_starts_with($content, "\xEF\xBB\xBF")) {
            $content = substr($content, 3);
        }

        $encoding = mb_detect_encoding($content, ['UTF-8', 'ISO-8859-1'], true);
        if (!$encoding) {
            return response()->json(['success' => false, 'error' => 'El archivo no puede leerse con la codificación detectada. Se acepta UTF-8 o ISO-8859-1.'], 422);
        }
        if ($encoding !== 'UTF-8') {
            $content = mb_convert_encoding($content, 'UTF-8', $encoding);
        }

        $lines = preg_split('/\r\n|\r|\n/', $content);
        $lines = array_filter(array_map('trim', $lines));

        if (count($lines) < 1) {
            return response()->json(['success' => false, 'error' => 'Archivo CSV vacío'], 422);
        }

        $headersLine = array_shift($lines);
        $headers = str_getcsv($headersLine);
        $headers = array_map(function ($h) {
            return trim(mb_strtoupper($h, 'UTF-8'));
        }, $headers);

        $requiredColumns = [
            'CODIGO', 'APELLIDOS', 'NOMBRES', 'EAP', 'PUNTAJE', 'MERITO',
            'OBSERVACION', 'TIPO', 'MODALIDAD', 'UNIVERSIDAD', 'PERIODO', 'FECHA'
        ];

        $missingColumns = array_diff($requiredColumns, $headers);
        if (!empty($missingColumns)) {
            return response()->json([
                'success' => false,
                'error' => 'El archivo CSV no contiene las columnas requeridas: ' . implode(', ', $missingColumns) . '. Verifique el formato e intente nuevamente.'
            ], 422);
        }

        $headerMap = array_flip($headers);

        $dates = [];
        $hasAlcanzoVacante = false;

        foreach ($lines as $line) {
            $data = str_getcsv($line);
            if (count($data) < count($requiredColumns)) {
                continue;
            }

            $obs = trim($data[$headerMap['OBSERVACION']] ?? '');
            $normalizedObs = $this->normalizer->execute($obs);
            if ($normalizedObs === 'ALCANZO VACANTE') {
                $hasAlcanzoVacante = true;
            }

            $date = trim($data[$headerMap['FECHA']] ?? '');
            if ($date !== '') {
                $dates[$date] = true;
            }
        }

        if (!$hasAlcanzoVacante) {
            return response()->json([
                'success' => false,
                'error' => "El archivo no contiene registros con observación 'ALCANZO VACANTE'. Verifique el contenido del CSV."
            ], 422);
        }

        // Store CSV to a persistent temporary path for the queue job
        $savedPath = $file->storeAs('tmp', 'upload-' . time() . '-' . uniqid() . '.csv');
        $absolutePath = storage_path('app/' . $savedPath);

        $firstLote = null;

        foreach (array_keys($dates) as $date) {
            $loteExists = LoteCruce::where('fecha_examen', $date)->exists();
            if ($loteExists) {
                continue;
            }

            $lote = LoteCruce::create([
                'fecha_examen' => $date,
                'estado' => 'processing',
                'started_at' => now(),
            ]);

            if ($firstLote === null) {
                $firstLote = $lote;
            }

            // Dispatch job
            $job = new ProcessCsvBatchJob($lote->id);
            $job->csvPath = $absolutePath;
            dispatch($job);
        }

        if ($firstLote === null) {
            // All dates were already processed
            return response()->json([
                'success' => false,
                'error' => 'Todas las fechas del CSV ya existen en el historial de lotes procesados.'
            ], 422);
        }

        return response()->json([
            'lote_id' => $firstLote->id,
            'estado' => 'processing',
            'message' => 'El archivo CSV está siendo procesado en segundo plano.'
        ], 202);
    }

    /**
     * Get all processed batches.
     */
    public function getLotes(): JsonResponse
    {
        $lotes = LoteCruce::orderBy('created_at', 'desc')->get();
        return response()->json($lotes);
    }

    /**
     * Get status and stats of a batch.
     */
    public function getLoteStatus(int $loteId): JsonResponse
    {
        $lote = LoteCruce::findOrFail($loteId);
        return response()->json($lote);
    }

    /**
     * List unmatched pending resolution.
     */
    public function getPendientes(Request $request, int $loteId): JsonResponse
    {
        $perPage = (int) $request->query('per_page', 15);
        $paginator = Ingresante::where('lote_cruce_id', $loteId)
            ->where('estado_match', 'pendiente')
            ->with('candidatos')
            ->paginate($perPage);

        return response()->json([
            'data' => $paginator->items(),
            'current_page' => $paginator->currentPage(),
            'last_page' => $paginator->lastPage(),
            'per_page' => $paginator->perPage(),
            'total' => $paginator->total(),
        ]);
    }

    /**
     * Query or compute candidates for a single applicant.
     */
    public function getCandidatos(int $id): JsonResponse
    {
        $action = new CalcularSimilitudesCabosAction();
        $result = $action->execute($id);

        if (!$result['success']) {
            return response()->json(['error' => $result['error']], 500);
        }

        return response()->json($result['data']['candidates']);
    }

    /**
     * Confirm match manually or mark as no_ingresado.
     */
    public function confirmar(Request $request, int $id): JsonResponse
    {
        $action = new GuardarCruceConfirmadoAction();
        $result = $action->execute(
            $id,
            $request->input('alumno_id') !== null ? (int)$request->input('alumno_id') : null,
            (bool) $request->input('marcar_no_ingresado', false)
        );

        if (!$result['success']) {
            return response()->json(['error' => $result['error']], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Coincidencia confirmada exitosamente.',
            'data' => $result['data'],
            'ingresante' => $result['data'],
        ]);
    }

    /**
     * Export batch results to Excel.
     */
    public function exportar(int $loteId): BinaryFileResponse|JsonResponse
    {
        $action = new ExportarExcelCruceAction();
        $result = $action->execute($loteId);

        if (!$result['success']) {
            return response()->json(['error' => $result['error']], 404);
        }

        return response()->download($result['data']['file_path'], "reporte-lote-{$loteId}.xlsx");
    }
}
