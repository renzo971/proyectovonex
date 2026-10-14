<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureRole
{
    /**
     * Ensure the authenticated user holds at least one of the given roles.
     *
     * Usage: ->middleware('role:admin') or ->middleware('role:admin,admisiones').
     * Assumes an auth middleware (auth:sanctum) already ran; a missing user
     * yields 401, an authenticated user without a matching role yields 403.
     */
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if ($user === null) {
            return response()->json([
                'success' => false,
                'error' => 'No autenticado.',
            ], 401);
        }

        if (! $user->hasRole(...$roles)) {
            return response()->json([
                'success' => false,
                'error' => 'No tiene permisos para realizar esta acción.',
            ], 403);
        }

        return $next($request);
    }
}
