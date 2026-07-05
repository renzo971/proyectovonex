# Feature Specification: Motor de Cruce Automático de Ingresantes UNMSM

**Feature ID:** 001-motor-cruce-ingresantes
**Created:** 2026-06-16
**Business Context:** [constitution.md](constitution.md)
**PO:** Samuel Cisneros
**Equipo:** Grupo V2 (Vonex)
**Status:** Under Review
**Versión:** 2.8.0

---

## Executive Summary (≤150 palabras)

El motor de cruce automatiza la validación de identidades de los ingresantes de la UNMSM contra la base de datos de la academia Vonex. El sistema procesa un CSV (~27,000 filas × 12 columnas) subido por el administrador de manera asíncrona. Normaliza los campos y aplica el filtro `ALCANZO VACANTE`: los registros que lo cumplen se retienen como ingresantes válidos; los demás, por trazabilidad. Luego realiza un cruce en dos fases: un match exacto automático (2 apellidos + 1 nombre) y una fase de coincidencia difusa asistida por una interfaz de validación para los cabos sueltos. Finalmente, genera un reporte consolidado en Excel con data enriquecida y un dashboard interactivo de analítica.

---

## User Stories

### US-001: Carga, Normalización y Filtrado de CSV

**As a** Administrador de la academia Vonex
**I want** subir el CSV oficial de ingresantes UNMSM para que el sistema filtre, normalice y agrupe los registros por fecha de examen
**So that** solo los ingresantes con vacante confirmada sean procesados, eliminando errores de carga manual y duplicados

**Priority:** P1 (Must Have)
**Story Points:** 5

#### Acceptance Criteria

- [ ] **AC-001:** Dado un archivo CSV con múltiples fechas de examen, cuando se sube al sistema, entonces se divide en lotes independientes por fecha de examen y se ignoran silenciosamente las fechas que ya fueron procesadas previamente, registrando el salto en el log del lote.
- [ ] **AC-002:** Dado un registro del CSV, cuando se aplica la normalización, entonces el texto se convierte íntegramente a MAYÚSCULAS, se eliminan todas las tildes (á→A, é→E, í→I, ó→O, ú→U) y se reemplaza estrictamente la "Ñ" por "N" sin excepción alguna.
- [ ] **AC-003:** Dado un nombre normalizado, cuando se procesa la cadena de texto, entonces el sistema separa lógicamente el apellido paterno, el apellido materno y los nombres, reconociendo correctamente apellidos compuestos de dos o más palabras (ej. "DE LA CRUZ", "DEL AGUILA").
- [ ] **AC-004:** Dado el archivo CSV, cuando se importa el lote, entonces el sistema normaliza primero el campo `OBSERVACION` (mayúsculas, sin tildes) y luego aplica el filtro: los registros cuyo valor normalizado sea exactamente `ALCANZO VACANTE` se consideran ingresantes válidos; todos los demás registros se retienen para trazabilidad. Ambas entidades quedan vinculadas al mismo lote y se registran los totales de cada grupo en el log.

#### UI/UX Notes

- El componente de carga debe mostrar un indicador de progreso durante el procesamiento.
- Al finalizar, mostrar resumen: total de registros del CSV, registros filtrados por OBSERVACION, registros cargados al lote, fechas ignoradas por duplicado.

#### Functional Notes

- El filtro de OBSERVACION (AC-004) se aplica **después** de la normalización del campo, no sobre el valor crudo. *(NC-1 — Resuelto. Ver Open Questions.)*
- **Persistencia dual (AC-004):** los registros que cumplen el filtro se consideran válidos; los que no lo cumplen se retienen por trazabilidad.
- **Procesamiento asíncrono:** dado que el CSV real alcanza ~27,000 filas × 12 columnas, la importación, normalización y enrutamiento debe procesarse fuera del ciclo HTTP de usuario para evitar cortes por inactividad. El endpoint de carga debe informar de inmediato que la tarea se está procesando.

---

### US-002: Consulta Directa a Base de Datos Academia

