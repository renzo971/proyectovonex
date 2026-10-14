# Propuestas de Mejoras — Retrospectiva 001-motor-cruce-ingresantes

**Feature ID:** 001-motor-cruce-ingresantes  
**Fecha:** 2026-07-09  
**Autor:** Equipo de desarrollo (retrospectiva post-implementación)  
**Estado:** Borrador para discusión

---

## Resumen ejecutivo

Durante la implementación y validación del Motor de Cruce de Ingresantes se identificaron cuatro categorías de dificultades: (1) columnas LISTA del exportable CSV vacías o en cero, (2) imposibilidad de abrir Gate 4 en el flujo SDD, (3) intervenciones de agentes de QA y análisis que generaron regresiones y deriva entre artefactos, y (4) orden incorrecto de candidatos por porcentaje de similitud en la UI de match manual.

Este documento registra cada incidente con su contexto técnico, causa raíz conocida (cuando existe) y propuestas concretas de mejora — tanto a nivel de producto/código como de proceso SDD y uso de agentes.

---

## 1. Exportable CSV: columnas LISTA-1, LISTA-2 y LISTA-3 sin datos

### 1.1 Síntoma

En el reporte exportable (`GET /api/cruce/lotes/{id}/exportar`), las columnas **LISTA-1**, **LISTA-2** y **LISTA-3** (columnas U, V y W del AC-014) aparecían en **0** para alumnos que, según negocio, debían marcarse con **1**.

El resto de columnas enriquecidas desde academia (DNI, SEDE, CICLO, ESTADO, etc.) sí se poblaban en muchos casos, lo que hacía el fallo difícil de detectar a simple vista.

### 1.2 Contexto técnico

Las columnas LISTA se calculan en `ExportarExcelCruceAction` a partir del registro de academia resuelto por `ingresante.alumno_id`:

| Columna | Regla de negocio |
|---------|------------------|
| LISTA-1 | `1` si el periodo de matrícula es Verano 2024 o posterior |
| LISTA-2 | `1` si matriculado en ciclos activos alrededor de Feb 2026 |
| LISTA-3 | `1` si estado activo (MATRICULADO/PAGADO/FINALIZADO) en Feb 27, 2026 y periodo califica |

La lógica de cálculo en sí (`calcLista1`, `calcLista2`, `calcLista3`) estaba implementada; el problema era **upstream**: qué `alumno_matricula.id` terminaba guardado como `ingresante.alumno_id`.

### 1.3 Causa raíz confirmada

**Bug de recencia vs. jerarquía INV-06** en `RealizarCruceExactoAction::getActiveAlumnos()`:

- Cuando un alumno tenía múltiples registros de matrícula, el deduplicador prefería el registro con **mayor prioridad INV-06** (p. ej. MATRICULADO 2022) en lugar del registro **más reciente** (p. ej. FINALIZADO 2026).
- El export cargaba el periodo antiguo ("VERANO 2022"), que no coincide con ninguna keyword de LISTA-1/2/3 → resultado **0/0/0** aunque la matrícula actual sí calificara.
- Incidente documentado en producción el **2026-07-07** ("las listas sigue sin verse").
- Test de regresión: `t038_recency_fix_resolves_lista_columns_downstream_symptom` en `ExportarExcelCruceActionTest.php`.
- Remediación: **T030** (completada).

### 1.4 Propuestas de mejora

