---
# Wave 23 §23.A.9/§23.A.10 — memory frontmatter for time-decay ranking
last_referenced_at: "2026-04-14T21:22:22.712336+00:00"
reference_count: 0
decay_floor: true
---

<!--
SYNC IMPACT REPORT:
- Version change: 2.5.0 -> 2.6.0
- List of modified principles:
  * Art. 3 - Estándares de Calidad: Se añade la regla de deduplicación por CODIGO+OBSERVACION dentro del lote; se añade el Contrato de Columnas inmutable para el Excel; se añade el principio de "solo Excel" como formato de salida.
  * Art. 4 - Principios de Arquitectura: Se añade el módulo independiente de Catálogo de Áreas y Carreras y su regla de consumo exclusivo en exportación; se añade el selector de exportación por fecha o consolidado.
  * Art. 6 - Límites (Las Tres Listas): Se añaden reglas ALWAYS DO / NEVER DO sobre el Contrato de Columnas, el uso del catálogo solo en exportación, y el formato exclusivo .xlsx.
- Added sections:
  * Flujo del Proceso de Cruce (actualizado con paso de selector de exportación)
- Removed sections: None
- Templates requiring updates:
  * OK spec.md (v2.6.0, alineado)
  * OK plan.md (v2.3.0, alineado)
- Follow-up TODOs:
  * Confirmar formato de carga del catálogo de Áreas y Carreras (ver spec.md Assumption A-06) antes de iniciar desarrollo de US-006.
-->

# Constitución del Proyecto Vonex

## Principios Fundamentales

### Art. 1 – Tareas pequeñas, una a la vez

- **Reglas**: Trabajar siempre en pasos de bebé (baby steps), uno a la vez. Nunca avanzar más de un paso a la vez. Asegurar que cada paso esté completamente verificado antes de continuar.
- **Justificación**: Mantiene los cambios manejables, reduce la complejidad de depuración y asegura la corrección del código.

### Art. 2 – Preservación de Patrones y Compatibilidad

- **Reglas**:
  - **Backend**: Patrón de clases de Acción (`app/Actions/`) con un único método público `execute()` que retorna `success`, `data`, `error`. Controladores delgados, relaciones de Eloquent limpias, tipado estricto (`declare(strict_types=1);`). Compatibilidad estricta con PHP 8.4+.
  - **Frontend**: React (Vite) SPA con componentes funcionales y Hooks reactivos, consumiendo la API REST de Laravel.
- **Justificación**: Garantiza legibilidad, mantenibilidad y alineación arquitectónica con el stack moderno del proyecto.

### Art. 3 – Estándares de Calidad

