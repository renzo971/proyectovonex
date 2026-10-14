# Motor de Cruce Automático de Ingresantes UNMSM (Vonex Crossing Engine)

[![Laravel](https://img.shields.io/badge/Laravel-11.x-FF2D20?style=flat&logo=laravel)](https://laravel.com)
[![React](https://img.shields.io/badge/React-18.x-61DAFB?style=flat&logo=react)](https://react.dev)
[![Vite](https://img.shields.io/badge/Vite-6.x-646CFF?style=flat&logo=vite)](https://vitejs.dev)
[![PHP](https://img.shields.io/badge/PHP-8.2+-777BB4?style=flat&logo=php)](https://php.net)

An enterprise data consolidation engine built for **Academia Vonex** to cross-reference and validate official UNMSM (*Universidad Nacional Mayor de San Marcos*) admission exam results (~27,000 records × 12 columns) against the academy's student enrollment database.

---

## 1. Architectural Overview

The system follows the **Service Actions pattern** in Laravel, combined with an asynchronous background pipeline driven by queues and an interactive React SPA for unresolved cases (*cabos sueltos*).

```mermaid
graph TB
    subgraph Client Layer (React SPA)
        UI[App.jsx]
        Upload[CSV File Upload]
        Unmatched[Pending Resolution Panel]
    end

    subgraph API & Controllers
        CTRL[CruceIngresantesController]
    end

    subgraph Queue & Asynchronous Processing
        Q[Queue: cruce]
        Job[ProcessCsvBatchJob]
    end

    subgraph Application Service Actions
        ACT_NORM[NormalizarTextoAction]
        ACT_CSV[ProcesarCargaCsvAction]
        ACT_EXACT[RealizarCruceExactoAction]
        ACT_FUZZY[CalcularSimilitudesCabosAction]
        ACT_CONFIRM[GuardarCruceConfirmadoAction]
        ACT_EXCEL[ExportarExcelCruceAction]
    end

    subgraph Dual Database Layer
        DB_VONEX[(Vonex Analytics DB)]
        DB_ACADEMIA[(Academia DB - Read-Only)]
    end

    UI --> CTRL
    CTRL --> Q
    Q --> Job

    Job --> ACT_CSV
    Job --> ACT_NORM
    Job --> ACT_EXACT
    Job --> ACT_FUZZY

    CTRL --> ACT_CONFIRM
    CTRL --> ACT_EXCEL

    ACT_EXACT --> DB_ACADEMIA
    ACT_FUZZY --> DB_ACADEMIA

    Job --> DB_VONEX
    ACT_CONFIRM --> DB_VONEX
    ACT_EXCEL --> DB_VONEX
```

### Core Architecture Highlights

- **Dual-Table Analytics Schema:**
  - `ingresantes`: Persists records who attained a vacancy (*alcanzó vacante*), tracking match statuses (`exacto`, `confirmado_manual`, `no_ingresado`, `pendiente`).
  - `no_ingresantes`: Audit table persisting all applicants who did not achieve a vacancy, ensuring 100% traceability without bloating the match queries.
- **Two-Phase Matching Engine:**
  1. **Strict Exact Match:** Compares normalized full names and DNI against active academy student enrollments.
  2. **Eager Fuzzy Match (Levenshtein):** Identifies ambiguous matches (*cabos sueltos* with similarity $\ge 70\%$) inside the background batch job and persists top 5 candidates in `ingresante_candidatos`.
- **Zero HTTP Timeouts:** CSV ingestion and heavy computations are offloaded to asynchronous background jobs via Laravel Queues.

---

## 2. Prerequisites & Requirements

- **PHP:** `^8.2` with extensions `pdo`, `mbstring`, `openssl`, `curl`
- **Composer:** `^2.x`
- **Node.js:** `^18.x` or `^20.x` & **npm**
- **Database:** PostgreSQL or MySQL (plus read-only connection to Academia DB)
- **Queue Backend:** Redis (recommended for production) or Database queue driver

---

## 3. Environment Setup & Configuration

Copy the example environment file and set the required variables:

```bash
cp .env.example .env
php artisan key:generate
```

### Key Environment Variables (`.env`)

```ini
# Primary Application Database (Vonex Analytics)
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=proyectovonex
DB_USERNAME=postgres
DB_PASSWORD=secret

# Academia Database (Read-Only Replica for Student Verification)
DB_ACADEMIA_HOST=127.0.0.1
DB_ACADEMIA_PORT=5432
DB_ACADEMIA_DATABASE=academia
DB_ACADEMIA_USERNAME=postgres
DB_ACADEMIA_PASSWORD=secret

# Queue Configuration
QUEUE_CONNECTION=database # or redis for high throughput
```

Run database migrations:

```bash
php artisan migrate
```

---

## 4. Execution Commands

To run the application locally, start the following three services:

### 1. Web Application Server
Using Laravel built-in server or Laravel Herd / Valet:
```bash
php artisan serve
```

### 2. Frontend Build & Asset Watcher (Vite)
Compiles React JSX components:
```bash
npm run dev
```

### 3. Queue Worker (CRITICAL)
Processes the CSV batches and fuzzy match calculations dispatched to the `cruce` queue:
```bash
php artisan queue:work --queue=cruce
```

> [!IMPORTANT]
> The background worker must be running with `--queue=cruce`. Uploaded files are enqueued via `ProcessCsvBatchJob` and will remain in pending state if this worker is not active.

---

## 5. API Reference (`/api/cruce/*`)

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/cruce/upload` | Upload official CSV file (max 20 MB) and dispatch batch job |
| `GET` | `/api/cruce/lotes` | List all processed admission exam batches |
| `GET` | `/api/cruce/lotes/{lote_id}/status` | Check the real-time processing status of a batch |
| `GET` | `/api/cruce/lotes/{lote_id}/pendientes` | Paginated list of unresolved records (*cabos sueltos*) |
| `GET` | `/api/cruce/ingresantes/{id}/candidatos` | Pre-calculated fuzzy match candidates for a pending record |
| `POST` | `/api/cruce/ingresantes/{id}/confirmar` | Confirm candidate match (`alumno_id`) or mark as not admitted (`marcar_no_ingresado: true`) |
| `GET` | `/api/cruce/lotes/{lote_id}/exportar` | Export final consolidated report in Excel / CSV format |
| `GET` | `/api/cruce/health` | Diagnostic check of database connectivity and queues |
| `GET` | `/api/cruce/academia/alumnos` | Diagnostic fetch of active academy student roster |
| `POST` | `/api/cruce/lotes/{lote_id}/reprocesar` | Reprocess an existing batch from scratch |
| `DELETE`| `/api/cruce/limpiar` | Purge lotes and associated records (administrative action) |

---

## 6. Testing & Quality Assurance

Unit and feature test suites are written using **Pest / PHPUnit**:

```bash
# Run all tests
php artisan test

# Run feature tests for the cruce module
php artisan test --filter=CruceIngresantesPendientesTest
php artisan test --filter=CruceIngresantesExportarTest

# Run authentication and authorization suite
php artisan test --filter=CruceAuthTest
```

---

## 7. SDD Enterprise Specifications

Detailed design, data contracts, and quality checklists can be found in the SDD artifacts:
- Solution Architecture & Decisions: [.specify/specs/001-motor-cruce-ingresantes/plan.md](file:///.specify/specs/001-motor-cruce-ingresantes/plan.md)
- Data Model & Schema: [.specify/specs/001-motor-cruce-ingresantes/data-model.md](file:///.specify/specs/001-motor-cruce-ingresantes/data-model.md)
- Acceptance Criteria & Specs: [.specify/specs/001-motor-cruce-ingresantes/spec.md](file:///.specify/specs/001-motor-cruce-ingresantes/spec.md)
- Task Breakdown: [.specify/specs/001-motor-cruce-ingresantes/tasks.md](file:///.specify/specs/001-motor-cruce-ingresantes/tasks.md)
