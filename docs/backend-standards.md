---
description: Backend development standards, best practices, and conventions for the VX Intranet Laravel 5.8 application including Actions pattern, Eloquent ORM, controllers, and PHP 7.1+ guidelines.
globs: ["app/**/*.php", "config/**/*.php", "database/**/*.php", "routes/**/*.php", "tests/**/*.php"]
alwaysApply: true
---

# Backend Project Standards and Best Practices

## 1. Overview & Technology Stack

The backend of the VX Intranet is a legacy application built on **Laravel 5.8** and **PHP 7.1+**. It interfaces with a **MySQL** database. To keep the codebase maintainable, testable, and clean, all new logic must follow the **Actions Pattern** alongside Laravel's controllers and models.

### Core Stack
- **Framework**: Laravel 5.8
- **Language**: PHP ^7.1 (typically running under PHP 7.4/8.0 in local environments, but maintaining strict compatibility with 7.1+ features)
- **Database**: MySQL

---

## 2. Architecture & Conventions

We follow a strict architectural hierarchy to keep controllers thin and logic maintainable.

### 2.1 The Actions Pattern
All complex business logic, data persistence, and database operations must be delegated to dedicated **Action** classes inside `app/Actions/`.
- **Single Responsibility**: Each Action class should perform exactly one operation and expose a single public method named `execute()`.
- **Method Signature**: The `execute()` method accepts parameters strictly typed where possible, and returns a structured array with at least a `success` boolean indicator, a `data` element (or result model/collection), and an `error` string/array when applicable.
- **Dependency Injection**: Inject required services or dependencies via constructor or resolve them dynamically using Laravel's container.

*Example Action class:*
```php
<?php

declare(strict_types=1);

namespace App\Actions\AulaFusion;

use App\Aula;
use Exception;

/**
 * Obtener un aula completa con todos sus datos secundarios.
 */
class GetAulaCompletaAction
{
    /**
     * Ejecutar la acción.
     *
     * @param int $aulaId ID del aula
     * @return array{success: bool, aula: ?\App\Aula, error: ?string}
     */
    public function execute(int $aulaId): array
    {
        try {
            $aula = Aula::find($aulaId);

            if (!$aula) {
                return [
                    'success' => false,
                    'aula' => null,
                    'error' => 'Aula no encontrada',
                ];
            }

            return [
                'success' => true,
                'aula' => $aula,
                'error' => null,
            ];

        } catch (Exception $e) {
            return [
                'success' => false,
                'aula' => null,
                'error' => 'Error al obtener el aula: ' . $e->getMessage(),
            ];
        }
    }
}
```

### 2.2 Controllers
Controllers should only handle HTTP concerns: validating incoming request parameters, invoking the appropriate Action, and returning a Blade view or a JSON response.
- **Thin Controllers**: No business logic, calculations, or raw updates should exist directly in controllers.
- **Dependency Injection**: Laravel automatically resolves dependency injection for Actions injected directly as parameters in controller methods.
- **Validation**: Use `$request->validate([...])` or `$this->validate($request, [...])` at the start of the controller methods.
- **Responses**: Return `response()->json([...])` for AJAX requests and standard `view('view-name', $data)` for Blade page renders.

*Example Controller method:*
```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Actions\AulaFusion\GetAulaCompletaAction;

class AulaFusionController extends Controller
{
    /**
     * Obtener aula completa con todos sus datos secundarios.
     *
     * @param Request $request Request HTTP
     * @param GetAulaCompletaAction $action Acción para obtener aula completa
     * @return JsonResponse
     */
    public function obtenerAulaCompleta(
        Request $request,
        GetAulaCompletaAction $action
    ): JsonResponse {
        $request->validate([
            'aula_id' => 'required|integer|exists:aulas,id',
        ]);

        $resultado = $action->execute((int) $request->aula_id);

        if (!$resultado['success']) {
            return response()->json(['error' => $resultado['error']], 404);
        }

        return response()->json([
            'success' => true,
            'aula' => $resultado['aula'],
        ]);
    }
}
```

---

## 3. Coding Standards & PHP Guidelines

- **Strict Types**: Use `declare(strict_types=1);` at the top of new PHP files to prevent type coercion.
- **Compatibility**: Ensure compatibility with PHP 7.1+. Avoid PHP 8+ features like constructor property promotion, union types (`string|int`), readonly properties, or match expressions in files that must support PHP 7.1.
- **Naming Conventions**:
  - Class Names: `PascalCase` (e.g. `CreateFusionAulaFromReferenceAction`).
  - Methods & Variables: `camelCase` (e.g. `obtenerAulaCompleta()`, `$aulaId`).
  - Tables & Columns: Legacy Spanish in snake_case (e.g. `codigo_aula`, `items_encuesta`, `link_drive`, `frecuencia_asistencias`).
  - Code Symbol Names: English for standard variables/methods/comments, Spanish strictly for domain-specific database columns and client-facing text.

---

## 4. Database & Eloquent ORM

- **Legacy Database**: The schema utilizes standard Spanish naming conventions for tables and columns.
- **Relationships**: Define Eloquent relationships in models using standard relationships (`belongsTo`, `hasMany`, `belongsToMany`).
- **No Direct DB Queries in Views**: Data fetching must occur in the Action class, passed through the Controller, and reference clean model instances or arrays in the view layer.
