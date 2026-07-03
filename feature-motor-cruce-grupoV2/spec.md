# Feature Specification: Motor de Cruce Automático de Ingresantes UNMSM

**Feature ID:** 001-motor-cruce-ingresantes
**Created:** 2026-06-16
**Business Context:** [constitution.md](constitution.md)
**PO:** Samuel Cisneros
**Equipo:** Grupo V2 (Vonex)
**Status:** Under Review
**Versión:** 2.7.0

---

## Executive Summary (≤150 palabras)

El motor de cruce automatiza la validación de identidades de los ingresantes de la UNMSM contra la base de datos de la academia Vonex (PostgreSQL). El sistema procesa un CSV (~27,000 filas × 12 columnas) subido por el administrador mediante un job asíncrono en cola Redis. Normaliza los campos y aplica el filtro `ALCANZO VACANTE`: los registros que lo cumplen se persisten en la tabla `ingresantes`; los demás, en `no_ingresantes`. Luego realiza un cruce en dos fases: un match exacto automático (2 apellidos + 1 nombre) y una fase de coincidencia difusa asistida por interfaz React para los cabos sueltos. Finalmente, genera un reporte consolidado en Excel con data enriquecida y un dashboard interactivo de analítica.

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
- [ ] **AC-004:** Dado el archivo CSV, cuando se importa el lote, entonces el sistema normaliza primero el campo `OBSERVACION` (mayúsculas, sin tildes) y luego aplica el filtro: los registros cuyo valor normalizado sea exactamente `ALCANZO VACANTE` se persisten en la tabla `ingresantes`; todos los demás registros se persisten en la tabla `no_ingresantes` para trazabilidad. Ambas inserciones quedan vinculadas al mismo `lote_cruce_id` y se registran los totales de cada grupo en el log del lote.

#### UI/UX Notes

- El componente de carga (`FileUpload`) debe mostrar un indicador de progreso durante el procesamiento.
- Al finalizar, mostrar resumen: total de registros del CSV, registros filtrados por OBSERVACION, registros cargados al lote, fechas ignoradas por duplicado.

#### Technical Notes

- La normalización (AC-002) es responsabilidad de `NormalizarTextoAction.php`.
- El filtrado de duplicados por fecha (AC-001) compara contra la tabla `lotes_cruce` antes de insertar.
- El filtro de OBSERVACION (AC-004) se aplica **después** de la normalización del campo, no sobre el valor crudo. *(NC-1 — Resuelto. Ver Open Questions.)*
- **Persistencia dual (AC-004):** los registros que cumplen el filtro van a la tabla `ingresantes`; los que no lo cumplen van a la tabla `no_ingresantes`. Ambas tablas llevan el mismo `lote_cruce_id` como clave de trazabilidad.
- **Redis + Colas (Laravel Queue):** dado que el CSV real alcanza ~27,000 filas × 12 columnas, la importación, normalización y enrutamiento a `ingresantes`/`no_ingresantes` se despachan como un job en cola (`ProcessCsvBatchJob`) a través de Redis. El endpoint de carga responde inmediatamente con el `lote_id` y el estado `procesando`; el frontend consulta el progreso vía polling o WebSocket. Esto evita timeouts HTTP y permite procesar el volumen real dentro del SLA de NFR-001.

---

### US-002: Consulta Directa a Base de Datos Academia

**As a** Sistema (motor de cruce)
**I want** consultar directamente la base de datos `academia` en PostgreSQL para obtener los registros de matrícula de los alumnos
**So that** el cruce se realice siempre contra datos actualizados sin depender de exportaciones o archivos intermedios

**Priority:** P1 (Must Have)
**Story Points:** 3

#### Acceptance Criteria

- [ ] **AC-005:** Dado un lote de ingresantes importados, cuando se inicia el proceso de cruce, entonces el sistema valida la conexión con la base de datos `academia` en PostgreSQL antes de ejecutar cualquier consulta, abortando limpiamente con alerta si la conexión falla.
- [ ] **AC-006:** Dado que la conexión está disponible, cuando se consultan los alumnos, entonces el sistema trae registros en todos los estados válidos: MATRICULADO, PAGADO, FINALIZADO, SUSPENDIDO, RETIRADO, TRASLADADO, STAND BY, ANULADO — sin filtrar ningún estado en la consulta de extracción.
- [ ] **AC-007:** Dado un alumno con múltiples registros históricos en la base de datos `academia`, cuando se determina su estado para el reporte, entonces se resuelve eligiendo el estado de mayor prioridad según la jerarquía inmutable: 1. MATRICULADO → 2. PAGADO → 3. FINALIZADO → 4. SUSPENDIDO → 5. RETIRADO → 6. TRASLADADO → 7. STAND BY → 8. ANULADO.

