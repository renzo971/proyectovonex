<!--
SYNC IMPACT REPORT:
- Version change: 1.1.0 -> 2.5.0
- List of modified principles:
  * Art. 2 · Preservación de Patrones y Compatibilidad Heredada: Removida regla de Swal.fire.
  * Art. 3 · Estándares de Calidad: Modificada precisión del cruce incluyendo coincidencia difusa para cabos sueltos.
  * Art. 7 · Límites (Las Tres Listas): Agregada regla de ignorar fechas duplicadas en ALWAYS DO y regla de procesar cabos sueltos guiados en NEVER DO. Removida la de Swal.fire.
- Added sections:
  * Flujo del Proceso de Cruce
- Removed sections: None
- Templates requiring updates:
  * ✅ .specify/templates/plan-template.md (already aligned)
  * ✅ .specify/templates/spec-template.md (already aligned)
  * ✅ .specify/templates/tasks-template.md (already aligned)
- Follow-up TODOs: None
-->
# Project Constitution: Motor de Cruce de Ingresantes UNMSM (Vonex)

**Version:** 2.5.0
**Established:** 2026-06-16
**Last Amended:** 2026-07-03

## Article I: Project Identity

### 1.1 Purpose
El motor de cruce automatiza la validación de identidades de los ingresantes de la UNMSM contra la base de datos de la academia Vonex, filtrando ingresantes con vacante y facilitando el emparejamiento analítico exacto y difuso.

### 1.2 Users
- **Equipo de Admisiones / Administradores:** Interactúan con la interfaz para subir CSV, validar cabos sueltos y descargar reportes.
- **Sistema Interno:** Entorno 100% Intranet (local).

### 1.3 Success Metrics
- Cero falsos positivos en el match automático inicial.
- Reducción del tiempo de procesamiento (Carga asíncrona de CSV en ≤ 50 segundos).
- Carga de interfaz de validación manual en ≤ 5 minutos para lotes históricos grandes.

## Article II: Technology Stack

### 2.1 Runtime & Platform
- **Production Environment:** On-prem / Intranet Local.
- **Container Platform:** Nginx Local (Proxy Inverso con cabeceras HTTP básicas). Sin jaulas Chroot/AppArmor por ser entorno de confianza.
- **CI/CD:** Pipeline estándar de revisión de código (GitHub).

### 2.2 Backend
- **Language:** PHP 8.4+ (con ext-pgsql, ext-redis, ext-opcache, ext-pcre).
- **Framework:** Laravel 13, Octane + FrankenPHP.
- **Database:** PostgreSQL 14+ (con pg_trgm, unaccent). PgBouncer 1.21+ (modo transaction).
- **Caching & Session:** Redis 7+ (driver único `redis`).
- **Messaging:** Laravel Horizon (min. 4 workers en cola cruce).

### 2.3 Frontend
- **Framework:** React SPA (Vite 8).
- **State Management:** Zustand, TanStack Query v5 (cursor-based pagination).
- **Styling:** CSS base, react-window (`VariableSizeList`) para listas virtuales infinitas.

### 2.4 Testing
- **Unit/Integration Testing:** Pest / PHPUnit (`php artisan test`).

## Article III: Quality Standards

### 3.1 Code Quality
- **Type Safety:** Tipado estricto en PHP (`declare(strict_types=1);`).
- **Formatting:** Cumplimiento estricto del formateador de código del proyecto sin excepciones.
- **Documentation:** Símbolos técnicos, clases, variables y commits en **inglés**. Conceptos de negocio de BD y UI en **español**.

### 3.2 Test Coverage
- **Critical Paths:** 100% de cobertura de pruebas unitarias e integradas para la lógica de cruce, normalización y endpoints. Pruebas manuales con curl/MCP no reemplazan las automatizadas.

### 3.3 Performance
- **API Response Time:** ≤ 300 ms (p95) para match difuso individual.
- **Page Load Time:** ≤ 5 minutos para renderizar tabla React con 27,000 registros pendientes (`pg_trgm` + cache + chunking).
- **Database Query Time:** Acelerado mediante índices GIN en PostgreSQL.
- **Job Processing Time:** ≤ 50 segundos para pipeline CSV (`Bus::batch()`, OPcache+JIT).

### 3.4 Security
- **Authentication:** Autenticación local.
- **Authorization:** Mínimo Privilegio en BD (Usuario `academia` restringido a SELECT; INSERT/UPDATE solo en lotes temporales).
- **Data Protection:** Sanitización estricta (CSV Formula Injection neutralizando `=`, `+`, `-`, `@`). Validación estricta de Magic Bytes/MIME. 
- **Compliance:** Arquitectura de seguridad de aplicación; WAF/CrowdSec descartados por diseño para intranet.

### 3.5 Accessibility
- **Standard:** Contraste visual intuitivo para rangos de similitud en React (Verde Intenso, Verde Claro, Amarillo).

## Article IV: Architecture Principles