**As a** Sistema (motor de cruce)
**I want** consultar directamente la base de datos de origen `academia` para obtener los registros de matrícula de los alumnos
**So that** el cruce se realice siempre contra datos actualizados sin depender de exportaciones o archivos intermedios

**Priority:** P1 (Must Have)
**Story Points:** 3

#### Acceptance Criteria

- [ ] **AC-005:** Dado un lote de ingresantes importados, cuando se inicia el proceso de cruce, entonces el sistema valida la disponibilidad de la base de datos `academia` antes de ejecutar cualquier consulta, abortando limpiamente con alerta si la conexión falla.
- [ ] **AC-006:** Dado que la conexión está disponible, cuando se consultan los alumnos, entonces el sistema extrae registros en todos los estados válidos: MATRICULADO, PAGADO, FINALIZADO, SUSPENDIDO, RETIRADO, TRASLADADO, STAND BY, ANULADO — sin filtrar ningún estado en la extracción inicial.
- [ ] **AC-007:** Dado un alumno con múltiples registros históricos, cuando se determina su estado para el reporte, entonces se resuelve eligiendo el estado de mayor prioridad según la jerarquía inmutable: 1. MATRICULADO → 2. PAGADO → 3. FINALIZADO → 4. SUSPENDIDO → 5. RETIRADO → 6. TRASLADADO → 7. STAND BY → 8. ANULADO.

#### Functional Notes

- La validación de conexión (AC-005) debe ocurrir antes de iniciar cualquier lógica de cruce.
- La jerarquía de estados (AC-007) es inmutable según Art. 4 de la Constitución; cualquier cambio requiere enmienda.
- Las credenciales de conexión nunca deben estar fijadas (hardcoded) en el sistema.

---

### US-003: Motor de Coincidencia en Dos Fases (Match Engine)

**As a** Administrador de la academia Vonex
**I want** que el sistema empareje automáticamente los ingresantes con alumnos de la academia en dos fases (exacta y difusa)
**So that** se minimicen los falsos positivos en el cruce automático y se reduzca la carga operativa de revisión manual

**Priority:** P1 (Must Have)
**Story Points:** 8

#### Acceptance Criteria

- [ ] **AC-008:** Dado un ingresante en el lote, cuando sus 2 apellidos (paterno y materno) y al menos 1 nombre coinciden exactamente con un alumno de la academia tras la normalización, entonces el sistema asocia automáticamente al ingresante con el alumno correspondiente, establece el estado `confirmado_automatico` y continúa sin intervención del usuario.
- [ ] **AC-009:** Dado un ingresante que no obtiene match exacto, cuando el motor calcula la similitud comparando la coincidencia de texto contra los alumnos de la academia, entonces genera una lista ordenada de mayor a menor probabilidad con hasta 5 candidatos potenciales y marca al ingresante como `pendiente`.
- [ ] **AC-010:** Dado un ingresante en estado `pendiente`, cuando ningún alumno supera el umbral de similitud de cálculo del 30%, entonces la lista de candidatos estará vacía y el sistema preparará al ingresante para que se muestre directamente la opción "Sin coincidencias encontradas" en la interfaz.

#### Functional Notes

- El cruce exacto (AC-008) debe ejecutarse de forma prioritaria antes de iniciar el cálculo difuso.
- El umbral del 30% (AC-010) es un supuesto revisable para el cálculo interno — ver **Assumption A-03**.

---

### US-004: Interfaz de Validación Asistida

**As a** Administrador de la academia Vonex
**I want** visualizar los ingresantes en estado `pendiente` y seleccionar manualmente el alumno correcto desde una interfaz interactiva
**So that** los cabos sueltos se resuelvan con criterio humano sin requerir herramientas externas ni hojas de cálculo

**Priority:** P2 (Should Have)
**Story Points:** 5

#### Acceptance Criteria

