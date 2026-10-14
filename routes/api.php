<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\AuthController;
use App\Http\Controllers\CruceIngresantesController;

/*
|--------------------------------------------------------------------------
| Public auth endpoint (SPA session login)
|--------------------------------------------------------------------------
| The SPA calls GET /sanctum/csrf-cookie first (registered by Sanctum),
| then POST /login. Uses the `web` middleware so the session store is
| available to establish the login cookie that authenticates the
| /cruce/* group below.
*/
Route::middleware('web')->group(function (): void {
    Route::post('/login', [AuthController::class, 'login']);
});

/*
|--------------------------------------------------------------------------
| Authenticated endpoints
|--------------------------------------------------------------------------
*/
Route::middleware('auth:sanctum')->group(function (): void {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', [AuthController::class, 'me']);
});

/*
|--------------------------------------------------------------------------
| Cruce endpoints (unprotected for development / frontend testing)
|--------------------------------------------------------------------------
*/
Route::prefix('cruce')->group(function (): void {
    // Read
    Route::get('/lotes', [CruceIngresantesController::class, 'lotes']);
    Route::get('/lotes/{lote_id}/status', [CruceIngresantesController::class, 'loteStatus']);
    Route::get('/lotes/{lote_id}/pendientes', [CruceIngresantesController::class, 'pendientes']);
    Route::get('/ingresantes/{id}/candidatos', [CruceIngresantesController::class, 'candidatos']);
    Route::get('/lotes/{lote_id}/exportar', [CruceIngresantesController::class, 'exportar']);

    // Write
    Route::post('/upload', [CruceIngresantesController::class, 'upload']);
    Route::post('/ingresantes/{id}/confirmar', [CruceIngresantesController::class, 'confirmar']);
    Route::post('/{id}/confirmar', [CruceIngresantesController::class, 'confirmar']);

    // Utility
    Route::get('/health', [CruceIngresantesController::class, 'health']);
    Route::get('/academia/alumnos', [CruceIngresantesController::class, 'academiaAlumnos']);

    // Destructive
    Route::delete('/limpiar', [CruceIngresantesController::class, 'limpiar']);
    Route::post('/lotes/{lote_id}/reprocesar', [CruceIngresantesController::class, 'reprocesar']);
});