#### Technical Notes

- La validación de conexión (AC-005) se ejecuta al inicio de `RealizarCruceExactoAction.php`.
- La jerarquía de estados (AC-007) es inmutable según Art. 3 de la Constitución; cualquier cambio requiere enmienda constitucional documentada.
- Las credenciales de conexión se gestionan exclusivamente mediante variables de entorno (`.env`) — Art. 4 de la Constitución.

---

### US-003: Motor de Coincidencia en Dos Fases (Match Engine)

**As a** Administrador de la academia Vonex
**I want** que el sistema empareje automáticamente los ingresantes con alumnos de la academia en dos fases (exacta y difusa)
**So that** se minimicen los falsos positivos en el cruce automático y se reduzca la carga operativa de revisión manual

**Priority:** P1 (Must Have)
**Story Points:** 8

#### Acceptance Criteria

- [ ] **AC-008:** Dado un ingresante en el lote, cuando sus 2 apellidos (paterno y materno) y al menos 1 nombre coinciden exactamente con un alumno de la academia tras la normalización, entonces el sistema asocia automáticamente al ingresante con el `alumno_id` correspondiente, establece el estado `confirmado_automatico` y continúa sin intervención del usuario.
- [ ] **AC-009:** Dado un ingresante que no obtiene match exacto, cuando el motor calcula la similitud comparando la frecuencia de letras y la distancia de Levenshtein contra los alumnos de la academia, entonces genera una lista ordenada de mayor a menor probabilidad con hasta 5 candidatos potenciales y marca al ingresante como `pendiente`.
- [ ] **AC-010:** Dado un ingresante en estado `pendiente`, cuando ningún alumno supera el umbral de similitud del 30%, entonces la lista de candidatos estará vacía y el sistema expondrá la opción "Sin coincidencias encontradas — Marcar como No Ingresado" en la interfaz.

#### Technical Notes

- El cruce exacto (AC-008) es responsabilidad de `RealizarCruceExactoAction.php`.
- El cálculo de similitud (AC-009) es responsabilidad de `CalcularSimilitudesCabosAction.php`.
- El umbral del 30% (AC-010) es un supuesto revisable — ver **Assumption A-03**.

---

### US-004: Interfaz de Validación Asistida (React)

**As a** Administrador de la academia Vonex
**I want** visualizar los ingresantes en estado `pendiente` y seleccionar manualmente el alumno correcto desde una interfaz interactiva
**So that** los cabos sueltos se resuelvan con criterio humano sin requerir herramientas externas ni hojas de cálculo

**Priority:** P2 (Should Have)
**Story Points:** 5

#### Acceptance Criteria

- [ ] **AC-011:** Dado un ingresante en estado `pendiente`, cuando se visualiza en la interfaz React, entonces se muestra una fila con sus datos del CSV (apellido paterno, materno, nombres, fecha de examen) y u

70n selector `<select>` con los candidatos que superen el **umbral de visualización del 70% de similitud**, ordenados de mayor a menor probabilidad, mostrando para cada uno el nombre completo y el porcentaje de similitud. Los candidatos con similitud entre 30% y 69% son calculados por el motor pero **no se muestran** en la interfaz.
- [ ] **AC-011b:** Dado que un candidato supera el umbral del 70% de similitud, cuando aparece en el selector de validación, entonces su badge de porcentaje se colorea según el siguiente sistema de rangos de colores inmutable:
  - **95%–100% → Verde intenso** (`#16a34a`): Match casi exacto; alta confianza de correspondencia.
  - **85%–94% → Verde claro** (`#4ade80`): Alta confianza; se recomienda seleccionar.
  - **70%–84% → Amarillo/Ámbar** (`#eab308`): Confianza media; requiere revisión cuidadosa del administrador.
- [ ] **AC-012:** Dado que el administrador selecciona un candidato del menú y presiona "Confirmar Match", cuando el sistema procesa la acción, entonces guarda la asociación invocando `GuardarCruceConfirmadoAction`, cambia el estado del ingresante a `confirmado_manual` y actualiza los datos enriquecidos en la base de datos analítica.
- [ ] **AC-013:** Dado que ningún candidato corresponde al ingresante, cuando el administrador selecciona "Sin coincidencias encontradas — Marcar como No Ingresado" y confirma, entonces el estado del ingresante se actualiza a `no_ingresado` en la base de datos analítica.

#### UI/UX Notes

