# Casos de Prueba: Motor de Cruce Automático de Ingresantes UNMSM

**Feature ID:** 001-motor-cruce-ingresantes
**Creado:** 2026-07-04
**Autor:** Diego Castillo
**Estado:** Under Review

> Glosario:
> - **US:** Historia de Usuario
> - **AC:** Criterio de Aceptación
> - **NFR:** Requisito No Funcional
> - **EC:** Caso de Borde
> - **ERR:** Escenario de Error
> - **E2E:** Prueba de extremo a extremo

---

## 1. Estrategia de pruebas

### 1.1 Alcance

| Tipo | Alcance | Cobertura esperada |
|------|---------|--------------------|
| Unidad | Normalización de texto, parsing de nombres, jerarquía de estados, filtrado de observaciones, ordenamiento de candidatos, escape de fórmulas | Validar reglas de negocio críticas aisladas |
| Integración | Upload CSV, job Redis, persistencia en lotes/ingresantes/no_ingresantes, cruce exacto y difuso, exportación Excel, catálogo | Cubrir los flujos principales del sistema |
| E2E | Carga de CSV, revisión de pendientes, confirmación manual, exportación | Validar uso real del usuario administrador |
| Rendimiento | Proceso batch de 27k filas, endpoint de candidatos, exportación de volumen | Verificar NFR-001 a NFR-003 |
| Seguridad | Sanitización de CSV, protección ante fórmulas y SQL injection, manejo de credenciales | Verificar NFR-004 y NFR-007 |

### 1.2 Entorno

| Entorno | Propósito | Datos |
|---------|-----------|-------|
| Local | Desarrollo y pruebas unitarias | Fixtures y factories |
| CI | Validación continua | Base de datos temporal + Redis controlado |
| Staging | Integración realista | Datos anónimos representativos |

### 1.3 Datos de prueba

- Fixtures de CSV con nombres acentuados, apellidos compuestos, observaciones variadas y duplicados.
- Factories para `LoteCruce`, `Ingresante`, `NoIngresante`, `IngresanteCandidato` y modelos de la base `academia` si se usa migración de prueba.
- Mocks o stubs solo para servicios externos no esenciales; los flujos relevantes deben ejecutarse contra base de datos real o aislada.

---

## 2. Casos de prueba

### 2.1 US-001 - Carga, normalización y filtrado de CSV

#### TC-001: Procesar un CSV nuevo con códigos duplicados y fechas previas

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | US-001, AC-001 |

**Dado** un CSV con dos fechas de examen y registros duplicados por `CODIGO`
**Cuando** se sube al sistema y el job procesa el lote
**Entonces** solo se insertan los `CODIGO` nuevos y el lote resultante contiene únicamente el delta de postulantes no previamente persistidos.

**Validaciones adicionales:**
- Los registros de fechas ya procesadas se ignoran silenciosamente.
- Los códigos ya presentes en `ingresantes` o `no_ingresantes` no se vuelven a insertar.

---

#### TC-002: Normalizar texto completo a mayúsculas, sin tildes y con Ñ convertida a N

| Atributo | Valor |
|----------|-------|
| Tipo | Unidad |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | US-001, AC-002 |

**Dado** un texto con acentos, `Ñ` y mezclas de mayúsculas/minúsculas
**Cuando** se ejecuta `NormalizarTextoAction`
**Entonces** el valor queda en mayúsculas, sin tildes y con `Ñ` reemplazada por `N`.

**Ejemplo:** `María Ñañez De La Cruz` → `MARIA NANEZ DE LA CRUZ`.

---

#### TC-003: Separar nombres y apellidos cuando hay apellidos compuestos

| Atributo | Valor |
|----------|-------|
| Tipo | Unidad |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | US-001, AC-003 |

**Dado** un nombre normalizado como `DE LA CRUZ GARCIA JUAN CARLOS`
**Cuando** se procesa el texto para separar nombres y apellidos
**Entonces** el parser devuelve correctamente apellido paterno, apellido materno y nombres.

---

#### TC-004: Filtrar `OBSERVACION` y enrutar a las tablas correctas

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | US-001, AC-004 |

**Dado** un CSV con registros cuyo valor normalizado de `OBSERVACION` es `ALCANZO VACANTE` y otros no lo es
**Cuando** el job procesa el lote
**Entonces** los que cumplen el filtro se insertan en `ingresantes`, los demás en `no_ingresantes`, ambos comparten el mismo `lote_cruce_id` y se registran los totales en el log del lote.