- **Reglas**:
  - **Integridad de Normalización**: Todo texto procesado desde el CSV crudo debe convertirse obligatoriamente a MAYÚSCULAS, sin tildes y con reemplazo estricto de la "Ñ" por "N". No se aceptan excepciones.
  - **Precisión del Cruce (Match Exacto e Integración Difusa)**:
    - Regla inicial estricta para cruce automático: `2 apellidos exactos + 1 nombre exacto` (Cero Falsos Positivos).
    - Cabos sueltos: match difuso interactivo antes de guardarse.
    - **Umbral dual de similitud (inmutable):** cálculo interno ≥30%; visualización en React solo ≥70%. Cualquier modificación requiere enmienda constitucional documentada.
    - **Sistema de colores por rango de similitud (inmutable):** 95-100% verde intenso (`#16a34a`); 85-94% verde claro (`#4ade80`); 70-84% amarillo/ámbar (`#eab308`). Ningún candidato por debajo del 70% se expone al administrador.
  - **Deduplicación de Lotes (inmutable, NUEVO):** La conformación de un lote por `FECHA_EXAMEN` y la detección de duplicados dentro de él se realiza **siempre** usando la combinación `CODIGO` (código único de postulante) + `OBSERVACION` normalizada como clave de identificación del registro — nunca únicamente la fecha de examen a nivel de lote completo. Esta clave debe reforzarse con un índice único a nivel de base de datos.
  - **Formato Exclusivo de Salida (inmutable, NUEVO):** El único artefacto de reporte descargable por el usuario final es un archivo **Excel (`.xlsx`)**. No se ofrecen ni se desarrollan rutas de exportación a CSV, PDF, JSON u otro formato para el reporte consolidado de ingresantes.
  - **Selector de Exportación (NUEVO):** Toda pantalla de descarga del reporte debe ofrecer al usuario exactamente dos modalidades de filtro: (a) una `FECHA_EXAMEN` específica, o (b) "Todas las fechas" (consolidado). No se permiten otras granularidades de filtro (ej. por rango de fechas libre) sin enmienda constitucional.
  - **Contrato de Columnas (inmutable, NUEVO):** Existe un conjunto fijo y documentado de columnas (definido en `spec.md`, US-005) que debe aparecer siempre, en el mismo orden, con las mismas cabeceras, en la Hoja 1 del Excel exportado — sin importar si el usuario descargó por fecha específica o consolidado, y sin importar si algún campo enriquecido carece de valor (en cuyo caso se usa la etiqueta `SIN MAPEAR`, nunca se omite la columna). Modificar este contrato requiere enmienda constitucional documentada (Art. 6.2).
  - **Catálogo de Áreas y Carreras — Alcance de Uso (inmutable, NUEVO):** El catálogo oficial de Áreas y Carreras UNMSM es un dato maestro independiente del flujo de ingresantes. **Su único punto de consumo permitido en todo el sistema es el momento de generación del Excel** (`ExportarExcelCruceAction`). Está prohibido usar el catálogo durante la carga del CSV de ingresantes, durante el cruce exacto o durante el cálculo de similitud difusa.
  - **Alcance del Excel final:** El reporte Excel contiene únicamente registros con `estado_match IN ('confirmado_automatico', 'confirmado_manual')`. Los registros `pendiente` y `no_ingresado` no aparecen en el Excel (en ninguna de las dos modalidades de descarga) pero se preservan en la BD para auditoría (NFR-005).
  - **Prioridad Histórica Inmutable**: 1. MATRICULADO, 2. PAGADO, 3. FINALIZADO, 4. SUSPENDIDO, 5. RETIRADO, 6. TRASLADADO, 7. STAND BY, 8. ANULADO.
  - **Estándares de Codificación**: Símbolos técnicos en inglés. Términos de dominio (tablas, columnas de BD, reglas de negocio) e interfaz de usuario en español.
  - **Reglas de Linting y Formateador**: Cumplimiento estricto sin excepciones.
  - **Data Protection**:
    - **Sanitización de Exportaciones**: Todo dato proveniente de fuentes externas (CSV de ingresantes y CSV/archivo de catálogo) debe sanitizarse antes de persistirse y exportarse a Excel para prevenir CSV/Formula Injection. Ningún campo puede comenzar con `=`, `+`, `-`, `@` sin ser neutralizado.
    - **Mínimo Privilegio en Base de Datos**: El usuario de PostgreSQL para `academia` tiene permisos estrictos de `SELECT`; `INSERT`/`UPDATE` únicamente sobre `lotes_cruce`, `ingresantes_cruce` y `catalogo_areas_carreras`.
    - **Validación Estricta de Tipos MIME**: La carga de cualquier archivo (CSV de ingresantes o catálogo de Áreas/Carreras) debe validar el contenido binario (Magic Bytes), no solo la extensión.
    - **Aislamiento de Carga de Trabajo**: El procesamiento masivo (cálculo de similitudes, generación de Excel consolidado) se ejecuta de forma asíncrona mediante colas Laravel.
- **Justificación**: Garantiza precisión analítica absoluta y trazabilidad de negocio real (no solo por fecha), consistencia total del formato de salida y separación limpia entre datos maestros (catálogo) y datos transaccionales (ingresantes).

### Art. 4 – Principios de Arquitectura

- **Reglas**:
  - **Pipeline sin intervención manual**: Lectura del CSV, loteo, deduplicación por `CODIGO`+`OBSERVACION` y consultas a `academia` se gestionan por script PHP, sin filtrado previo en hojas de cálculo.
  - **Centralización Analítica**: Resultado final siempre en un archivo Excel para distribución; el pipeline interno no depende de archivos intermedios estáticos.
  - **Módulo de Catálogo Independiente (NUEVO)**: La carga y mantenimiento del catálogo de Áreas y Carreras UNMSM es un módulo desacoplado del pipeline de lotes de ingresantes, con su propia pantalla de administración, su propia tabla (`catalogo_areas_carreras`) y su propio ciclo de vida (upsert sin afectar lotes existentes). Se consume por referencia únicamente en tiempo de exportación.
  - **Selector de Exportación Único (NUEVO)**: La exportación se expone mediante un único endpoint parametrizado que acepta un identificador de lote o el valor "todas las fechas", garantizando que el Contrato de Columnas (Art. 3) se aplique de forma centralizada y no diverja entre modalidades de descarga.
  - **Gestión de Errores Silenciosos**: Timeout o error de conexión pausa el lote y alerta; datos parcialmente procesados se marcan para revisión.
  - **Auditoría y trazabilidad**: Se registra cada lote, cada `Fecha de Examen`, cada `CODIGO` omitido por duplicado, el resultado del cruce y cualquier fallo.
  - **Seguridad de credenciales**: Variables de entorno (`.env`) exclusivamente.
  - **Pruebas automatizadas**: Cobertura unitaria e integrada para lógica de cruce, deduplicación, exportación y catálogo. Pruebas manuales (curl/MCP) complementan, no reemplazan.
  - **SLA de rendimiento de validación manual**: Vista de validación React ≤5 minutos para lotes de hasta ~27,000 registros (`pg_trgm`, Redis cache TTL 1h, chunking de 500).
  - **Stack de rendimiento inmutable**: `pg_trgm` + índice GIN (prohibido Levenshtein en bucle PHP); Redis como driver único de colas/caché/sesión; Laravel Horizon (mín. 4 workers); Laravel Octane + FrankenPHP; PgBouncer (modo `transaction`, pool 20); PHP OPcache + JIT; `Bus::batch()` (chunks de 500); `react-window`; TanStack Query v5 (cursor pagination); PhpSpreadsheet en modo streaming (obligatorio también para el modo de exportación "Todas las fechas", dado su mayor volumen acumulado).