- El selector (AC-011) debe incluir como primera opción un placeholder no seleccionable: "Selecciona un alumno...".
- Mostrar un **badge de color** con el porcentaje de similitud junto al nombre de cada candidato según los rangos definidos en AC-011b. No mostrar candidatos con similitud < 70%.
- La confirmación (AC-012) debe mostrar feedback visual inmediato (spinner + mensaje de éxito/error) sin recargar la página.
- La opción "No Ingresado" (AC-013) debe estar visualmente diferenciada (color rojo o icono de advertencia) para evitar clics accidentales.
- Si ningún candidato supera el 70% de similitud, mostrar directamente la opción "Sin coincidencias encontradas — Marcar como No Ingresado" como única opción disponible (comportamiento equivalente a EC-003).

#### Technical Notes

- La API REST expone los cabos sueltos del lote vía `GET /api/cruce/{lote}/pendientes`.
- La confirmación se envía vía `POST /api/cruce/{ingresante}/confirmar`.
- El componente principal es `UnmatchedRow.jsx`; el orquestador de la vista es `App.jsx`.

---

### US-005: Exportación de Reporte Consolidado en Excel

**As a** Usuario de negocio (administración/marketing)
**I want** descargar un archivo Excel con los datos de ingresantes procesados y analítica visual incorporada
**So that** pueda distribuir resultados y analizar métricas por fecha de examen sin herramientas adicionales

**Priority:** P3 (Nice to Have)
**Story Points:** 5

#### Acceptance Criteria

- [ ] **AC-014:** Dado un lote procesado, cuando el usuario descarga el reporte Excel, entonces la **Hoja 1** contiene **exclusivamente** los registros cuyo `estado_match` sea `confirmado_automatico` o `confirmado_manual` — los registros con estado `pendiente` o `no_ingresado` **no aparecen en el Excel**. Las columnas A–M corresponden a los datos del CSV crudo original del ingresante y a partir de la columna N se incluyen los campos enriquecidos del alumno de la academia: Sede, Ciclo, Año académico y Estado resuelto por jerarquía.
- [ ] **AC-014b:** Dado el reporte Excel (Hoja 1), cuando el administrador lo abre, entonces los registros `confirmado_automatico` (match exacto, similitud implícita del 100%) aparecen sin distinción visual adicional de color de similitud; los registros `confirmado_manual` **no muestran columna de porcentaje de similitud** en el Excel — el reporte consolida únicamente los datos validados finales, sin metadatos del proceso de cruce difuso.
- [ ] **AC-015:** Dado el archivo Excel descargado, cuando el usuario abre la **Hoja 2**, entonces encuentra gráficos analíticos pre-construidos (distribución por estado, por sede, por ciclo) basados únicamente en los registros confirmados de la Hoja 1, y segmentadores dinámicos que filtran todas las métricas por fecha de examen.

#### Technical Notes

- La exportación es responsabilidad de `ExportarExcelCruceAction.php`.
- Utilizar una librería PHP compatible con Excel (ej. PhpSpreadsheet) para generar ambas hojas y los gráficos dinámicos.
- El filtro de registros para el Excel se aplica con `WHERE estado_match IN ('confirmado_automatico', 'confirmado_manual')`; los estados `pendiente` y `no_ingresado` quedan fuera del reporte final pero permanecen en la BD para auditoría (NFR-005).
- Los colores por rango de similitud son exclusivos de la **interfaz React** (AC-011b); el Excel no replica este sistema de colores.

---

## Arquitectura y Contexto Técnico

### Racional de la Arquitectura de Seguridad (Security Design Decisions)

**Contexto Operativo:**
El sistema de cruce de ingresantes se desplegará en un entorno **100% local (Intranet)**. No tendrá exposición pública a Internet, por lo que los vectores de ataque perimetrales (fuerza bruta desde el exterior, DDoS) son de riesgo muy bajo. La principal amenaza es interna (errores de manipulación de datos, saturación de recursos por cargas masivas, o vulnerabilidades a nivel de aplicación como CSV Injection).

**Decisión Arquitectónica:**
Se adopta un enfoque centrado en la **Seguridad de la Aplicación (Zero-Trust a nivel de input)** y **Aislamiento de Carga de Trabajo**, descartando controles perimetrales (WAF, CrowdSec) y confinamiento de kernel (Chroot, AppArmor) para evitar complejidad operativa innecesaria en la red local de confianza.

**Implementación:**
1. **Sanitización Estricta:** Todo input (CSV) es desarmado antes de persistirse para prevenir inyección de fórmulas (CSV/Formula Injection).
2. **Mínimo Privilegio (Base de Datos):** La aplicación se conecta con un usuario restringido a solo lectura sobre los datos de la academia y solo escritura sobre las tablas de cruce temporales.
3. **Control de Recursos HTTP:** Nginx local con cabeceras de seguridad básicas y límite estricto de tamaño de carga.
4. **Desacoplamiento de Carga:** El cálculo intensivo no bloquea el servidor web; se deriva asíncronamente a workers de Laravel Horizon.