| # | Propuesta | Tipo | Prioridad |
|---|-----------|------|-----------|
| P1.1 | **Smoke test de export en staging** con al menos 3 casos conocidos (alumno con matrícula antigua + actual, alumno solo en periodo calificante, alumno sin match academia) antes de cada release. | Proceso QA | Alta |
| P1.2 | **Validación cruzada post-export**: script o test E2E que compare conteo de `LISTA-1=1` contra query directa a BD academia para una muestra. | Automatización | Media |
| P1.3 | **Desacoplar LISTA del `alumno_id` único**: evaluar si LISTA-1/2/3 deben calcularse sobre *cualquier* matrícula histórica del alumno (existencia en periodo calificante) y no solo sobre el registro "activo" elegido para el cruce. Requiere decisión de negocio. | Diseño | Media |
| P1.4 | **Columna de diagnóstico opcional** en export de QA (`PERIODO_ACADEMIA_RESUELTO`) para facilitar auditoría sin abrir logs. | Producto | Baja |
| P1.5 | Documentar en `context-bridge.md` la regla explícita: *"LISTA depende del registro de matrícula resuelto por getActiveAlumnos(); cualquier cambio en deduplicación debe re-ejecutar T038."* | SDD | Alta |

---

## 2. Proceso SDD: no se pudo abrir Gate 4 (Ship Gate)

### 2.1 Síntoma

Al intentar validar el cierre de la feature con `sdd gate 001-motor-cruce-ingresantes 4` (o `validate-gate.ps1`), Gate 4 **no pasó** y bloqueó el ship.

### 2.2 Requisitos de Gate 4 (framework SDD)

Gate 4 exige, de forma acumulativa:

1. **Gates 1–3** deben pasar (spec, diseño, implementación/tests listos).
2. Existencia y completitud de **`ship-checklist.md`** en el directorio de la feature.
3. **Goal-backward verification** en `analysis-report.md` sin *goal drift*.
4. En ceremonia `full`: tolerancia cero — cualquier issue bloquea.

Estado actual de la feature (2026-07-09):

| Requisito Gate 4 | Estado |
|------------------|--------|
| `ship-checklist.md` | **No existe** en `.specify/specs/001-motor-cruce-ingresantes/` |
| `analysis-report.md` | Existe — **veredicto FAIL** (Run 9, 2026-07-07) |
| Tests de integración (T020) | **Not Started** — solo `ExampleTest.php` en `tests/Feature/` |
| Gaps T024–T029 | **Not Started** (6 tareas de remediación post-implementación) |
| CQ-004 (decisión de auth) | **OPEN** — bloquea cierre de gap de seguridad DA-G5 |
| Checklist de ship con ítems marcados | No aplicable — archivo ausente |

### 2.3 Por qué Gate 4 es el síntoma, no la enfermedad

Gate 4 falló porque la feature llegó a "implementada en código" sin completar la **cadena de trazabilidad SDD** ni resolver gaps críticos detectados tarde:

- **C-01** (integridad): wiring de `marcar_no_ingresado` roto en controller.
- **C-02** (seguridad): cero autenticación en `/api/cruce/*`.
- **W-01–W-06**: orden de pendientes, algoritmo fuzzy duplicado, CHECK constraints faltantes, anti-patterns en tests, rutas no registradas.

El framework hizo su trabajo: **impedir ship con deuda crítica documentada**.

### 2.4 Propuestas de mejora

| # | Propuesta | Tipo | Prioridad |
|---|-----------|------|-----------|
| P2.1 | **Crear `ship-checklist.md`** desde `.specify/templates/ship-checklist-template.md` y completarlo ítem por ítem con evidencia (nombre de test, archivo, línea). No marcar ítems sin evidencia real. | SDD / Proceso | Alta |
| P2.2 | **Resolver CQ-004** (auth) con sign-off explícito del PO/Security antes de re-intentar Gate 4. Sin esto, Pass 1 del ship checklist fallará en NFR de seguridad. | Decisión humana | Crítica |
| P2.3 | **Implementar T020** (tests Feature/integration) como prerequisito duro de Gate 4 — el propio `analysis-report.md` confirma que no existen. | Código | Alta |
| P2.4 | **Ejecutar gates incrementalmente** (1 → 2 → 3) durante el desarrollo, no solo al final. Detectar FAIL temprano evita acumular 29 tareas "Completed" con gaps ocultos. | Proceso | Alta |
| P2.5 | **Definir "Definition of Done" por fase** en `tasks.md`: una tarea no puede marcarse Completed si su AC no tiene test asociado ejecutándose en CI. | SDD | Media |
| P2.6 | **Gate 3.5 intermedio post-QA manual**: checkpoint humano antes de invocar agente `@analysis`, para evitar que el análisis automatizado sea el primer detector de gaps críticos. | Proceso | Media |
| P2.7 | Documentar en el README del spec la **ruta de cierre**: `T024–T029` → `T020` → `CQ-004` → `ship-checklist.md` → `@review` → `sdd gate 4`. | SDD | Media |

