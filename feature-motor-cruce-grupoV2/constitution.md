<!--
SYNC IMPACT REPORT:
- Version change: 1.1.0 -> 2.4.0
- List of modified principles:
  * Art. 2 – Preservación de Patrones y Compatibilidad Heredada: Removida regla de Swal.fire.
  * Art. 3 – Estándares de Calidad: Modificada precisión del cruce incluyendo coincidencia difusa para cabos sueltos.
  * Art. 7 – Límites (Las Tres Listas): Agregada regla de ignorar fechas duplicadas en ALWAYS DO y regla de procesar cabos sueltos guiados en NEVER DO. Removida la de Swal.fire.
- Added sections:
  * Flujo del Proceso de Cruce
- Removed sections: None
- Templates requiring updates:
  * ? .specify/templates/plan-template.md (already aligned)
  * ? .specify/templates/spec-template.md (already aligned)
  * ? .specify/templates/tasks-template.md (already aligned)
- Follow-up TODOs: None
-->

# Constitución del Proyecto Vonex

## Principios Fundamentales

### Art. 1 – Tareas pequeñas, una a la vez

- **Reglas**: Trabajar siempre en pasos de bebé (baby steps), uno a la vez. Nunca avanzar más de un paso a la vez. Asegurar que cada paso esté completamente verificado antes de continuar.
- **Justificación**: Mantiene los cambios manejables, reduce la complejidad de depuración y asegura la corrección del código.

### Art. 2 – Preservación de Patrones y Compatibilidad
- **Reglas**:
  - **Backend**: Seguir el patrón de clases de Acción (`app/Actions/`) con un único método público `execute()` que retorne un arreglo estructurado con `success` (booleano), `data` (modelo o colección) y `error` (mensaje/arreglo de error). Mantener controladores delgados, relaciones de Eloquent limpias y tipado estricto (`declare(strict_types=1);`). Compatibilidad estricta con PHP 8.4+.
  - **Frontend**: React (Vite) en arquitectura SPA con componentes funcionales y Hooks reactivos, consumiendo la API REST de Laravel.
- **Justificación**: Garantiza la legibilidad, mantenibilidad y alineación arquitectónica con el stack moderno del proyecto.

### Art. 3 – Estándares de Calidad