**Trade-offs:**
- Ventajas: Agilidad operativa para el equipo, cero falsos positivos de WAF bloqueando a usuarios internos, menor sobrecarga de configuración del sistema operativo.
- Desventajas: Si la red local es vulnerada, no hay una capa adicional de protección (AppArmor) para contener una escalada de privilegios en el servidor (riesgo aceptado dado el entorno).

### Sección de Arquitectura e Infraestructura

**A. Proxy Inverso: Nginx Local**

Configuración estándar orientada a rendimiento y prevención de fallos de subida masiva.
Cabeceras obligatorias:

```nginx
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "DENY" always;
client_max_body_size 10M;
```

**B. Capa de Ejecución: PHP-FPM / Laravel Octane**

Se ejecuta de manera estándar sin configuraciones de jaula Chroot ni AppArmor obligatorios, minimizando el mantenimiento de políticas. Se recomienda usar un usuario de sistema dedicado sin privilegios de administrador.

### Flujo de Datos (Cruce y Normalización)

- Toda entrada de texto del CSV pasa por sanitización anti-inyección de
  fórmulas antes de persistirse o exportarse (ver `NormalizarTextoAction`).
- La carga del archivo se valida por Magic Bytes y MIME real, no solo por
  extensión.
- `CalcularSimilitudesCabosAction` se ejecuta como Job encolado (Laravel
  Queues) para evitar timeouts y saturación de memoria en lotes grandes.

### Ejemplo de implementación técnica (referencia para el equipo)

```php
<?php

declare(strict_types=1);

namespace App\Actions\Cruce;

final readonly class NormalizarTextoAction
{
    public function execute(string $input): string
    {
        $sanitized = mb_strtoupper(trim($input), 'UTF-8');

        // Prevención de inyección de fórmulas para la exportación a Excel
        if (preg_match('/^[=+\-@\t\r]/', $sanitized)) {
            $sanitized = "'" . $sanitized;
        }

        $sanitized = str_replace(
            ['Á', 'É', 'Í', 'Ó', 'Ú', 'Ñ'],
            ['A', 'E', 'I', 'O', 'U', 'N'],
            $sanitized
        );

        return $sanitized;
    }
}
```

```php
// FormRequest de CruceIngresantesController
public function rules(): array
{
    return [
        'archivo_ingresantes' => [
            'required',
            'file',
            'mimetypes:text/csv,text/plain',
            'mimes:csv',
            'max:10240',
        ],
    ];
}
```

---

## Non-Functional Requirements

### NFR-001: Rendimiento de Carga (Procesamiento Asíncrono en Cola)

- **Requirement:** El procesamiento completo de un CSV con hasta ~27,000 filas × 12 columnas (filtrado, normalización, enrutamiento a `ingresantes`/`no_ingresantes` y agrupación en lote) debe completarse en menos de **50 segundos** medidos desde que el job es despachado a la cola Redis hasta que el lote queda en estado `completado` en base de datos.
- **Context:** El endpoint HTTP de carga responde en < 2 s retornando el `lote_id` y el estado `procesando`; el SLA de 50 s aplica exclusivamente al procesamiento asíncrono del job en cola, no a la respuesta HTTP inicial.
- **Traces to:** Art. 4 de la Constitución — Pipeline sin intervención manual; NFR-006 (Redis Queue); Assumption A-05 (disponibilidad de Redis).
- **Verification:** Test de rendimiento con un CSV sintético de ~27,000 filas × 12 columnas: medir el tiempo desde `Job::dispatch()` hasta que `lotes_cruce.estado = 'completado'` vía worker de cola Redis activo.

### NFR-002: Tiempo de Respuesta API (Fuzzy Match)

- **Requirement:** La consulta de candidatos (fuzzy match) para un ingresante individual en la interfaz interactiva debe responder en menos de 300 ms (percentil 95).
- **Traces to:** Art. 4 de la Constitución — Pruebas automatizadas; Assumption A-02 (índices en BD).
- **Verification:** Test de integración midiendo el tiempo de respuesta del endpoint `GET /api/cruce/{ingresante}/candidatos` con carga representativa.

### NFR-003: Volumen de Carga de Archivo

