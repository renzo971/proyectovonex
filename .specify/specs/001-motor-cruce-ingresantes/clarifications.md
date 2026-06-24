# Clarifications Log: Motor de Cruce Automático de Ingresantes UNMSM

**Feature ID:** 001-motor-cruce-ingresantes
**Sessions:** 1
**Status:** In Progress

---

## Summary

**Total Questions:** 2
**Resolved:** 2
**Pending:** 0

**Key Decisions:**
1. El filtro por OBSERVACION (`ALCANZO VACANTE`) se aplica siempre sobre el texto normalizado, enrutando a `ingresantes` o `no_ingresantes` (dual table).
2. De-duplicación automática de filas idénticas dentro del mismo CSV de origen para asegurar la calidad de la data analítica.

---

## Session 1: 2026-06-24

**Participants:** Samuel Cisneros (PO), Equipo V2, Antigravity (Clarification Agent)
**Duration:** 15 min

### Questions Addressed

#### CQ-001: Filtro de OBSERVACION: Normalizado vs Crudo

**Category:** Business Logic
**Route To:** PO
**Status:** Resolved

**Question:**
¿El filtro por `ALCANZO VACANTE` se debe aplicar sobre el valor normalizado (mayúsculas, sin tildes) o sobre el valor crudo original del CSV?

**Context:**
> El filtro de OBSERVACION (AC-004) se aplica después de la normalización del campo, no sobre el valor crudo. (NC-1)

**Options Considered:**
1. **Opción A (Filtrar sobre normalizado):** Robusto contra variaciones de tildes o mayúsculas/minúsculas en el CSV oficial.
2. **Opción B (Filtrar sobre crudo):** Más simple pero propenso a omitir registros si el formato del CSV varía ligeramente.

**Decision:**
El filtro se aplica **siempre sobre el valor normalizado**.

**Rationale:**
Evita errores de filtrado debido a inconsistencias de formato en la base de datos de origen de la UNMSM. Los registros que no cumplen el filtro se enrutan de forma dual a la tabla `no_ingresantes` para no perder trazabilidad.

**Impact on Artifacts:**
- [x] spec.md: US-001, AC-004 y Notas Técnicas.

**Decided By:** Samuel Cisneros, PO
**Date:** 2026-06-24

---

#### CQ-002: Manejo de Registros Duplicados en el CSV

**Category:** Business Logic
**Route To:** PO
**Status:** Resolved

**Question:**
Si el archivo CSV contiene registros idénticos duplicados (mismo postulante con la misma fecha de examen y misma observación), ¿el sistema debe de-duplicar e importar un solo registro en el lote, o debe importar todos manteniendo la duplicidad tal como viene en el CSV original?

**Context:**
> Dado un archivo CSV con múltiples fechas de examen, cuando se sube al sistema, entonces se divide en lotes independientes... y se ignoran silenciosamente las fechas que ya fueron procesadas previamente... (AC-001)

**Options Considered:**
1. **Opción A (De-duplicación automática):** El sistema detecta registros idénticos en el mismo CSV y solo importa uno de ellos para evitar duplicidad de registros en la base de datos analítica.
2. **Opción B (Preservar duplicidad):** El sistema importa cada fila tal cual viene en el archivo para mantener correspondencia exacta 1:1 con el documento oficial, dejando la resolución de anomalías para auditorías externas.

**Decision:**
Se elige la **Opción A (De-duplicación automática)**.

**Rationale:**
Evita la polución de datos duplicados en las tablas analíticas y asegura que las métricas y los conteos finales del lote representen personas únicas.

**Impact on Artifacts:**
- [ ] spec.md: US-001, AC-001 y Notas Técnicas.

**Decided By:** Samuel Cisneros, PO
**Date:** 2026-06-24

---

## Pending Questions

These questions require further investigation or stakeholder input:

No hay preguntas pendientes.

---

## Deferred Questions

No hay preguntas diferidas en esta sesión.

---

## Amendments to Specification

| Date | Artifact | Section | Change | CQ Reference |
|------|----------|---------|--------|--------------|
| 2026-06-24 | spec.md | US-001 | Modificación de AC-004 para reflejar la persistencia dual post-normalización. | CQ-001 |
| 2026-06-24 | spec.md | US-001 | Modificación de AC-001 para especificar la de-duplicación automática de filas idénticas en el lote. | CQ-002 |

---

## Sign-off

- [x] Product Owner: Samuel Cisneros - Business decisions validated
- [ ] Dev Lead: [Name] - Technical feasibility confirmed
- [ ] QA Lead: [Name] - Technical feasibility confirmed
- [ ] FA: [Name] - Requirements complete

**Clarification Phase Status:** Ready for Gate 1 (All business questions resolved)

