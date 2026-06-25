# Business Context: Motor de Cruce Automático de Ingresantes UNMSM

**Feature ID:** 001-motor-cruce-ingresantes
**Created:** 2026-06-24
**Owner:** Samuel Cisneros (Product Owner)
**Status:** Under Review

---

## 1. Problem Statement

El equipo de admisiones de la academia Vonex no puede cruzar ni validar de manera eficiente las identidades de los ingresantes de la UNMSM contra la base de datos de matrículas debido a que la carga de resultados y el emparejamiento de datos se realizan mediante procesos manuales o propensos a errores con grandes volúmenes de datos (~27,000 filas × 12 columnas), lo que resulta en demoras operativas significativas, timeouts en el servidor, duplicidad de registros y una pérdida de trazabilidad en los resultados analíticos.

---

## 2. Business Justification

### 2.1 Why Now?

Es crítico contar con este motor automatizado inmediatamente después del examen de admisión de la UNMSM para consolidar y reportar con precisión la tasa de éxito de la academia. Esto permitirá al equipo de marketing iniciar campañas de difusión y retención de alumnos con datos 100% validados sin depender de conciliaciones manuales tardías que debilitan la ventaja competitiva.

### 2.2 Business Value

| Value Type | Expected Impact | Measurement |
|------------|-----------------|-------------|
| Revenue | Mejora en captación y retención de alumnos | Mayor número de matrículas nuevas y conversiones post-examen |
| Cost Savings | Reducción de ~80 horas de trabajo manual por proceso de admisión | Horas hombre dedicadas a la conciliación manual de ingresantes |
| Efficiency | Procesamiento de lotes en ≤ 50 segundos | Tiempo total de ejecución del job en cola Redis vs. proceso manual anterior |
| Trazabilidad | 100% de los registros auditables en dual-table | Porcentaje de registros del CSV mapeados a `ingresantes` o `no_ingresantes` |

### 2.3 Cost of Inaction

- Demoras críticas en el lanzamiento de campañas de marketing basadas en ingresantes reales.
- Pérdida de credibilidad por posibles falsos positivos publicados en listas de ingresantes.
- Timeouts y bloqueos recurrentes en el servidor HTTP al intentar procesar archivos de 20 MB síncronamente.

---

## 3. Success Metrics

| Metric | Current Baseline | Target | Timeframe | Measurement Method |
|--------|------------------|--------|-----------|-------------------|
| Tiempo de procesamiento de lote | Horas de trabajo manual | ≤ 50 segundos para ~27k filas | Inmediato al desplegar | Log del job en base de datos (`lotes_cruce`) |
| Precisión del emparejamiento exacto | N/A (Manual) | 100% libre de falsos positivos en coincidencia exacta | Inmediato | Comparación automática contra criterios estrictos |
| Resolución de cabos sueltos | N/A | 100% de registros en estado `pendiente` resueltos vía React | Fin del periodo de admisión | Reporte de lotes con estado de resolución de pendientes |

### Success Definition

Este feature es exitoso cuando:

1. El motor procesa un CSV completo de ingresantes de forma asíncrona mediante Redis en menos de 50 segundos sin causar timeouts HTTP.
2. Todos los ingresantes se normalizan correctamente y se persisten de manera trazable en `ingresantes` (si alcanzaron vacante) o `no_ingresantes`.
3. El 100% de las coincidencias exactas se asocia y confirma automáticamente, y los cabos sueltos (similitud ≥ 30%) son expuestos y resueltos mediante la UI interactiva en React sin requerir herramientas externas.

---

## 4. User Personas

### 4.1 Primary Persona: Administrador de Admisiones

| Attribute | Description |
|-----------|-------------|
| **Role** | Encargado de Procesamiento y Operaciones |
| **Goals** | Cargar el CSV oficial de la UNMSM, visualizar ingresantes pendientes (cabos sueltos) y asociar o descartar alumnos rápidamente de forma asistida. |
| **Pain Points** | Pérdida de tiempo depurando datos en Excel, cuelgues al importar archivos pesados, y dificultad para encontrar homónimos por errores de digitación en el CSV de origen. |
| **Tech Savviness** | Medium |

### 4.2 Secondary Persona: Analista de Negocio / Marketing

| Attribute | Description |
|-----------|-------------|
| **Role** | Analista de Marketing y Difusión |
| **Goals** | Descargar reportes consolidados en Excel con gráficos analíticos incorporados y segmentadores por sede, ciclo y fecha de examen para evaluar el rendimiento de la academia. |
| **Pain Points** | Falta de acceso oportuno a los datos oficiales de ingresantes, reportes incompletos o sin información de valor de negocio como la sede de origen. |

---

## 5. High-Level Requirements

### 5.1 Functional Requirements