- **Justificación**: Claridad en la separación de responsabilidades, robustez ante fallos, y portabilidad del motor analítico y de sus datos maestros.

### Art. 5 – Estándares de Lenguaje

- **Reglas**: Codificación técnica (variables, clases, funciones, commits) en inglés. Elementos visibles al usuario y conceptos de negocio de BD en español.
- **Justificación**: Profesionalidad del código y comprensión por usuarios y administradores.

### Art. 6 – Límites (Las Tres Listas)

- **SIEMPRE HACER (ALWAYS DO)**:
  - Etiquetar cada registro entrante con su "Fecha de Examen" automáticamente.
  - Validar conexión a la BD `academia` antes de procesar cualquier lote.
  - Deduplicar registros dentro de un lote usando `CODIGO` + `OBSERVACION`, no solo la fecha de examen.
  - Ignorar silenciosamente los registros/lotes ya procesados, registrando el detalle en el log.
  - Ofrecer siempre las dos modalidades de descarga del reporte: fecha específica o "Todas las fechas".
  - Incluir el 100% de las columnas del Contrato de Columnas en cada Excel generado, sin importar la modalidad de descarga ni la disponibilidad del dato (usar `SIN MAPEAR` cuando corresponda).
  - Consumir el catálogo de Áreas y Carreras únicamente en el momento de generar el Excel.
  - Aplicar el sistema de colores por rango de similitud (≥95% verde intenso, 85-94% verde claro, 70-84% amarillo) en la interfaz React de validación.
  - Filtrar el Excel final para incluir exclusivamente registros `confirmado_automatico` o `confirmado_manual`.
  - Realizar desarrollos en pasos cortos con entregas incrementales y frecuentes.
  - Retornar respuestas JSON desde controladores de API.
  - Probar manualmente endpoints mediante `curl` o navegador MCP antes de finalizar una iteración.
- **PREGUNTAR PRIMERO (ASK FIRST)**:
  - Antes de alterar o expandir la lista de los 8 estados permitidos para el cruce.
  - Si la estructura de columnas del CSV de origen (ingresantes o catálogo) sufre alguna modificación.
  - Antes de modificar el Contrato de Columnas del Excel.
  - Antes de añadir una tercera modalidad de descarga (ej. rango de fechas libre) al selector de exportación.
  - Agregar nuevas dependencias a Composer o npm.
  - Modificar esquemas de bases de datos.
- **NUNCA HACER (NEVER DO)**:
  - Volver a la manipulación manual de datos o delegar el filtrado de fechas/duplicados a intervención humana.
  - Sobrescribir datos de días de examen anteriores al procesar un nuevo lote.
  - Guardar directamente coincidencias no exactas sin revisión interactiva del usuario.
  - Omitir columnas del Contrato de Columnas en el Excel, incluso si están vacías para todos los registros del filtro elegido.
  - Ofrecer o desarrollar exportación en un formato distinto a `.xlsx` para el reporte de ingresantes.
  - Usar el catálogo de Áreas y Carreras en ningún paso del pipeline distinto a la exportación (ni en carga, ni en cruce exacto, ni en cálculo de similitud).
  - Mostrar en la interfaz React candidatos con similitud < 70%.
  - Incluir registros `pendiente` o `no_ingresado` en el Excel final, en ninguna modalidad de descarga.
  - Modificar los códigos hexadecimales de color del sistema de rangos de similitud sin enmienda constitucional.
  - Confiar ciegamente en la extensión de archivo (`.csv`); siempre validar Magic Bytes y tipo MIME real, tanto para el CSV de ingresantes como para el archivo del catálogo.
  - Escribir SQL directo en vistas Blade o lógica de negocio en Controladores.
  - Exponer endpoints de procesamiento masivo o de exportación sin Rate Limiting estricto.
- **Justificación**: Reglas de control estrictas para salvaguardar calidad de datos, consistencia del reporte final y separación de responsabilidades entre datos transaccionales y datos maestros.