---

#### TC-005: Sanitizar caracteres especiales y prefijos de inyección antes de persistir

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | US-001, AC-004b, NFR-007 |

**Dado** un registro con prefijos o caracteres especiales como `=`, `+`, `-`, `@`
**Cuando** se procesa y se persiste en la base de datos
**Entonces** el valor se sanitiza y se guarda de forma segura mediante el ORM, sin permitir ejecución maliciosa ni corrupción del contenido.

---

#### TC-006: Mostrar resumen de progreso y métricas del lote al finalizar

| Atributo | Valor |
|----------|-------|
| Tipo | E2E |
| Prioridad | P2 |
| Automatizado | Sí / Planificado |
| Trazas a | US-001, UI/UX Notes |

**Dado** un CSV cargado correctamente
**Cuando** finaliza el procesamiento
**Entonces** la interfaz muestra un resumen con total de registros, registros filtrados, registros cargados y fechas ignoradas por duplicado.

---

### 2.2 US-002 - Consulta directa a la base de datos academia

#### TC-007: Validar conexión a academia antes de ejecutar el cruce

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | US-002, AC-005 |

**Dado** que la conexión a la base de datos academia no está disponible
**Cuando** se inicia el proceso de cruce
**Entonces** el sistema aborta de forma controlada y no ejecuta consultas posteriores.

---

#### TC-008: Consultar alumnos en todos los estados válidos y resolver jerarquía correcta

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | US-002, AC-006, AC-007 |

**Dado** múltiples registros históricos de un alumno en la base de datos academia con distintos estados
**Cuando** se resuelve el estado para el reporte
**Entonces** el sistema toma el estado de mayor prioridad según la jerarquía: `MATRICULADO > PAGADO > FINALIZADO > SUSPENDIDO > RETIRADO > TRASLADADO > STAND BY > ANULADO`.

---

#### TC-009: Exponer estado del lote vía API

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | US-002, NFR-005 |

**Dado** un lote en proceso o completado
**Cuando** se invoca `GET /api/cruce/lotes/{lote_id}/status`
**Entonces** la respuesta incluye `lote_id`, estado, totales y timestamps relevantes.

---

### 2.3 US-003 - Motor de coincidencia en dos fases

#### TC-010: Asignar match exacto cuando apellidos y un nombre coinciden

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | US-003, AC-008 |

**Dado** un ingresante con apellidos y al menos un nombre coincidiendo exactamente con un alumno de academia tras la normalización
**Cuando** se ejecuta la fase exacta de cruce
**Entonces** el sistema asigna el `alumno_id`, marca el estado como `confirmado_automatico` y continúa sin intervención humana.

---

#### TC-011: Generar candidatos difusos con hasta 5 opciones ordenadas

| Atributo | Valor |
|----------|-------|
| Tipo | Unidad |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | US-003, AC-009 |

**Dado** un ingresante sin match exacto
**Cuando** se calcula la similitud difusa
**Entonces** el motor devuelve hasta 5 candidatos ordenados de mayor a menor probabilidad.

**Validaciones adicionales:**
- Se incluyen score o porcentaje de similitud.
- El cálculo se produce dentro del job batch y no en el request HTTP.

---

#### TC-012: Dejar lista vacía y exponer opción de no ingresado cuando no hay candidato válido

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | US-003, AC-010 |

**Dado** un ingresante cuyo mejor candidato no supera el umbral del 30%
**Cuando** finaliza la fase difusa
**Entonces** la lista de candidatos queda vacía y la interfaz expone la opción `Sin coincidencias encontradas — Marcar como No Ingresado`.

---

### 2.4 US-004 - Interfaz de validación asistida

#### TC-013: Mostrar fila pendiente con placeholder y candidatos ordenados

| Atributo | Valor |
|----------|-------|
| Tipo | E2E |
| Prioridad | P1 |
| Automatizado | Sí / Planificado |
| Trazas a | US-004, AC-011 |

**Dado** un ingresante en estado `pendiente`
**Cuando** se visualiza en la interfaz React
**Entonces** aparece una fila con sus datos del CSV, un `<select>` con placeholder inicial no seleccionable y los candidatos ordenados por similitud con porcentaje visible.

---