- [ ] **AC-011:** Dado un ingresante en estado `pendiente`, cuando se visualiza en la interfaz, entonces se muestra una fila con sus datos del CSV y un selector con los candidatos que superen el **umbral de visualización del 70% de similitud**, ordenados de mayor a menor probabilidad. Los candidatos con similitud entre 30% y 69% son calculados pero **no se muestran**.
- [ ] **AC-011b:** Dado que un candidato supera el umbral del 70% de similitud, cuando aparece en el selector de validación, entonces su indicador de porcentaje se colorea según el sistema de rangos inmutable:
  - **95%–100% → Verde intenso**: Match casi exacto; alta confianza.
  - **85%–94% → Verde claro**: Alta confianza; se recomienda seleccionar.
  - **70%–84% → Amarillo/Ámbar**: Confianza media; requiere revisión cuidadosa.
- [ ] **AC-012:** Dado que el administrador selecciona un candidato del menú y presiona "Confirmar Match", cuando el sistema procesa la acción, entonces guarda la asociación, cambia el estado del ingresante a `confirmado_manual` y actualiza los datos analíticos.
- [ ] **AC-013:** Dado que ningún candidato corresponde al ingresante, cuando el administrador selecciona "Sin coincidencias encontradas — Marcar como No Ingresado" y confirma, entonces el estado del ingresante se actualiza a `no_ingresado`.

#### UI/UX Notes

- Mostrar un **indicador de color** con el porcentaje de similitud junto a cada nombre.
- La confirmación (AC-012) debe mostrar feedback visual inmediato (spinner + éxito/error) sin recargar la página.
- La opción "No Ingresado" (AC-013) debe estar visualmente diferenciada (ej. color rojo o ícono) para evitar clics accidentales.
- Si ningún candidato supera el 70% de similitud, mostrar por defecto la opción "Sin coincidencias encontradas" (EC-003).

---

### US-005: Exportación de Reporte Consolidado en Excel

**As a** Usuario de negocio (administración/marketing)
**I want** descargar un archivo Excel con los datos de ingresantes procesados y analítica visual incorporada
**So that** pueda distribuir resultados y analizar métricas por fecha de examen sin herramientas adicionales

**Priority:** P3 (Nice to Have)
**Story Points:** 5

#### Acceptance Criteria

- [ ] **AC-014:** Dado un lote procesado, cuando el usuario descarga el reporte Excel, entonces la **Hoja 1** contiene **exclusivamente** los registros cuyo estado sea `confirmado_automatico` o `confirmado_manual` (los registros `pendiente` o `no_ingresado` **no aparecen**). Se incluyen los datos originales y las columnas enriquecidas (Sede, Ciclo, Año académico, Estado resuelto).
- [ ] **AC-014b:** Dado el reporte Excel (Hoja 1), cuando el administrador lo abre, entonces los registros confirmados manualmente **no muestran columna de porcentaje de similitud**. El reporte consolida únicamente los datos validados, sin metadatos del proceso de cruce.
- [ ] **AC-015:** Dado el archivo Excel descargado, cuando el usuario abre la **Hoja 2**, entonces encuentra gráficos analíticos pre-construidos (distribución por estado, sede, ciclo) basados únicamente en los registros confirmados de la Hoja 1, con segmentadores dinámicos por fecha de examen.

#### Functional Notes

- Los colores por rango de similitud son exclusivos de la interfaz de validación manual (AC-011b) y no deben trasladarse al Excel.

---

## Non-Functional Requirements

### NFR-001: Rendimiento de Carga (Procesamiento Asíncrono)

- **Requirement:** El procesamiento completo de un CSV con hasta ~27,000 filas × 12 columnas debe completarse en menos de **50 segundos** medidos desde la recepción del archivo hasta que el lote queda en estado `completado` (u operativamente procesado).
- **Traces to:** Art. 4 de la Constitución — Pipeline sin intervención manual.
- **Verification:** Test de rendimiento con un CSV sintético de ~27,000 filas midiendo el tiempo de procesamiento en backend.

### NFR-002: Tiempo de Respuesta API (Fuzzy Match)