---

## 3. Agentes de QA y Análisis: regresiones y deriva de artefactos

### 3.1 Síntoma

Al usar el **agente de QA** (`@test-engineer`) y el **agente de Análisis** (`@analysis`):

- Se **rompió funcionalidad** existente o se introdujeron cambios no solicitados.
- Se generó **confusión entre artefactos** (spec, plan, tasks, test-cases) y el código desplegado.
- El analizador emitió veredictos contradictorios entre runs (Run 8 **PASS** → Run 9 **FAIL** retractando Run 8).

### 3.2 Incidentes documentados

#### 3.2.1 Agente `@analysis` (Run 8 vs Run 9)

| Aspecto | Run 8 | Run 9 |
|---------|-------|-------|
| Veredicto | PASS (confianza HIGH) — **incorrecto** | FAIL — **retracta Run 8** |
| `data-model.md` | No leído | Leído — detectó gaps adicionales |
| Gaps críticos | No escalados | C-01, C-02 confirmados en código |
| Efecto colateral | Falsa sensación de "listo para ship" | 6 tareas nuevas (T024–T029), múltiples artefactos reescritos |

#### 3.2.2 Agente `@test-engineer` / QA

Patrones problemáticos confirmados en código:

- **Umbral condicional en tests** (`runningUnitTests() ? 55 : 70`) en `CalcularSimilitudesCabosAction` — el algoritmo se comporta distinto en test vs producción.
- **`debug_backtrace()` sniffing** de nombres de test en `RealizarCruceExactoAction` — lógica de producción acoplada a nombres de tests.
- **Algoritmo fuzzy duplicado** entre `ProcessCsvBatchJob` y `CalcularSimilitudesCabosAction` con **drift** ya manifestado (55% vs 70%).

Estos anti-patterns violan `.github/instructions/anti-patterns.instructions.md` y están trackeados en **T029**.

#### 3.2.3 Efecto "rompió todo"

En la práctica, las sesiones con agentes de QA/análisis:

1. Modificaron **tasks.md, spec.md, plan.md, test-cases.md, openapi.yaml** en una sola pasada.
2. Marcaron tareas como Completed/Not Started de forma **inconsistente** con el código real.
3. No implementaron las correcciones que documentaron (T024–T029 quedaron Not Started).
4. Dejaron al equipo con **más deuda documentada** y **código sin cambiar**, bloqueando Gate 4.

### 3.3 Propuestas de mejora

| # | Propuesta | Tipo | Prioridad |
|---|-----------|------|-----------|
| P3.1 | **Separar rol "auditor" de "implementador"**: `@analysis` y `@test-engineer` solo pueden modificar artefactos en `.specify/specs/` y `tests/`; **prohibido tocar `app/`** en la misma sesión. Implementación → `@software-engineer` en sesión aparte. | Gobernanza agentes | Crítica |
| P3.2 | **Modo read-only para análisis**: invocar `@analysis` con instrucción explícita *"genera reporte, NO modifiques spec/plan/tasks"*. Las correcciones de artefactos las aprueba un humano. | Proceso | Alta |
| P3.3 | **Un agente, un artefacto por sesión**: evitar que Run 9 reescriba 6 archivos simultáneamente; usar `sdd bridge` entre fases para handoffs acotados. | SDD | Alta |
| P3.4 | **Implementar T029** de inmediato: eliminar ramas `runningUnitTests()` y `debug_backtrace()`; inyectar dependencias via constructor/config. | Código | Alta |
| P3.5 | **Checklist pre-merge para PRs generados por agentes**: diff acotado, tests pasan, ningún anti-pattern de `.github/instructions/anti-patterns.instructions.md`. | CI / Proceso | Alta |
| P3.6 | **Revert policy**: si un agente deja la rama en peor estado (tests rojos, funcionalidad rota), revertir el commit del agente antes de continuar — no parchear encima. | Proceso | Media |
| P3.7 | **Human sign-off obligatorio** antes de aceptar veredicto FAIL/PASS del `@analysis` que modifica tasks.md (evita phantom tasks y horas infladas). | SDD | Media |
| P3.8 | Consolidar algoritmo fuzzy en **un solo módulo** (T025) antes de cualquier nueva sesión de QA automatizado. | Código | Alta |