#### TC-014: Confirmar match manual y actualizar estado y datos enriquecidos

| Atributo | Valor |
|----------|-------|
| Tipo | E2E |
| Prioridad | P1 |
| Automatizado | Sí / Planificado |
| Trazas a | US-004, AC-012 |

**Dado** un ingresante pendiente con candidatos disponibles
**Cuando** el administrador selecciona un candidato y confirma el match
**Entonces** se invoca `GuardarCruceConfirmadoAction`, el estado cambia a `confirmado_manual` y se actualizan los datos enriquecidos.

**Validación UX:**
- Debe mostrarse feedback visual inmediato (spinner + mensaje de éxito/error) sin recargar la página.

---

#### TC-015: Marcar como no ingresado desde la opción visualmente diferenciada

| Atributo | Valor |
|----------|-------|
| Tipo | E2E |
| Prioridad | P2 |
| Automatizado | Sí / Planificado |
| Trazas a | US-004, AC-013 |

**Dado** un ingresante pendiente sin candidato válido
**Cuando** el administrador selecciona la opción de no ingresado y confirma
**Entonces** el estado del ingresante cambia a `no_ingresado` y la interfaz refleja la decisión.

---

### 2.5 US-005 - Exportación de reporte consolidado en Excel

#### TC-016: Requerir selector de fecha o consolidado y bloquear otros formatos

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P2 |
| Automatizado | Sí |
| Trazas a | US-005, AC-014 |

**Dado** un conjunto de lotes procesados
**Cuando** el usuario solicita la exportación
**Entonces** el sistema obliga a elegir entre una `FECHA_EXAMEN` específica o `Todas las fechas`, y genera solo un archivo `.xlsx`.

---

#### TC-017: Generar Excel con contrato de columnas y datos enriquecidos

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | US-005, AC-015 |

**Dado** un lote con registros confirmados automáticos o manuales
**Cuando** se genera el reporte Excel
**Entonces** el archivo contiene el contrato de columnas definido: columnas A-M del CSV original y columnas N+ con datos enriquecidos de academia y catálogo; los campos sin match muestran `SIN MAPEAR` y solo se incluyen registros con estado `confirmado_automatico` o `confirmado_manual`.

---

### 2.6 US-006 - Gestión del catálogo de áreas y carreras

#### TC-018: Cargar catálogo con validación de Magic Bytes y sanitización

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P2 |
| Automatizado | Sí |
| Trazas a | US-006, AC-017 |

**Dado** un archivo CSV del catálogo oficial
**Cuando** se sube al módulo independiente
**Entonces** el sistema valida los Magic Bytes, sanitiza campos para evitar inyección de fórmulas y realiza un upsert en `catalogo_areas_carreras`.

---

#### TC-019: Restringir el uso del catálogo al reporte final y no al pipeline de cruce

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P2 |
| Automatizado | Sí |
| Trazas a | US-006, AC-018 |

**Dado** el pipeline de carga y cruce
**Cuando** se evalúan los ingresantes o se calcula el fuzzy match
**Entonces** el catálogo no se consulta ni se usa en ninguna etapa intermedia.

---

## 3. Casos de borde

### EC-001: Fila con nombre o apellido vacío

#### TC-020: Registrar error por fila incompleta y continuar con las demás

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P2 |
| Automatizado | Sí |
| Trazas a | EC-001 |

**Dado** una fila CSV con campos de nombre vacíos
**Cuando** se procesa el lote
**Entonces** se registra un error en el log del lote con número de fila y el proceso continúa con las filas restantes.

---

### EC-002: CSV sin columnas requeridas

#### TC-021: Rechazar carga con mensaje de columnas faltantes

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | EC-002, ERR-001 |

**Dado** un CSV sin columnas obligatorias como `NOMBRES`, `OBSERVACION` o `FECHA`
**Cuando** se intenta sube el archivo
**Entonces** la carga se rechaza con un error descriptivo y no se insertan registros.

---

### EC-003: Fuzzy match sin candidatos válidos

#### TC-022: Mostrar opción de no ingresado sin bloquear el flujo

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P2 |
| Automatizado | Sí |
| Trazas a | EC-003 |

**Dado** un ingresante con similitud máxima menor al umbral del 30%
**Cuando** se genera la lista de candidatos
**Entonces** la lista queda vacía y la interfaz permite marcarlo como no ingresado.