- **Reglas**:
  - **Integridad de Normalización**: Todo texto procesado desde el CSV crudo debe convertirse obligatoriamente a MAYÚSCULAS, sin tildes y con reemplazo estricto de la "Ñ" por "N". No se aceptan excepciones.
  - **Precisión del Cruce (Match Exacto e Integración Difusa)**:
    - En el primer paso, la regla de validación de identidad inicial para el cruce automático es estricta: `2 apellidos exactos + 1 nombre exacto` (Cero Falsos Positivos).
    - Los registros que no coincidan de forma exacta (cabos sueltos) deben evaluarse buscando coincidencias o concurrencias similares (match difuso/fuzzy matching) para que el usuario pueda validarlos interactivamente antes de ser guardados.
    - **Umbral dual de similitud (inmutable):** El motor calcula candidatos con similitud = 30% (umbral de cálculo interno). La interfaz de validación React **solo muestra** candidatos con similitud = 70% (umbral de visualización). Estos dos valores son independientes y cualquier modificación requiere enmienda constitucional documentada.
    - **Sistema de colores por rango de similitil (inmutable):** Los badges de similitud en la interfaz React deben seguir estrictamente esta escala: **95-100%   verde intenso** (#16a34a); **85-94%   verde claro** (#4ade80); **70-84%   amarillo/ámbar** (#eab308). Ningún candidato por debajo del 70% debe exponerse al administrador.
    - **Alcance del Excel final:** El reporte Excel de exportación contiene únicamente registros con `estado_match IN ('confirmado_automatico', 'confirmado_manual')`. Los registros `pendiente` y `no_ingresado` **no aparecen en el Excel** pero se preservan en la BD para auditoría (NFR-005). El Excel no replica el sistema de colores de similitud de la interfaz React.
  - **Prioridad Histórica Inmutable**: La resolución de estados duplicados debe regirse exclusivamente por la jerarquía definida: 1. MATRICULADO, 2. PAGADO, 3. FINALIZADO, 4. SUSPENDIDO, 5. RETIRADO, 6. TRASLADADO, 7. STAND BY, 8. ANULADO.
  - **Estándares de Codificación**: Los símbolos técnicos (clases, variables, métodos, comentarios de código) deben escribirse en inglés. Los términos de dominio (tablas, columnas de BD, reglas de negocio) e interfaz de usuario visibles deben estar en español.
  - **Reglas de Linting y Formateador**: Cumplimiento estricto del formateador de código del proyecto sin excepciones.
  - **Data Protection**:
    - **Sanitización de Exportaciones:** Todo dato proveniente de fuentes externas (CSV) debe ser sanitizado antes de su persistencia y exportación a Excel para prevenir ataques de inyección de fórmulas (CSV/Formula Injection). Ningún campo puede comenzar con los caracteres `=`, `+`, `-`, `@` sin ser neutralizado.
    - **Mínimo Privilegio en Base de Datos:** El usuario de PostgreSQL utilizado por el backend para conectarse a `academia` debe tener permisos estrictos de `SELECT` sobre la tabla de alumnos, y `INSERT`/`UPDATE` únicamente sobre `lotes_cruce` e `ingresantes_cruce`.
    - **Validación Estricta de Tipos MIME:** La carga de archivos debe validar el contenido binario (Magic Bytes) del archivo, no solo la extensión `.csv`.
    - **Aislamiento de Carga de Trabajo:** El procesamiento masivo de datos (cálculo de similitudes) debe ejecutarse de forma asíncrona mediante colas de trabajo en segundo plano (Laravel Queues) para evitar bloqueos del proceso principal y saturación de memoria.
- **Justificación**: Garantiza precisión analítica absoluta en reportes sin perder la capacidad de capturar coincidencias por ligeras diferencias mediante validación asistida por el usuario.

### Art. 4 – Principios de Arquitectura

- **Reglas**:
  - **Pipeline sin intervención manual**: La orquestación del flujo de trabajo (lectura del CSV, separación por lotes y consultas a la base de datos de la academia) se gestionará mediante un script en PHP, eliminando manipulación manual o filtrado previo en hojas de cálculo.
  - **Centralización Analítica**: Los datos resultantes del cruce y enriquecimiento se descargarán en un archivo Excel final para su distribución; el pipeline interno no debe depender de hojas de cálculo manuales ni de archivos intermedios estáticos.
  - **Gestión de Errores Silenciosos**: Si se produce un timeout o error de conexión, el sistema debe pausar el lote y alertar. Los datos parcialmente procesados deben marcarse para revisión.
  - **Auditoría y trazabilidad**: Registrar cada lote, cada `Fecha de Examen`, el resultado del cruce y cualquier fallo para poder reconstruir el origen de las decisiones analíticas tomadas.
  - **Seguridad de credenciales**: Claves o secretos no se almacenan en el repositorio. Usar variables de entorno (`.env`).
  - **Pruebas automatizadas**: Cobertura de pruebas unitarias e integradas para la lógica de cruce y los endpoints. Las pruebas manuales con `curl` o el navegador MCP complementan, pero no reemplazan la validación.
  - **Integridad de Symlinks**: Los artefactos reutilizables en `ai-specs` deben estar referenciados mediante symlinks para que otros agentes (como `.claude` o `.cursor`) accedan consistentemente.
  - **SLA de rendimiento de validación manual:** El tiempo de carga de la vista de validación React (ingresantes `pendiente` con candidatos coloreados) debe ser = 5 minutos para lotes de hasta ~27,000 registros. El tiempo base de producción de ~15 minutos es inaceptable. La optimización se logra mediante `pg_trgm` en PostgreSQL, Redis cache del pool de alumnos (TTL 1 h) y chunking de 500 registros por batch.
  - **Stack de rendimiento inmutable** - Los siguientes componentes son parte de la arquitectura de producción y no pueden ser reemplazados sin enmienda constitucional:
    - **`pg_trgm` + índice GIN:** Toda similitud difusa se calcula en el motor PostgreSQL. Prohibido implementar Levenshtein PHP en bucle contra toda la tabla de alumnos.
    - **Redis como driver único** de colas (`QUEUE_CONNECTION=redis`), caché (`CACHE_STORE=redis`) y sesión (`SESSION_DRIVER=redis`). Prohibido usar `database` como driver de colas o caché en producción.
    - **Laravel Horizon** para gestión de colas con mínimo 4 workers paralelos en producción (`supervisor-cruce`).
    - **Laravel Octane + FrankenPHP** como servidor HTTP de producción (workers PHP persistentes).
    - **PgBouncer** (modo `transaction`, pool 20 conexiones) entre Laravel y la BD `academia` para evitar saturar `max_connections` de PostgreSQL.
    - **PHP OPcache + JIT** habilitados en producción (`opcache.jit=tracing`, buffer 128 MB).
    - **`Bus::batch()`** con chunks de 500 registros para el procesamiento paralelo del CSV.
    - **`react-window` (`VariableSizeList`)** para renderizar la tabla de validación sin importar el número de filas pendientes.
    - **TanStack Query v5** con cursor-based pagination (`cursorPaginate(100)`) para todas las llamadas API de la vista de validación.
    - **PhpSpreadsheet en modo streaming** para la generación del Excel final sin desbordar la memoria PHP.
- **Justificación**: Claridad en la separación de responsabilidades, seguridad, robustez ante fallos de infraestructura y portabilidad del motor analítico. El stack de rendimiento garantiza los SLAs de NFR-001, NFR-002 y NFR-007 con margen operativo.

### Art. 5 – Estándares de Lenguaje

- **Reglas**: Toda codificación técnica (variables, clases, funciones y commits) se escribe en inglés. Todo elemento visible al usuario y conceptos de negocio de base de datos se escribe en español.
- **Justificación**: Mantiene la profesionalidad del código y garantiza un sistema entendible para usuarios y administradores.

### Art. 6 – Portabilidad Multi-Agente

- **Reglas**: Mantener los archivos de especificaciones e instrucciones de los agentes en `ai-specs` como la fuente de verdad. Actualizar symlinks en los directorios de agentes específicos cuando cambien las rutas de archivos.
- **Justificación**: Asegura que cualquier asistente de IA trabaje con el mismo contexto unificado.

### Art. 7 – Límites (Las Tres Listas)

- **SIEMPRE HACER (ALWAYS DO)**:
  - Etiquetar cada registro entrante con su respectiva "Fecha de Examen" extraída automáticamente antes de insertarlo en la base de datos analítica.
  - Validar la conexión y autenticación con la base de datos de la academia antes de iniciar el procesamiento de cualquier lote.
  - Ignorar las fechas y registros ya cargados al procesar un nuevo archivo CSV para evitar duplicidades.
  - Realizar desarrollos en pasos cortos con entregas incrementales y frecuentes.
  - Retornar respuestas JSON desde controladores de API.
  - Probar manualmente endpoints mediante `curl` o navegador MCP antes de finalizar una iteración.
  - Mantener la documentación técnica actualizada.
  - Aplicar el sistema de colores por rango de similitud (Art. 3) en la interfaz React de validación: verde intenso =95%, verde claro 85-94%, amarillo 70-84%.
  - Filtrar el Excel final para incluir exclusivamente registros `confirmado_automatico` o `confirmado_manual`.
- **PREGUNTAR PRIMERO (ASK FIRST)**:
  - Antes de alterar o expandir la lista de los 8 estados permitidos para el cruce.
  - Si la estructura de columnas del CSV de origen sufre alguna modificación.
  - Agregar nuevas dependencias a Composer o npm.
  - Modificar esquemas de bases de datos.
- **NUNCA HACER (NEVER DO)**:
  - Volver a la manipulación manual de datos o delegar el filtrado de fechas a la intervención humana.
  - Sobrescribir datos de días de examen anteriores al procesar un nuevo lote.
  - Guardar directamente coincidencias no exactas sin permitir al usuario revisarlas mediante la funcionalidad de validación de registros similares.
  - Escribir consultas SQL directas en vistas Blade.
  - Escribir lógica de negocio directamente en controladores.
  - Mostrar en la interfaz React candidatos con similitud < 70%, independientemente del resultado del motor difuso.
  - Incluir registros `pendiente` o `no_ingresado` en el archivo Excel de exportación final.
  - Modificar los códigos hexadecimales de color del sistema de rangos de similitud sin enmienda constitucional.
  - Nunca confiar ciegamente en la extensión del archivo (.csv); siempre validar los Magic Bytes y el tipo MIME real en el controlador.
  - Nunca exponer endpoints de procesamiento masivo sin Rate Limiting estricto.
  - Nunca ejecutar el proceso de PHP-FPM o los workers de colas con privilegios de administrador (root).
  - Nunca exponer la API sin cabeceras de seguridad básicas (X-Content-Type-Options, X-Frame-Options).
- **Justificación**: Reglas de control estrictas para salvaguardar la calidad del código, evitar reprocesamientos y prevenir riesgos de seguridad.

## Flujo del Proceso de Cruce

1. **Conexión y Extracción**: El sistema se conecta a la base de datos `academia` para extraer los datos de los alumnos matriculados vigentes.
2. **Carga de Archivo**: El usuario sube el archivo CSV de ingresantes a San Marcos.
3. **Cruce Inicial (Coincidencia Exacta)**: Se realiza el cruce utilizando coincidencia de `2 apellidos exactos + 1 nombre exacto`. Los registros válidos se guardan automáticamente en la DB con estado `confirmado_automatico`.
4. **Tratamiento de Cabos Sueltos (Match Difuso)**: Para los alumnos que no tuvieron match exacto, el motor calcula similitud difusa (umbral interno = 30%). La interfaz React expone al administrador únicamente los candidatos que superen el **70% de similitud**, coloreados por rango (verde intenso =95% / verde claro 85-94% / amarillo 70-84%). El administrador selecciona el match correcto (estado `confirmado_manual`) o lo descarta (estado `no_ingresado`).
5. **Control de Cargas Futuras**: Al procesar una nueva carga, el sistema ignora las fechas de examen que ya fueron cargadas y procesadas previamente.
6. **Exportación del Reporte**: El archivo Excel final incluye exclusivamente los registros `confirmado_automatico` y `confirmado_manual`, sin exponer metadatos del proceso difuso.

## Flujo de Trabajo Git y Colaboración

- **Rama `main` / `master`**: Producción estable. Solo se sube código verificado mediante pull requests.
- **Rama `develop`**: Entorno de desarrollo e integración.
- **Ramas de Características (`feature/`)**: Cada nueva funcionalidad o API se desarrolla en una rama dedicada (ej. `feature/alumno-matricula-api`).
- **Validaciones**: Antes de fusionar con `develop`, todo código debe pasar por revisiones de QA.
- **Integrantes y Funciones**:
  - **Samuel Cisneros**: Product Owner (PO) / Product Manager
  - **Renzo Fabián**: Tech Lead / Lead Developer
  - **Diego Fernando**: QA Tester / Co-Lead de Constitución
  - **Yerson Vargas**: QA / Apoyo Técnico

## Configuración y Ejecución de Pruebas

- **Stack de Infraestructura requerido en producción**:
  - **PHP 8.4+** con extensiones: `ext-pgsql`, `ext-redis` (phpredis), `ext-opcache`, `ext-pcre`.
  - **PostgreSQL 14+** con extensiones instaladas en ambas BDs: `pg_trgm`, `unaccent`, `pg_stat_statements`.
  - **Redis 7+** como driver de colas, caché y sesión.
  - **PgBouncer 1.21+** configurado en modo `transaction` con pool de 20 conexiones hacia BD `academia`.
  - **Laravel Octane** con FrankenPHP como servidor HTTP (workers PHP persistentes).
  - **Laravel Horizon** con 4 workers paralelos en cola `cruce`.
  - **OPcache + JIT** habilitados (`opcache.jit=tracing`, buffer 128 MB, `memory_consumption=256`).
- **Frontend**:
  - Node.js 20+ / npm 10+.
  - Dependencias npm: `react`, `@tanstack/react-query`, `react-window`, `zustand`, `axios`.
  - Build de producción: `npm run build` (Vite 8 con manualChunks).
- **Configuración del Entorno Backend**:
  - Copiar `.env.example` a `.env` y completar valores de BD, Redis y feature flags.
  - Ejecutar `php artisan octane:install --server=frankenphp`.
  - Ejecutar `php artisan horizon:install`.
  - Wayfinder: `php artisan wayfinder:generate` debe ejecutarse al modificar rutas del backend.
- **Ejecución en Desarrollo**:
  - `composer run dev` - inicia Octane, Horizon, Pail y Vite en paralelo.
- **Ejecución de Pruebas**:
  - Backend: `php artisan test` (Pest/PHPUnit).
  - Rendimiento: `php artisan test --filter=FuzzyMatchPerformanceTest`.
  - Verificar pg_trgm: `psql -d academia -c "SELECT extname FROM pg_extension WHERE extname='pg_trgm';"`.
  - Verificar índice GIN: `psql -d academia -c "\d+ alumnos"`.
  - Verificar Horizon: `php artisan horizon:status`.
  - Verificar Octane: `php artisan octane:status`.

## Gobernanza de la Constitución

- **Ratificación**: Esta constitución está ratificada por el equipo de desarrollo principal y es de cumplimiento obligatorio para programadores y agentes de IA.
- **Enmiendas**: Cualquier modificación requiere acuerdo del equipo, documentación de la enmienda, incremento de versión y propagación en plantillas.
- **Revisión de Cumplimiento**: Se verificará la adherencia en cada Pull Request y revisión de código.

### 8.2 Amendment Log

| Fecha | Versión | Artículos | Descripción del Cambio | Autor |
|---|---|---|---|---|
| 2026-07-03 | 2.4.0 | III, VII | Incorporación de controles de seguridad: sanitización CSV, mínimo privilegio DB, aislamiento bare metal (Chroot+AppArmor) y perímetro Nginx/ModSecurity/CrowdSec | Antigravity |

**Versión**: 2.4.0 | **Ratificado**: 2026-06-16 | **Última Enmienda**: 2026-07-02 | **Cambios v2.4.0**: Stack de rendimiento inmutable elevado a Art. 4 (pg_trgm, Redis multi-rol, Horizon 4 workers, Octane+FrankenPHP, PgBouncer, OPcache+JIT, Bus::batch, react-window, TanStack Query, PhpSpreadsheet streaming); Configuración de Entorno expandida con infraestructura completa.