- **Requirement:** El sistema debe soportar la subida de archivos CSV de hasta 20 MB sin error de límite de memoria en el proceso HTTP inicial de recepción del archivo.
- **Traces to:** Art. 3 de la Constitución — Integridad de Normalización; necesidad operativa del equipo de admisiones. El procesamiento posterior corre en worker Redis (NFR-006), por lo que el límite de memoria HTTP no aplica a la normalización.
- **Verification:** Subir un CSV de 20 MB y confirmar: (a) respuesta HTTP exitosa con `lote_id`, (b) sin error `memory_limit` en el proceso HTTP, (c) job encolado correctamente visible en Redis.

### NFR-004: Seguridad de Credenciales

- **Requirement:** Las credenciales de conexión a la base de datos `academia` no deben almacenarse en el repositorio; deben gestionarse exclusivamente mediante variables de entorno.
- **Traces to:** Art. 4 de la Constitución — Seguridad de credenciales.
- **Verification:** Revisión de código automatizada (git-secrets o equivalente) + revisión manual en Pull Request.

### NFR-005: Trazabilidad de Lotes

- **Requirement:** Cada lote procesado debe registrar en base de datos: fecha de examen, total de registros del CSV, total enrutados a `ingresantes`, total enrutados a `no_ingresantes`, total con match exacto, total pendientes, total no ingresados y timestamp de inicio/fin del job.
- **Traces to:** Art. 4 de la Constitución — Auditoría y trazabilidad.
- **Verification:** Query de verificación en la tabla `lotes_cruce` después de procesar un lote de prueba; confirmar que los totales suman el 100% de filas del CSV.

### NFR-006: Procesamiento Asíncrono con Redis

- **Requirement:** La importación y normalización del CSV debe ejecutarse fuera del ciclo de vida HTTP, utilizando **Redis** como driver de colas de Laravel. El sistema debe soportar al menos 1 worker concurrente y tolerar reinicios del worker sin pérdida de datos (jobs fallidos deben quedar en la cola `failed_jobs` para reintento manual).
- **Traces to:** Art. 4 de la Constitución — Pipeline sin intervención manual; Gestión de Errores Silenciosos; NFR-001 (SLA de 50 s); volumen real de ~27,000 filas × 12 columnas que excede los límites prácticos de procesamiento síncrono en HTTP.
- **Verification:** (a) Verificar con `php artisan queue:work --queue=cruce` que el job `ProcessCsvBatchJob` se despacha y completa correctamente. (b) Simular fallo de worker a mitad de procesamiento y confirmar que el lote queda en estado `pausado` (no corruptible). (c) Confirmar que `QUEUE_CONNECTION=redis` está configurado en `.env`.

### NFR-007: Tiempo Máximo de Generación del Reporte de Validación Manual

- **Requirement:** El tiempo total transcurrido desde que el administrador navega a la vista de validación manual (`GET /api/cruce/{lote}/pendientes`) hasta que la interfaz React muestra la tabla completa de ingresantes `pendiente` con sus candidatos coloreados debe ser **≤ 5 minutos** para un lote con hasta ~27,000 ingresantes procesados (incluyendo los que quedaron en estado `pendiente`). El escenario base de producción actual registra tiempos de ~15 minutos, lo que excede el SLA admisible.
- **Context:** Este SLA aplica al tiempo de carga de la vista de validación, no al procesamiento del CSV (cubierto por NFR-001). El cuello de botella principal identificado es el cálculo de similitud difusa secuencial en PHP contra toda la BD `academia`. La estrategia de optimización prioriza: (1) uso de `pg_trgm` en PostgreSQL para delegar el cálculo de similitud al motor de BD, (2) precarga de alumnos de academia en Redis con TTL de 1 hora, (3) filtro previo por inicial de apellido antes de ejecutar la similitud, (4) chunking de ingresantes en batches de 500 procesados en paralelo.
- **Traces to:** Art. 4 de la Constitución — Pipeline sin intervención manual; Art. 3 — Precisión del Cruce; NFR-002 (300 ms por ingresante individual); A-02 (índices en BD).
- **Verification:** Test de rendimiento con un lote real de ~5,000 registros `pendiente`: medir el tiempo total desde el request hasta que la vista React termina de renderizar todos los candidatos. El tiempo debe ser ≤ 5 minutos. Documentar comparativa antes/después de implementar `pg_trgm`.

---



## Edge Cases