---

### EC-004: Fecha de examen ya procesada

#### TC-023: Ignorar silenciosamente los registros ya incluidos

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | EC-004 |

**Dado** un CSV con una fecha de examen previamente procesada
**Cuando** se vuelve a subir el archivo
**Entonces** los registros de esa fecha se ignoran y el log registra la fecha omitida.

---

### EC-005: Más de 5 candidatos con igual similitud

#### TC-024: Limitar a 5 candidatos y desempatar por apellido paterno

| Atributo | Valor |
|----------|-------|
| Tipo | Unidad |
| Prioridad | P2 |
| Automatizado | Sí |
| Trazas a | EC-005 |

**Dado** más de 5 alumnos con igual similitud
**Cuando** se ordenan los candidatos
**Entonces** solo se muestran los 5 primeros y los empates se resuelven por apellido paterno.

---

### EC-006: CSV con codificación distinta de UTF-8/ISO-8859-1

#### TC-025: Rechazar carga por codificación no soportada

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | EC-006, ERR-002 |

**Dado** un CSV codificado como UTF-16
**Cuando** se sube al sistema
**Entonces** se rechaza con un mensaje de codificación y no se insertan registros.

---

### EC-007: Error de conexión a academia durante el cruce

#### TC-026: Pausar el lote y conservar estado recuperable

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | EC-007, NFR-006 |

**Dado** una falla temporal de conexión a la base de datos academia
**Cuando** el job intenta ejecutar el cruce
**Entonces** el lote queda en un estado recuperable y los registros ya procesados no se pierden.

---

### EC-008: Worker Redis caído o reiniciado

#### TC-027: Mantener consistencia del lote tras fallo del worker

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | EC-008, NFR-006 |

**Dado** un worker Redis reiniciado durante la ejecución del job
**Cuando** el proceso falla
**Entonces** el job queda registrado en `failed_jobs` y el lote conserva el estado ya persistido sin duplicaciones.

---

## 4. Escenarios de error

### ERR-001: Formato de columnas incorrecto

#### TC-028: Rechazar carga cuando los nombres de las columnas son incorrectos

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | ERR-001 |

**Dado** un CSV con columnas presentes pero con nombres incorrectos
**Cuando** se intenta subir
**Entonces** la API responde con HTTP 422 y mensaje claro sobre las columnas inválidas.

---

### ERR-002: Archivo mayor a 20 MB

#### TC-029: Rechazar archivo demasiado grande antes de procesar

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | ERR-005 |

**Dado** un archivo CSV de 21 MB
**Cuando** se envía al endpoint de carga
**Entonces** el sistema responde con HTTP 413 y no crea un lote.

---

### ERR-003: CSV vacío tras el filtro de observación

#### TC-030: Rechazar carga cuando no hay registros válidos

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | ERR-004 |

**Dado** un CSV donde ninguna fila tiene `OBSERVACION=ALCANZO VACANTE`
**Cuando** se intenta procesar
**Entonces** la carga se rechaza con HTTP 422 y mensaje de que no hay registros válidos.

---

### ERR-004: Confirmación de match con alumno_id inválido

#### TC-031: Rechazar la confirmación y no alterar el estado

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | ERR-006 |

**Dado** un ingreso con un `alumno_id` inexistente en la petición de confirmación
**Cuando** se invoca `POST /api/cruce/ingresantes/{id}/confirmar`
**Entonces** el sistema responde con HTTP 404 y no modifica el estado del ingresante.

---

### ERR-005: Job fallido y movido a failed_jobs

#### TC-032: Registrar el fallo y mantener consistencia del lote

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | ERR-007, NFR-006 |

**Dado** una excepción inesperada durante `ProcessCsvBatchJob`
**Cuando** el worker procesa el job
**Entonces** el job aparece en `failed_jobs`, el lote queda en estado de error o pausa según la naturaleza del fallo y no se pierden registros ya insertados.

---

## 5. Pruebas no funcionales

### NFR-001: Rendimiento de carga asíncrona

#### TC-033: Procesar 27,000 filas en menos de 50 segundos

| Atributo | Valor |
|----------|-------|
| Tipo | Rendimiento |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | NFR-001 |

**Escenario:** despachar un job con un CSV sintético de 27,000 filas.
**Objetivo:** el lote pasa a `completed` en menos de 50 segundos.

---