### 4.1 Design Principles
- **Pipeline sin intervención manual:** Eliminar filtrado manual previo; el motor procesa el CSV puro asíncronamente en Redis.
- **Precisión Analítica:** Regla inicial estricta (2 apellidos + 1 nombre). Para cabos sueltos, umbral de cálculo interno 30%, umbral visual en interfaz 70%.
- **Normalización Estricta:** Todo texto procesado debe convertirse a MAYÚSCULAS, sin tildes, con reemplazo de "Ñ" por "N".
- **Jerarquía Inmutable de Estados:** 1. MATRICULADO, 2. PAGADO, 3. FINALIZADO, 4. SUSPENDIDO, 5. RETIRADO, 6. TRASLADADO, 7. STAND BY, 8. ANULADO.

### 4.2 Code Organization
- **Backend:** Patrón de clases de Acción (`app/Actions/Cruce`) con un único método `execute()` que retorna un array (`success`, `data`, `error`).
- **Controladores:** Delgados; relegan toda lógica de negocio a las Acciones.
- **Frontend:** Componentes funcionales y Hooks reactivos.

### 4.3 Dependency Management
- Modificar dependencias de Composer o npm requiere autorización (ver 6.2).
- Usar PhpSpreadsheet en modo streaming para evitar desborde de memoria.

### 4.4 API Design
- Endpoints RESTful respondiendo en JSON.
- `php artisan wayfinder:generate` para documentar/compilar rutas backend.

### 4.5 Error Handling
- **Gestión Silenciosa:** Si falla la conexión, el sistema pausa el lote en lugar de perder datos. Los fallos masivos caen a la cola `failed_jobs`.

### 4.6 Logging & Observability
- Trazabilidad y Auditoría: Se guardan los totales (match, no_ingresado, pendiente) en `lotes_cruce` por cada fecha de examen importada.

**Versión**: 2.5.0 | **Ratificado**: 2026-06-16 | **Última Enmienda**: 2026-07-03

## Article V: Development Workflow

### 5.1 Git Workflow
- **Branch Strategy:** `main` (producción estable), `develop` (desarrollo), `feature/` (ramas de características).
- **Commit Messages:** En inglés, usando convenciones de Conventional Commits.
- **PR Requirements:** Aprobación de QA antes de fusionar.

### 5.2 Review Process
- **Roles:** Samuel Cisneros (PO), Renzo Fabián (Tech Lead), Diego Fernando / Yerson Vargas (QA).
- **Review Criteria:** Adherencia total a esta Constitución.

### 5.3 Definition of Done
- Tareas completadas en *baby steps* (pasos pequeños).
- Pruebas automatizadas en verde.
- Pruebas manuales de endpoint (con curl/MCP) validadas.
- Artefactos `ai-specs` (symlinks) actualizados.

## Article VI: Boundaries

### 6.1 Always Do
- Trabajar en pasos de bebé (baby steps) y verificar siempre un paso antes del siguiente.
- Etiquetar registro con "Fecha de Examen" extraída automáticamente.
- Validar conexión a BD `academia` antes de procesar lote.
- Ignorar silenciosamente las fechas de CSV ya cargadas previamente.
- Aplicar sistema de colores inmutable (95-100% verde intenso #16a34a, 85-94% verde claro #4ade80, 70-84% amarillo #eab308).
- Filtrar Excel final para excluir pendientes/no_ingresados (solo match confirmado).

### 6.2 Ask First
- Alterar la jerarquía inmutable de 8 estados (Art 4.1).
- Modificar estructura de columnas del CSV original.
- Agregar dependencias a Composer/npm.
- Modificar esquemas de bases de datos de producción.

### 6.3 Never Do
- Volver a manipulación manual de datos pre-cruce.
- Sobrescribir fechas de examen anteriores.
- Guardar matches difusos sin revisión interactiva.
- Escribir SQL en vistas Blade o lógica de negocio en Controladores.
- Exponer candidatos con similitud < 70% en React.
- Incluir registros `pendiente` o `no_ingresado` en el archivo Excel final.
- Modificar colores hex de similitud sin enmienda formal.
- Confiar ciegamente en extensión `.csv` (validar MIME real).
- Ejecutar PHP-FPM / workers como `root`.
- Exponer la aplicación HTTP sin Rate Limiting y X-Frame-Options/X-Content-Type-Options.

## Article VII: Amendments

### 7.1 Amendment Process
Esta constitución puede enmendarse mediante:
1. Proposición del cambio.
2. Ratificación por el Tech Lead y Product Owner.
3. Actualización de versión y registro en el Amendment Log.

### 7.2 Amendment Log

| Date | Article | Change | Rationale |
|------|---------|--------|-----------|
| 2026-06-16 | All | Versión base ratificada (2.2.0) | Kickoff del cruce automatizado |
| 2026-06-24 | All | Transición a Enterprise SDD (2.4.0) | Inclusión del stack de rendimiento inmutable y fases de cruce |
| 2026-07-03 | II, III | Controles de Seguridad Intranet (2.5.0) | Adaptación a entorno local (sanitización CSV, MIME, mínimo privilegio DB); descarta explícitamente WAF/Chroot/AppArmor. |