## Flujo del Proceso de Cruce

1. **Conexión y Extracción**: El sistema se conecta a la base de datos `academia` para extraer los datos de los alumnos matriculados vigentes.
2. **Carga de Archivo**: El usuario sube el archivo CSV de ingresantes a San Marcos.
3. **Loteo y Deduplicación (ACTUALIZADO)**: El sistema agrupa los registros en lotes por `FECHA_EXAMEN`; dentro de cada lote, identifica y deduplica cada registro por la clave `CODIGO` + `OBSERVACION`, ignorando silenciosamente lo ya procesado y registrándolo en el log.
4. **Cruce Inicial (Coincidencia Exacta)**: `2 apellidos exactos + 1 nombre exacto` → estado `confirmado_automatico`.
5. **Tratamiento de Cabos Sueltos (Match Difuso)**: umbral interno 30%, visible en UI solo ≥70%, coloreado por rango. El administrador confirma (`confirmado_manual`) o descarta (`no_ingresado`).
6. **Mantenimiento Independiente del Catálogo (NUEVO)**: En paralelo, y de forma independiente al ciclo de vida de los lotes, el administrador puede subir o actualizar el catálogo oficial de Áreas y Carreras UNMSM.
7. **Selección y Exportación del Reporte (ACTUALIZADO)**: El usuario elige, en la pantalla de exportación, si desea el reporte de una `FECHA_EXAMEN` específica o de "Todas las fechas" consolidadas. El sistema genera el Excel filtrando solo registros `confirmado_automatico`/`confirmado_manual`, aplicando siempre el Contrato de Columnas completo, y enriqueciendo `AREA_OFICIAL`/`CARRERA_OFICIAL` desde el catálogo vigente en ese momento (usando `SIN MAPEAR` si no hay coincidencia).

## Flujo de Trabajo Git y Colaboración

- **Rama `main` / `master`**: Producción estable. Solo se sube código verificado mediante pull requests.
- **Rama `develop`**: Entorno de desarrollo e integración.
- **Ramas de Características (`feature/`)**: Cada nueva funcionalidad o API se desarrolla en una rama dedicada.
- **Validaciones**: Antes de fusionar con `develop`, todo código debe pasar por revisiones de QA.
- **Integrantes y Funciones**:
  - **Samuel Cisneros**: Product Owner (PO) / Product Manager
  - **Renzo Fabián**: Tech Lead / Lead Developer
  - **Diego Fernando**: QA Tester / Co-Lead de Constitución
  - **Yerson Vargas**: QA / Apoyo Técnico

## Configuración y Ejecución de Pruebas

- **Backend**: PHP 8.4+ (`ext-pgsql`, `ext-redis`, `ext-opcache`, `ext-pcre`); PostgreSQL 14+ (`pg_trgm`, `unaccent`); Redis 7+; PgBouncer 1.21+; Laravel Octane + FrankenPHP; Laravel Horizon (4 workers).
- **Frontend**: Node.js 20+/npm 10+; `react`, `@tanstack/react-query`, `react-window`, `zustand`, `axios`; build con Vite 8.
- **Ejecución de Pruebas**: `php artisan test` (Pest/PHPUnit); `php artisan test --filter=FuzzyMatchPerformanceTest`; `php artisan test --filter=ExportacionSelectorTest`; `php artisan test --filter=CatalogoAreasCarrerasTest`.

## Gobernanza de la Constitución

- **Ratificación**: Esta constitución está ratificada por el equipo de desarrollo principal y es de cumplimiento obligatorio para programadores y agentes de IA.
- **Enmiendas**: Cualquier modificación requiere acuerdo del equipo, documentación de la enmienda, incremento de versión y propagación en `spec.md`/`plan.md`.
- **Revisión de Cumplimiento**: Se verifica adherencia en cada Pull Request.

### Amendment Log

| Fecha | Versión | Artículos | Descripción del Cambio | Autor |
|---|---|---|---|---|
| 2026-06-16 | 2.2.0 | All | Versión base ratificada | Equipo V2 |
| 2026-06-24 | 2.4.0 | III, IV | Stack de rendimiento inmutable, Redis Queue, persistencia dual | Equipo V2 |
| 2026-07-03 | 2.5.0 | III, VII | Controles de seguridad: sanitización CSV, mínimo privilegio DB | Antigravity |
| **2026-07-03** | **2.6.0** | **III, IV, VI** | **Deduplicación de lote por `CODIGO`+`OBSERVACION`; formato exclusivo Excel; selector de exportación por fecha o consolidado; Contrato de Columnas inmutable; módulo independiente de Catálogo de Áreas y Carreras consumido solo en exportación** | **Equipo V2** |

**Versión**: 2.6.0 | **Ratificado**: 2026-06-16 | **Última Enmienda**: 2026-07-03