| ID | Scenario | Expected Behavior | Story Reference |
|----|----------|-------------------|-----------------:|
| EC-001 | Fila del CSV con campo de nombre o apellido vacío | Registrar el error en el log del lote con número de fila e identificador del registro; continuar procesando las filas siguientes sin abortar el lote | US-001 |
| EC-002 | CSV sin las columnas requeridas (`NOMBRES`, `OBSERVACION`, `FECHA_EXAMEN`) | Rechazar la carga inmediatamente con mensaje de error descriptivo indicando qué columnas faltan; no insertar ningún registro | US-001 |
| EC-003 | Motor de coincidencia difusa sin candidatos con similitud ≥ 70% (umbral de visualización) | Mostrar en el selector React directamente la opción "Sin coincidencias encontradas — Marcar como No Ingresado" como única opción disponible; no bloquear el flujo. Nota: el motor calcula internamente candidatos desde el 30%, pero solo se exponen al usuario los que superen el 70% | US-003 / US-004 |
| EC-004 | Fecha de examen del CSV ya procesada previamente | Ignorar silenciosamente los registros de esa fecha; registrar el salto en el log con la fecha omitida y la razón | US-001 |
| EC-005 | Alumno con más de 5 candidatos calculados de igual similitud | Tomar solo los 5 de mayor similitud; en caso de empate exacto, desempatar por orden alfabético del apellido paterno; el filtro de visualización del 70% se aplica después del top-5 | US-003 |
| EC-006 | CSV con codificación distinta de UTF-8 o ISO-8859-1 (ej. UTF-16) | Detectar la codificación al inicio de la carga; si no es soportada, rechazar con error descriptivo de codificación sin insertar ningún registro | US-001 |
| EC-007 | Timeout o error de conexión a la BD `academia` durante el cruce | Pausar el lote, marcar los registros procesados con su estado actual y alertar al administrador; los registros no procesados quedan en `pendiente` para reintento | US-002 / NFR-006 |
| EC-009 | Lote con 0 registros `confirmado_automatico` y 0 `confirmado_manual` al momento de exportar | Retornar HTTP 422 con mensaje: "No hay registros confirmados en este lote para exportar. Confirme al menos un match antes de descargar el reporte."; no generar archivo Excel vacío | US-005 |
| EC-010 | Ingresante pendiente cuyos candidatos calculados (30%–69%) existen pero ninguno supera el umbral de visualización del 70% | La interfaz muestra la opción "Sin coincidencias encontradas — Marcar como No Ingresado"; el log del lote registra que el ingresante tenía N candidatos calculados por debajo del umbral visual (para auditoría interna) | US-003 / US-004 |
| EC-008 | Worker Redis caído o reiniciado durante el procesamiento del job | El job queda en la cola `failed_jobs`; el lote permanece en estado `procesando` hasta que el administrador reintente el job manualmente; no se pierden ni duplican registros ya insertados | US-001 / NFR-006 |

---

## Error Scenarios

| ID | Error Condition | User Message | System Behavior | Story Reference |
|----|-----------------|:------------:|-----------------|----------------:|
| ERR-001 | CSV con formato de columnas incorrecto | "El archivo CSV no contiene las columnas requeridas: {lista}. Verifique el formato e intente nuevamente." | Rechazar carga; no insertar registros; log con detalle técnico | US-001 |
| ERR-002 | Codificación de archivo no soportada | "El archivo no puede leerse con la codificación detectada ({encoding}). Se acepta UTF-8 o ISO-8859-1." | Rechazar carga; retornar HTTP 422 con detalle de codificación detectada | US-001 |
| ERR-003 | Fallo de conexión a BD `academia` | "No se pudo establecer conexión con la base de datos de la academia. Contacte al administrador del sistema." | Abortar proceso de cruce; marcar lote como `error`; registrar stack trace en log del servidor | US-002 |
| ERR-004 | CSV vacío (0 registros tras filtro OBSERVACION) | "El archivo no contiene registros con observación 'ALCANZO VACANTE'. Verifique el contenido del CSV." | Retornar HTTP 422; no crear lote en BD | US-001 |
| ERR-005 | Archivo mayor a 20 MB | "El archivo supera el tamaño máximo permitido (20 MB). Divídalo en partes y vuelva a intentarlo." | Rechazar antes de procesar; retornar HTTP 413 | US-001 |
| ERR-006 | Confirmación de match con `alumno_id` inválido | "El alumno seleccionado no existe en la base de datos. Recargue la página e intente nuevamente." | Retornar HTTP 404; no actualizar estado del ingresante | US-004 |
| ERR-007 | Job `ProcessCsvBatchJob` falla y mueve a `failed_jobs` | "El procesamiento del lote encontró un error inesperado. El lote quedó en pausa. Contacte al administrador para reintentarlo." | Marcar `lotes_cruce.estado = 'error'`; registrar excepción completa en `failed_jobs`; no borrar registros ya insertados | US-001 / NFR-006 |

---

## Related or Duplicate Work

