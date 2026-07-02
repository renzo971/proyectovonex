<?php

declare(strict_types=1);

use App\Http\Controllers\CruceIngresantesController;
use Illuminate\Support\Facades\Route;

Route::prefix('cruce')->group(function () {
    Route::get('/health', [CruceIngresantesController::class, 'health']);
    Route::get('/academia/alumnos', [CruceIngresantesController::class, 'academiaAlumnos']);
    Route::post('/upload', [CruceIngresantesController::class, 'upload']);
    Route::get('/ingresantes/{id}/candidatos', [CruceIngresantesController::class, 'candidatos']);
    Route::post('/ingresantes/{id}/confirmar', [CruceIngresantesController::class, 'confirmar']);
    Route::post('/{id}/confirmar', [CruceIngresantesController::class, 'confirmar']);
    Route::post('/lotes/{loteId}/reprocesar', [CruceIngresantesController::class, 'reprocesar']);
    Route::delete('/limpiar', [CruceIngresantesController::class, 'limpiar']);
    Route::get('/lotes', [CruceIngresantesController::class, 'lotes']);
    Route::get('/lotes/{loteId}/status', [CruceIngresantesController::class, 'loteStatus']);
    Route::get('/lotes/{loteId}/pendientes', [CruceIngresantesController::class, 'pendientes']);
});