### NFR-002: Tiempo de respuesta del fuzzy match

#### TC-034: Responder el endpoint de candidatos en menos de 300 ms p95

| Atributo | Valor |
|----------|-------|
| Tipo | Rendimiento |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | NFR-002 |

**Escenario:** consultar el endpoint de candidatos con carga representativa.
**Objetivo:** p95 menor a 300 ms.

---

### NFR-003: Soporte de archivos hasta 20 MB

#### TC-035: Aceptar un CSV de 20 MB sin error de memoria en el upload inicial

| Atributo | Valor |
|----------|-------|
| Tipo | Rendimiento |
| Prioridad | P2 |
| Automatizado | Sí |
| Trazas a | NFR-003 |

**Escenario:** subir un archivo de 20 MB mediante la ruta inicial.
**Objetivo:** respuesta HTTP exitosa y job encolado sin error de memoria.

---

### NFR-004: Seguridad de credenciales

#### TC-036: Garantizar que las credenciales de academia no se almacenen en el repositorio

| Atributo | Valor |
|----------|-------|
| Tipo | Seguridad |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | NFR-004 |

**Escenario:** revisar el repositorio y la configuración de ejecución.
**Objetivo:** no debe existir ninguna credencial real en el código; solo variables de entorno.

---

### NFR-005: Trazabilidad de lotes

#### TC-037: Verificar metadatos completos del lote procesado

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | NFR-005 |

**Dado** un lote procesado
**Cuando** se consulta la tabla de lotes
**Entonces** deben existir fecha de examen, totales, match exacto, pendientes, no ingresados y timestamps de inicio y fin.

---

### NFR-006: Procesamiento asíncrono con Redis

#### TC-038: Encolar el job y soportar reinicios del worker

| Atributo | Valor |
|----------|-------|
| Tipo | Integración |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | NFR-006 |

**Escenario:** despachar `ProcessCsvBatchJob` y reiniciar el worker durante la ejecución.
**Objetivo:** el job queda registrado en la cola fallida o se recupera sin pérdida de datos ya insertados.

---

### NFR-007: Integridad y sanitización de datos

#### TC-039: Neutralizar prefijos de fórmulas y caracteres peligrosos

| Atributo | Valor |
|----------|-------|
| Tipo | Seguridad |
| Prioridad | P1 |
| Automatizado | Sí |
| Trazas a | NFR-007 |

**Dado** un valor de texto que empieza con `=`, `+`, `-` o `@`
**Cuando** se ingresa al flujo de carga o exportación
**Entonces** el sistema lo neutraliza y lo persiste como dato seguro.

---

## 6. Matriz de trazabilidad

| Requisito | Casos de prueba |
|-----------|-----------------|
| US-001 / AC-001 | TC-001 |
| US-001 / AC-002 | TC-002 |
| US-001 / AC-003 | TC-003 |
| US-001 / AC-004 | TC-004 |
| US-001 / AC-004b | TC-005 |
| US-002 / AC-005 | TC-007 |
| US-002 / AC-006, AC-007 | TC-008 |
| US-003 / AC-008 | TC-010 |
| US-003 / AC-009 | TC-011 |
| US-003 / AC-010 | TC-012 |
| US-004 / AC-011 | TC-013 |
| US-004 / AC-012 | TC-014 |
| US-004 / AC-013 | TC-015 |
| US-005 / AC-014 | TC-016 |
| US-005 / AC-015 | TC-017 |
| US-006 / AC-017 | TC-018 |
| US-006 / AC-018 | TC-019 |
| NFR-001 | TC-033 |
| NFR-002 | TC-034 |
| NFR-003 | TC-035 |
| NFR-004 | TC-036 |
| NFR-005 | TC-037 |
| NFR-006 | TC-038 |
| NFR-007 | TC-039 |

---

## 7. Plan de ejecución

| Etapa | Cobertura |
|-------|-----------|
| Pre-commit | Pruebas unitarias de normalización y lógica de match |
| PR | Integración de carga, cruce y exportación |
| Merge | Suite completa de integración y seguridad |
| Nocturna | E2E y pruebas de rendimiento |

---

## 8. Criterios de salida

La funcionalidad se considera lista para revisar cuando:
- Todos los TC P1 están verdes.
- Los NFR-001 a NFR-007 cuentan con evidencia ejecutable.
- No quedan escenarios críticos sin cobertura.