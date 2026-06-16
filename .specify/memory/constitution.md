# Proyecto Vonex Constitution

## Core Principles

### Art. 1 · Small tasks, one at a time (tareas pequeñas, una a la vez)
- **Rules**: Always work in baby steps, one at a time. Never move forward more than one step. Ensure each step is fully verified before proceeding.
- **Rationale**: Keeps changes manageable, reduces debugging complexity, and ensures correctness.

### Art. 2 · Pattern Preservation & Legacy Compatibility (preservación de patrones y compatibilidad)
- **Rules**:
  - **Backend**: Follow the Action class pattern (`app/Actions/`) with standard single-method `execute()` returning structured success/data/error arrays. Thin controllers, clean Eloquent relationships, and strict types (`declare(strict_types=1);`). PHP 7.1+ compatibility.
  - **Frontend**: Use Vue.js 2.x Options API within Blade views, Bootstrap 4 grid layout, custom utility CSS, and SweetAlert2 (`Swal.fire`) for user notifications. No native alerts/confirms.
- **Rationale**: Maintains readability, architectural alignment, consistency with legacy framework code, and avoids introducing unapproved dependencies or patterns.

### Art. 3 · Quality Standards (estándares de calidad)
- **Rules**:
  - **TDD & Unit Testing**: Update/write backend tests using Pest/PHPUnit. Validate database integrity before and after test execution.
  - **Coding Standards**: English for technical symbols (class/variable/function names, comments), Spanish strictly for domain database schema column names and UI elements visible to the user.
  - **Linting & Formatter**: Strict coding syntax must be adhered to without exceptions.
- **Rationale**: High code quality, clear separation of concerns, and localization consistency.

### Art. 4 · Architecture Principles (principios de arquitectura)
- **Rules**:
  - **Hierarchical separation**: Controller (HTTP validation, response formatting) -> Action (single business logic unit, DB interaction) -> Eloquent Models (data mappings, relationships).
  - No direct DB queries in views. Thin controllers. No business logic in controllers.
  - **Symlink integrity**: Reusable artifacts in `ai-specs` must be mapped via symlinks for other agents (`.claude`, `.cursor`).
- **Rationale**: Clear separation of concerns, DRY code, and cross-agent portability.

### Art. 5 · Language Standards (estándares de lenguaje)
- **Rules**: All technical code elements (variables, classes, internal comments, logs, and commit messages) must be written in English. UI elements and domain-specific terms (database tables/columns, business rules) must be in Spanish.
- **Rationale**: Keeps the codebase professional, aligns with legacy design, and provides a clear user experience.

### Art. 6 · Portabilidad Multi-Agente (Multi-Agent Portability)
- **Rules**: Keep reusable artifacts in `ai-specs` as the canonical source. Agent-specific paths (like `.claude` and `.cursor`) should reference them through symlinks. Update links when files are renamed or moved.
- **Rationale**: Ensures any agent (Claude, Cursor, Gemini, etc.) can operate on the codebase seamlessly.

### Art. 7 · Boundaries (límites - las tres listas)
- **ALWAYS DO**:
  - Use baby steps and perform incremental checkins.
  - Use `declare(strict_types=1);` in PHP.
  - Return JSON from controllers for API endpoints.
  - Use `Swal.fire` for alerts and confirmations.
  - Perform manual endpoint testing using curl/MCP browser.
  - Keep documentation updated.
- **ASK FIRST**:
  - Adding new dependencies (npm/composer).
  - Changing database schema (migrations).
  - Changing core routing or directory structures.
  - Demoting or promoting constitution rules.
- **NEVER DO**:
  - Write direct DB queries in Blade Views.
  - Write business logic directly in controllers.
  - Use native `alert()` or `confirm()`.
  - Use PHP 8+ features in legacy PHP 7.1+ compatible files.
  - Skip manual testing or database verification.
- **Rationale**: Strict safeguards to prevent codebase degradation and security risks.

## Git Workflow & Team Collaboration
- **Rama `main` / `master`**: Producción estable. Solo se sube código verificado mediante pull requests.
- **Rama `develop`**: Entorno de desarrollo e integración.
- **Ramas de Características (`feature/`)**: Cada nueva funcionalidad o API se desarrolla en una rama dedicada (ej. `feature/alumno-matricula-api`).
- **Validaciones**: Antes de fusionar con `develop`, todo código debe pasar por revisiones de QA.
- **Integrantes y Funciones**:
  - **Samuel Cisneros**: Analista (Product Owner / Product Manager)
  - **Renzo Fabián**: Fullstack (Tech Lead / Lead Developer)
  - **Diego Fernando**: Soporte (Quality Assurance - QA)
  - **Yerson Vargas**: Soporte (QA / Apoyo Técnico)

## Setup & Testing Execution
- **Configuración del Entorno**:
  - Backend: PHP (>= 8.x para desarrollo local, compatibilidad PHP 7.1+ en producción), Composer, PostgreSQL (DB: `intranet_local`), Laravel Server.
  - Wayfinder: `php artisan wayfinder:generate` must be run whenever a backend route changes.
- **Ejecución de Pruebas**:
  - Backend: `php artisan test` (Pest/PHPUnit).

## Governance
- **Ratification**: This constitution is ratified by the core development team (Samuel Cisneros, Renzo Fabián, Diego Fernando, Yerson Vargas) and is binding for all developers and AI agents.
- **Amendments**: Modifying this constitution requires team agreement, documentation of the change, a bump of the version, and propagation across templates.
- **Compliance Review**: All Pull Requests and commits must be reviewed for adherence to this constitution.

**Version**: 1.0.0 | **Ratified**: 2026-06-16 | **Last Amended**: 2026-06-16