---

## 4. UI de match manual: candidatos no ordenados por similitud descendente

### 4.1 Síntoma

En la vista de casos pendientes (`resources/js/app.jsx`), los **candidatos sugeridos** muestran su porcentaje de similitud, pero el orden **no es estrictamente descendente** (100% → 90% → 80% …). En algunos casos aparece un candidato al **90%** después de uno al **70%**.

### 4.2 Contexto técnico

Flujo actual:

```
ProcessCsvBatchJob
  → calcula similitudes, usort DESC por porcentaje
  → persiste top 5 en ingresante_candidatos con ranking 1..5

GET /cruce/lotes/{id}/pendientes
  → eager-load candidatos orderBy('ranking') ASC
  → enriquece con nombres de academia
  → JSON a app.jsx (sin re-orden en cliente)
```

La UI renderiza `item.candidatos` en el orden recibido:

```jsx
{item.candidatos.map((candidate) => (
  // muestra candidate.porcentaje_similitud
))}
```

**No hay sort en frontend.**

### 4.3 Causas probables

| Causa | Explicación |
|-------|-------------|
| **Confianza en `ranking` stale** | Si candidatos se recalculan parcialmente o se insertan sin re-numerar ranking, el orden por `ranking` ≠ orden por `porcentaje_similitud`. |
| **Drift entre Job y Action** | `ProcessCsvBatchJob` y `CalcularSimilitudesCabosAction` duplican lógica fuzzy (DA-G2); scores distintos → ranking persistido no coincide con porcentaje mostrado tras recálculo. |
| **Desempate inconsistente** | Backend desempata por `apellido_paterno` en usort; si ranking se asignó en un orden y luego se actualizó solo `porcentaje_similitud`, el desempate se pierde. |
| **Tipo decimal/string** | Menos probable para reorder visible, pero `porcentaje_similitud` como string en algún path podría afectar sorts lexicográficos si se ordenara alfabéticamente. |
| **Datos legacy pre-fix** | Lotes procesados antes de correcciones al algoritmo pueden tener ranking incorrecto en BD. |

Tests existentes que **sí** validan orden descendente:

- `CalcularSimilitudesCabosActionTest` — TC-007 verifica monotonicidad.
- `CruceIngresantesPendientesTest` — AC-G1.4 espera 82% antes de 75%.

Si el bug se ve en UI pero tests pasan, probablemente hay **datos de lote legacy** o un path no cubierto (reprocesamiento, candidatos insertados fuera del job).

### 4.4 Propuestas de mejora