- **Requirement:** La consulta de candidatos para un ingresante individual en la interfaz interactiva debe responder en menos de 300 ms (percentil 95).
- **Traces to:** Art. 3 de la Constitución — Performance.
- **Verification:** Test de integración midiendo el tiempo de respuesta del endpoint de consulta.

### NFR-003: Volumen de Carga de Archivo

- **Requirement:** El sistema debe soportar la subida de archivos CSV de hasta 20 MB sin arrojar errores de límite de memoria durante la recepción del archivo.
- **Traces to:** Necesidad operativa del equipo de admisiones.
- **Verification:** Carga exitosa de un payload de 20 MB.

### NFR-004: Seguridad de Credenciales

- **Requirement:** Las credenciales de conexión a la base de datos externa no deben almacenarse en el código fuente bajo ninguna circunstancia.
- **Traces to:** Art. 4 de la Constitución — Seguridad.

### NFR-005: Trazabilidad de Lotes

- **Requirement:** Cada lote procesado debe dejar un registro auditable de: fecha de examen, total de registros procesados, válidos, excluidos, exactos, pendientes y no ingresados, además de marcas de tiempo de ejecución.
- **Traces to:** Art. 4 de la Constitución — Auditoría y trazabilidad.

### NFR-006: Aislamiento de Carga (Background Processing)

- **Requirement:** El trabajo intensivo de importación y cálculo inicial debe ejecutarse fuera del ciclo de vida de la petición HTTP principal del usuario, tolerando interrupciones de red o del navegador sin perder los datos procesados.
- **Traces to:** Art. 4 de la Constitución — Gestión de Errores.

### NFR-007: Rendimiento del Reporte de Validación Manual

- **Requirement:** El tiempo total de renderizado de la tabla de validación manual (para un lote masivo con miles de registros en estado pendiente) no debe exceder los **5 minutos**.
- **Traces to:** Art. 4 de la Constitución — SLA de rendimiento de validación.

### NFR-008: Contrato de Sanitización y Seguridad (Input)

- **Requirement:** Todo campo de texto proveniente del CSV se debe evaluar: si comienza con `=`, `+`, `-`, `@`, tabulador o retorno de carro, se debe neutralizar (ej. anteponiendo comilla simple `'`) para prevenir inyección de fórmulas al exportar. La carga se acepta estrictamente validando los *Magic Bytes* (tipo de contenido real), no asumiendo que la extensión de archivo es segura.
- **Traces to:** Art. 3 de la Constitución — Data Protection.
- **Verification:** Pruebas de seguridad inyectando payloads en los campos del CSV.

---

## Edge Cases

| ID | Scenario | Expected Behavior | Story Reference |
|----|----------|-------------------|-----------------:|
| EC-001 | Fila del CSV con campo de nombre o apellido vacío | Registrar el error en el log del lote con identificador; continuar procesando el resto | US-001 |
| EC-002 | CSV sin las columnas obligatorias | Rechazar la carga indicando qué columnas faltan; no generar lote | US-001 |
| EC-003 | Ingresante sin candidatos con similitud ≥ 70% | Mostrar opción "Sin coincidencias encontradas" por defecto | US-003, US-004 |
| EC-004 | Fecha de examen del CSV ya procesada anteriormente | Ignorar silenciosamente registros de esa fecha; registrar salto en log | US-001 |
| EC-005 | Alumno con más de 5 candidatos de igual similitud | Tomar top-5; desempatar alfabéticamente | US-003 |
| EC-006 | CSV con codificación distinta a UTF-8 o ISO-8859-1 | Rechazar carga con mensaje claro de error de codificación | US-001 |
| EC-007 | Caída de conexión a BD `academia` durante cruce | Pausar lote guardando progreso; dejar registros restantes como `pendiente` | US-002 |
| EC-008 | Lote con 0 registros confirmados al intentar exportar | Retornar error de validación (HTTP 422); no generar Excel vacío | US-005 |

---

## Error Scenarios