| Type | Target | Reason |
|------|--------|--------|
| `implementsTogether` | US-001, US-002 | Comparten el modelo `LoteCruce` y la lógica de conexión a la BD; deben implementarse en el mismo sprint como unidad cohesiva |
| `blocks` | US-003 | Depende de US-001 (registros normalizados en `ingresantes_cruce`) y US-002 (pool de alumnos de la academia disponible) |
| `blocks` | US-004 | Depende de US-003 para tener candidatos calculados en estado `pendiente` |
| `blocks` | US-005 | Depende de US-003 y US-004 para tener datos enriquecidos y estados resueltos |

---

## Glossary

| Term | Definition | Context |
|------|------------|---------:|
| Ingresante | Estudiante que alcanzó una vacante en el examen de admisión de la UNMSM | Dominio de negocio |
| Lote | Conjunto de registros del CSV agrupados por una misma `FECHA_EXAMEN` | Dominio técnico y de negocio |
| Match exacto | Coincidencia de 2 apellidos + al menos 1 nombre entre un ingresante y un alumno de la academia, tras normalización | Motor de cruce |
| Cabo suelto | Ingresante sin match exacto pero con similitud ≥ 30% con algún alumno de la academia | Motor de cruce |
| `confirmado_automatico` | Estado asignado cuando el cruce exacto establece la asociación sin intervención humana | Estado del sistema |
| `confirmado_manual` | Estado asignado cuando el administrador valida manualmente la asociación en la interfaz React | Estado del sistema |
| `pendiente` | Estado inicial de un ingresante que no obtuvo match exacto; requiere revisión manual | Estado del sistema |
| `no_ingresado` | Estado final cuando el administrador descarta todos los candidatos sugeridos | Estado del sistema |
| Jerarquía de estados | Orden de prioridad inmutable para resolver el estado de un alumno con múltiples registros históricos (Art. 3 Constitución) | Regla de negocio |
| Normalización | Proceso de convertir texto a MAYÚSCULAS, eliminar tildes y sustituir "Ñ" por "N" | Motor de normalización |
| Levenshtein | Algoritmo de distancia de edición usado para calcular la similitud entre cadenas de texto en el motor difuso | Técnico |
| `ingresantes` | Tabla de BD que almacena los registros del CSV cuyo campo `OBSERVACION` normalizado equivale a `ALCANZO VACANTE` | Schema analítico |
| `no_ingresantes` | Tabla de BD que almacena los registros del CSV que **no** cumplen el filtro de `OBSERVACION`; conservados para auditoría y trazabilidad del lote | Schema analítico |
| `ProcessCsvBatchJob` | Job de Laravel despachado a la cola Redis que orquesta la importación, normalización y enrutamiento dual del CSV | Técnico |
| Redis Queue | Servicio de cola basado en Redis usado como driver de `QUEUE_CONNECTION` en Laravel para procesar jobs asíncronos fuera del ciclo HTTP | Técnico |

---

## Assumptions