| ID | Requirement | Priority | Notes |
|fr-01| El sistema debe cargar, normalizar y filtrar archivos CSV de ingresantes UNMSM agrupándolos por fecha de examen. | Must Have | |
|fr-02| El sistema debe consultar directamente la base de datos `academia` PostgreSQL para obtener alumnos matriculados. | Must Have | |
|fr-03| El sistema debe emparejar ingresantes con alumnos usando un motor de coincidencia en dos fases (exacta y difusa). | Must Have | |
|fr-04| El sistema debe proveer una interfaz interactiva en React para validar manualmente los ingresantes en estado `pendiente`. | Should Have | |
|fr-05| El sistema debe generar un reporte consolidado en formato Excel con gráficos analíticos dinámicos y métricas por sede/ciclo. | Nice to Have | |

### 5.2 Non-Functional Requirements

| ID | Category | Requirement | Priority |
|----|----------|-------------|----------|
| NFR-01 | Performance | El procesamiento de un lote en cola Redis debe completarse en ≤ 50 segundos. | Must Have |
| NFR-02 | Performance | La consulta de candidatos (fuzzy match) debe responder en ≤ 300 ms (percentil 95). | Must Have |
| NFR-03 | Availability | El sistema debe soportar cargas de archivos CSV de hasta 20 MB sin error de límite de memoria en HTTP. | Must Have |
| NFR-04 | Security | Las credenciales de conexión no deben almacenarse en el código; deben gestionarse por variables de entorno. | Must Have |
| NFR-05 | Auditability| Todo lote procesado debe registrar metadatos de auditoría y totales de conciliación en la BD. | Must Have |
| NFR-06 | Reliability | El procesamiento de importación debe ejecutarse mediante cola Redis, tolerando caídas y manteniendo logs de fallos. | Must Have |

---

## 6. Scope Boundaries

### 6.1 In Scope

- ✅ Carga de CSV y persistencia dual en tablas `ingresantes` (cumplen filtro) y `no_ingresantes` (para trazabilidad).
- ✅ Normalización estricta (conversión a MAYÚSCULAS, remoción de tildes y conversión obligatoria de Ñ a N).
- ✅ Algoritmo de coincidencia exacta por apellidos y primer nombre, y coincidencia difusa (Levenshtein) con umbral del 30%.
- ✅ Interfaz en React para la resolución manual de cabos sueltos.
- ✅ Exportación a Excel con dos hojas (data enriquecida y gráficos analíticos).

### 6.2 Explicitly Out of Scope

| Item | Reason | Future Consideration? |
|------|--------|----------------------|
| Integración vía API directa con la UNMSM | La UNMSM no provee APIs públicas; el proceso depende estrictamente de la subida del CSV oficial. | No |
| Modificación de datos en la base `academia` | El motor de cruce es estrictamente de lectura sobre la base de datos de la academia para mantener su integridad. | No |
| Autenticación multifactor (MFA) | Se asume el esquema de sesión y roles estándar de la aplicación principal. | Sí |

---

## 7. Dependencies

### 7.1 Prerequisite Features/Systems

| Dependency | Status | Owner | Impact if Delayed |
|------------|--------|-------|-------------------|
| Base de datos `academia` en PostgreSQL | Ready | Equipo de DB / Infra | Imposible realizar cualquier cruce o validación de alumnos. |
| Entorno Redis activo para colas de Laravel | Ready | Equipo de Infra | El procesamiento masivo de CSV fallaría por timeouts de memoria y tiempo en HTTP. |

---

## 8. Risks & Assumptions

### 8.1 Assumptions

| ID | Assumption | If False, Then... |
|----|------------|-------------------|
| A-01 | El formato y codificación del CSV es siempre UTF-8 o ISO-8859-1. | El procesamiento fallará antes de la importación para evitar datos corruptos. |
| A-02 | La base de datos `academia` cuenta con índices sobre nombres y apellidos. | Degradación severa del performance del motor de cruce, incumpliendo los SLAs. |
| A-03 | El umbral del 30% de Levenshtein es óptimo para cabos sueltos. | Si es muy alto se omiten candidatos; si es muy bajo se genera ruido visual en la UI. |
| A-04 | Un máximo de 5 candidatos potenciales es suficiente para la revisión humana. | Homónimos correctos podrían no mostrarse en la UI interactiva. |
| A-05 | El servicio Redis está disponible y activo en el entorno de producción. | El job no se encolará y el procesamiento masivo fallará. |

### 8.2 Risks

| ID | Risk | Likelihood | Impact | Mitigation Strategy |
|----|------|------------|--------|---------------------|
| R-01 | Degradación de consultas en la base `academia` por falta de índices en nombres/apellidos. | Med | High | Auditar la base de datos en fase de diseño e implementar índices si es necesario. |
| R-02 | Worker de Redis caído durante el procesamiento del job asíncrono. | Low | High | Utilizar la tabla `failed_jobs` para reintento y mantener el estado del lote en `procesando` sin corromper datos. |

---

## 9. Stakeholder Sign-off

- [x] Product Owner: Samuel Cisneros - Date: 2026-06-25
- [x] Business Sponsor: Samuel Cisneros - Date: 2026-06-25
