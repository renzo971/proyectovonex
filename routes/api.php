<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\CruceIngresantesController;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::post('/cruce/upload', [CruceIngresantesController::class, 'upload']);
Route::get('/cruce/lotes', [CruceIngresantesController::class, 'getLotes']);
Route::get('/cruce/lotes/{lote_id}/status', [CruceIngresantesController::class, 'getLoteStatus']);
Route::get('/cruce/lotes/{lote_id}/pendientes', [CruceIngresantesController::class, 'getPendientes']);
Route::get('/cruce/ingresantes/{id}/candidatos', [CruceIngresantesController::class, 'getCandidatos']);

// Register both confirm path options to support tests and frontend
Route::post('/cruce/ingresantes/{id}/confirmar', [CruceIngresantesController::class, 'confirmar']);
Route::post('/cruce/{id}/confirmar', [CruceIngresantesController::class, 'confirmar']);

Route::get('/cruce/lotes/{lote_id}/exportar', [CruceIngresantesController::class, 'exportar']);