| ID | Assumption | If False, Then… |
|----|------------|-----------------|
| A-01 | El formato de codificación del CSV es siempre UTF-8 o ISO-8859-1 | Si se sube un CSV con otra codificación (ej. UTF-16), la carga fallará con ERR-002, evitando caracteres corruptos en la BD |
| A-02 | La base de datos `academia` tiene índices creados sobre los campos de apellidos y nombres | Sin índices, las consultas de cruce exacto y difuso degradarán el rendimiento, incumpliendo NFR-001 y NFR-002 |
| A-03 | El umbral de **cálculo interno** del motor difuso es 30% (mínimo para considerar un candidato); el umbral de **visualización en la interfaz** es 70% (mínimo para mostrar al usuario) | Si el umbral de visualización del 70% es demasiado alto, el administrador no verá candidatos válidos y deberá marcar manualmente más registros como "No Ingresado"; si es demasiado bajo, el selector React mostrará candidatos de baja confianza que incrementan el riesgo de match incorrecto. Estos dos umbrales son independientes y configurables por separado |
| A-04 | Un máximo de 5 candidatos potenciales (calculados, pre-filtro de 70%) es suficiente para cubrir los errores de digitación más frecuentes | Si existen más de 5 homónimos con la misma similitud, el candidato correcto podría quedar excluido de la lista, obligando a búsqueda manual extendida |
| A-05 | El servicio Redis está disponible y accesible desde el servidor Laravel en el entorno de producción | Si Redis no está disponible, el job no podrá encolarse, el procesamiento del CSV fallará inmediatamente tras la recepción del archivo y el SLA de NFR-001 no podrá cumplirse. Mitigación: configurar un health-check de Redis en el startup de la aplicación |
| A-06 | El Excel final es un documento de distribución de resultados confirmados, no un reporte de auditoría del proceso de cruce | Si los usuarios de negocio necesitan ver también los registros `pendiente` o `no_ingresado` en el Excel, se requerirá una nueva US (hoja adicional de auditoría). Por ahora, la Hoja 1 contiene exclusivamente registros con `estado_match IN ('confirmado_automatico', 'confirmado_manual') |

---

## Open Questions

> Estas preguntas se identificaron durante la especificación y requieren resolución en la fase de clarificación. Las marcadas con 🔴 son bloqueantes para implementación.

1. [x] ✅ **[NC-1 — RESUELTO]:** ¿El filtro por `ALCANZO VACANTE` se aplica sobre el valor normalizado (mayúsculas, sin tildes) o sobre el valor crudo del CSV?
   - **Decisión confirmada por PO (2026-06-24):** El filtro se aplica **siempre sobre el valor normalizado** (mayúsculas, sin tildes). No existe caso de uso donde el valor crudo sea preferido.
   - **Consecuencia en datos:** los registros que no cumplan el filtro normalizado se persisten en la tabla `no_ingresantes` (no se descartan). Ver AC-004 y Technical Notes de US-001.
   - **Impacto en schema:** se requieren dos tablas diferenciadas: `ingresantes` y `no_ingresantes`, ambas con `lote_cruce_id` como FK.

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-06-01 | Samuel Cisneros | Especificación funcional inicial (formato libre) |
| 2.0 | 2026-06-10 | Renzo Fabián | Incorporación de match difuso (cabos sueltos) y React UI |
| 2.2.0 | 2026-06-16 | Samuel Cisneros / Equipo V2 | Alineación con Constitución v2.2.0; ignorado de fechas duplicadas; supresión de match difuso automático sin revisión |
| 2.3.0 | 2026-06-24 | Equipo V2 (refactor por Antigravity) | Adaptación completa al modelo Enterprise SDD: US-XXX H3, AC como checkboxes, NFR con trazabilidad, tablas de EC/ERR, Story Linking, Glosario, Assumptions formalizados |
| 2.4.0 | 2026-06-24 | Samuel Cisneros (PO) | Correcciones post-revisión: NFR-001 ajustado de 5 s → 50 s; NC-1 resuelto (filtro post-normalización); persistencia dual ingresantes/no_ingresantes en AC-004; NFR-006 Redis Queue añadido; volumen real documentado (~27,000 filas × 12 columnas) |
| 2.5.0 | 2026-06-24 | Equipo V2 (revisión elite Antigravity) | Revisión final: Executive Summary actualizado con dual-table + Redis; NFR-001 título y trazabilidad unificados; NFR-003 verificación alineada con arquitectura de colas; EC-008 añadido (worker Redis caído); ERR-007 añadido (job a failed_jobs); Glosario extendido con 4 términos nuevos (ingresantes, no_ingresantes, ProcessCsvBatchJob, Redis Queue); A-05 añadido (disponibilidad Redis) |
| 2.6.0 | 2026-07-02 | Samuel Cisneros (PO) — decisiones ratificadas | **Umbral dual de similitud:** umbral de cálculo interno permanece en 30%; nuevo umbral de visualización en interfaz React fijado en 70%. **Sistema de colores en React (AC-011b):** verde intenso 95–100%, verde claro 85–94%, amarillo 70–84%; candidatos <70% no se muestran. **Alcance Excel redefinido (AC-014, AC-014b):** Hoja 1 contiene exclusivamente registros `confirmado_automatico` y `confirmado_manual`; registros `pendiente` y `no_ingresado` excluidos del Excel. **EC-009, EC-010 añadidos.** **A-06 añadido** (Excel como documento de distribución, no de auditoría). **NFR-007 añadido** (tiempo máximo de generación del reporte de validación ≤ 5 min). |
| 2.7.0 | 2026-07-03 | Antigravity | Incorporación de racional y arquitectura de seguridad (perímetro Nginx/WAF/CrowdSec, PHP-FPM Chroot, AppArmor) |

---

## External References

> Fuentes externas consultadas durante la elaboración de esta especificación.
> Ver `source-verification.instructions.md` para el flujo DETECT→FETCH→IMPLEMENT→CITE.

| Source | Access Date | Relevant Section | Notes |
|--------|:-----------:|-----------------|-------|
| Papalini, E. (2026). *Non-Deterministic Spec-Driven Development — Enterprise Edition*. Independently published. | 2026-06-24 | Cap. 2 (Four Phases / Four Gates), Cap. 11-12 (Enterprise SDD Pipeline), App. C Template 2 (spec.md) | Framework de referencia para la estructura del presente spec |
| Constitución del Proyecto Vonex v2.2.0 ([constitution.md](constitution.md)) | 2026-06-16 | Art. 2-7 | Fuente de verdad para estándares de calidad, jerarquía de estados y límites del proyecto |
