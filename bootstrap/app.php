<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // Sanctum SPA auth: treat first-party stateful frontend requests
        // (same-origin fetch from the React SPA) as session-authenticated,
        // so the /api/cruce/* routes can rely on session cookies + CSRF.
        $middleware->statefulApi();

        // Prevent redirecting unauthenticated API requests to a non-existent login route
        $middleware->redirectGuestsTo(fn (Request $request) =>
            $request->is('api/*') ? null : '/'
        );

        // Role gate for the cruce endpoints (see routes/api.php).
        $middleware->alias([
            'role' => \App\Http\Middleware\EnsureRole::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*'),
        );
    })->create();