| ID | Error Condition | User Message | System Behavior | Story Reference |
|----|-----------------|:------------:|-----------------|----------------:|
| ERR-001 | Formato de columnas incorrecto | "El archivo CSV no contiene las columnas requeridas: {lista}. Verifique e intente nuevamente." | Rechazar carga | US-001 |
| ERR-002 | Codificación no soportada | "El archivo no puede leerse. Se acepta UTF-8 o ISO-8859-1." | Rechazar carga | US-001 |
| ERR-003 | Fallo de conexión a DB Origen | "No se pudo establecer conexión con la base de origen. Contacte al administrador." | Abortar creación de lote | US-002 |
| ERR-004 | CSV sin registros 'ALCANZO VACANTE' | "El archivo no contiene registros con observación 'ALCANZO VACANTE'." | Rechazar carga | US-001 |
| ERR-005 | Archivo > 20 MB | "El archivo supera 20 MB. Divídalo y vuelva a intentarlo." | Rechazar HTTP 413 | US-001 |
| ERR-006 | Confirmación con alumno inválido | "El alumno seleccionado no es válido. Recargue e intente nuevamente." | Ignorar acción | US-004 |

---

## Related or Duplicate Work

| Type | Target | Reason |
|------|--------|--------|
| `implementsTogether` | US-001, US-002 | Comparten el mismo contexto de persistencia de datos (ingesta y extracción) |
| `blocks` | US-003 | Depende de la finalización de US-001 y US-002 para iniciar el cruce |
| `blocks` | US-004 | Depende de US-003 para visualizar los cabos sueltos generados |
| `blocks` | US-005 | Depende de US-003 y US-004 para poder exportar los estados resueltos finales |

---

## Glossary

| Term | Definition | Context |
|------|------------|---------:|
| Ingresante | Estudiante que alcanzó una vacante en el examen | Negocio |
| Lote | Conjunto de registros del CSV agrupados por `FECHA_EXAMEN` | Negocio |
| Match exacto | Coincidencia de 2 apellidos + al menos 1 nombre | Negocio |
| Cabo suelto | Ingresante sin match exacto pero con similitud | Negocio |
| `confirmado_automatico` | Match exacto (sin intervención humana) | Sistema |
| `confirmado_manual` | Validación interactiva por administrador | Sistema |
| `pendiente` | Estado de revisión manual pendiente | Sistema |
| `no_ingresado` | Descarte manual (sin candidato válido) | Sistema |
| Jerarquía de estados | Orden de prioridad inmutable (MATRICULADO, PAGADO, etc.) | Negocio |
| Normalización | Conversión a MAYÚSCULAS, sin tildes, Ñ→N | Negocio |

---

## Assumptions

| ID | Assumption | If False, Then… |
|----|------------|-----------------|
| A-01 | Codificación de CSV es siempre UTF-8 o ISO-8859-1 | Fallará la carga con ERR-002 |
| A-02 | BD Origen posee índices de búsqueda adecuados | El rendimiento (NFR-002) decaerá severamente |
| A-03 | Umbral interno de similitud es 30%; visual en UI es 70% | Cambia dramáticamente la carga operativa visual del administrador |
| A-04 | 5 candidatos son suficientes para emparejar | El candidato correcto podría quedar fuera de lista obligando búsqueda manual |
| A-05 | La exportación Excel es un producto final de distribución | Si se requiere como auditoría, se deberá crear otra US para incluir "pendientes" |

---

## Open Questions

1. [x] ✅ **[NC-1 — RESUELTO]:** ¿El filtro por `ALCANZO VACANTE` se aplica sobre el valor normalizado (mayúsculas, sin tildes) o sobre el valor crudo del CSV?
   - **Decisión confirmada por PO:** El filtro se aplica **siempre sobre el valor normalizado**.

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-06-01 | Samuel Cisneros | Especificación funcional inicial |
| 2.8.0 | 2026-07-03 | Antigravity | Refactorización de requerimientos (eliminación de clases técnicas/arquitectura, enfoque 100% en negocio y comportamiento según Requirement Analyst Agent) |