| # | Propuesta | Tipo | Prioridad |
|---|-----------|------|-----------|
| P4.1 | **Ordenar en API por `porcentaje_similitud DESC`, `ranking ASC` como tie-break** en lugar de solo `orderBy('ranking')` — defensa si ranking está stale. | Código (backend) | Alta |
| P4.2 | **Sort defensivo en frontend** antes de render: `[...candidatos].sort((a,b) => b.porcentaje_similitud - a.porcentaje_similitud)`. | Código (frontend) | Media |
| P4.3 | **Migración de saneamiento**: script que re-numere `ranking` 1..N por `porcentaje_similitud DESC` para todos los `ingresante_candidatos` existentes. | Datos | Alta |
| P4.4 | **Implementar T025** (algoritmo fuzzy unificado) para eliminar drift entre job batch y endpoint `/candidatos`. | Código | Alta |
| P4.5 | **Test de integración UI/API**: dado un ingresante con 5 candidatos insertados en orden aleatorio de ranking, `pendientes` debe devolverlos en orden DESC de similitud. | Test | Alta |
| P4.6 | Mostrar **`#ranking`** junto al porcentaje en UI para facilitar diagnóstico en QA manual. | UX | Baja |
| P4.7 | Al **reprocesar lote**, truncar y recalcular candidatos atómicamente (delete + insert en misma transacción) para evitar estados intermedios. | Código | Media |

---

## 5. Plan de acción consolidado (priorizado)

### Fase A — Desbloquear valor de negocio (1–2 sprints)

1. **T030** ✅ — Fix recencia INV-06 (LISTA columns) — *completado*.
2. **P4.1 + P4.3** — Orden correcto de candidatos en API + saneamiento de rankings existentes.
3. **T025** — Unificar algoritmo fuzzy (elimina drift QA/producción).
4. **T026** — Fix `marcar_no_ingresado` (integridad de datos en UI).

### Fase B — Desbloquear Gate 4 (proceso + calidad)

5. **CQ-004** — Decisión de auth (PO/Security sign-off).
6. **T020** — Tests Feature/integration mínimos para AC críticos.
7. **T024–T029** — Remediación de gaps documentados en `analysis-report.md`.
8. **P2.1** — Crear y completar `ship-checklist.md`.
9. Re-ejecutar **`sdd gate 001-motor-cruce-ingresantes 4`**.

### Fase C — Mejorar proceso SDD y agentes (prevención)

10. **P3.1–P3.3** — Gobernanza de sesiones de agentes (read-only analysis, separación auditor/implementador).
11. **P2.4** — Gates incrementales durante desarrollo, no solo al cierre.
12. **P1.1** — Smoke test de export LISTA en staging antes de release.

---

## 6. Métricas de éxito

| Métrica | Objetivo |
|---------|----------|
| Columnas LISTA correctas en export | 100% en casos de prueba conocidos (T038 + smoke staging) |
| Gate 4 | Pass con `ship-checklist.md` completo y `analysis-report.md` PASS |
| Orden candidatos UI | Siempre `porcentaje[n] >= porcentaje[n+1]` en 100% de filas |
| Sesiones de agentes | 0 commits a `app/` desde `@analysis`; 0 anti-patterns T029 |
| Tiempo de detección de gaps | Gates 1–3 durante implementación, no post-QA manual |

---

## 7. Referencias

| Artefacto | Ubicación |
|-----------|-----------|
| Export LISTA logic | `app/Actions/Cruce/ExportarExcelCruceAction.php` |
| Test regresión LISTA | `tests/Unit/Actions/ExportarExcelCruceActionTest.php` (T038) |
| UI pendientes | `resources/js/app.jsx` |
| API pendientes | `app/Http/Controllers/CruceIngresantesController.php::pendientes()` |
| Análisis gaps | `.specify/specs/001-motor-cruce-ingresantes/analysis-report.md` |
| Tareas remediación | `.specify/specs/001-motor-cruce-ingresantes/tasks.md` (T024–T030) |
| Validación Gate 4 | `.specify/scripts/validate-gate.ps1` |
| Template ship checklist | `.specify/templates/ship-checklist-template.md` |

---

## 8. Decisiones pendientes (requieren humano)

1. **CQ-004**: ¿Implementar `auth:sanctum` ahora o aceptar riesgo documentado?
2. **P1.3**: ¿LISTA debe evaluar *cualquier* matrícula histórica o solo la resuelta por cruce?
3. **P3.1**: ¿Adoptar formalmente la política "analysis read-only" en `AGENTS.md` o `.cursor/rules/`?
