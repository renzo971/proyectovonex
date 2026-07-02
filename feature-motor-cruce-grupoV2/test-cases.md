# Casos de Prueba: Motor de Cruce Automático de Ingresantes UNMSM

**Dueño (QA)**: Diego Fernando
**Equipo**: Grupo V2 (Vonex)
**Versión**: 2.5.0

## Resumen ejecutivo (≤150 palabras)

Este documento define los casos de prueba del flujo de trabajo analítico que cruza los registros de ingresantes de la UNMSM con los alumnos matriculados en la base de datos de la academia. El enfoque principal es validar la carga del CSV filtrando por observación, normalización de apellidos compuestos y la precisión del motor en dos fases (coincidencia automática exacta y difusa asistida). Los casos cubren flujos felices, manejo de errores de conexión de base de datos, resolución de jerarquía de estados múltiples y la validación estructural del Excel exportado con su dashboard interactivo.

## Casos de Prueba (Test Cases)

### TC-1 (de AC-1.1, caso feliz): Agrupación por lotes de fechas múltiples

**Datos:** CSV crudo de San Marcos que contiene 100 filas del examen del sábado `14/03/2026` y 100 filas del domingo `15/03/2026` mezcladas.
**Pasos:** Ejecutar la carga del CSV en el sistema automatizado.
**Esperado:** El sistema no sobreescribe la data; separa internamente la ejecución creando exactamente 2 lotes independientes (Batch 1: 14/03/2026, Batch 2: 15/03/2026) con 100 registros cada uno.

### TC-2 (de AC-1.2 y AC-1.3, caso feliz): Limpieza y normalización de textos

**Datos:** Fila del CSV con el campo Apellidos y Nombres ingresado como: `De la Cruz Muñoz, María-José`.
**Pasos:** Pasar el registro por el módulo de limpieza y separación de cadenas.
**Esperado:** El texto se normaliza a mayúsculas y sin tildes. El sistema reconoce el apellido compuesto resultando en `Apellido 1: DE LA CRUZ`, `Apellido 2: MUNOZ`, `Nombres: MARIA-JOSE`.

### TC-3 (de AC-3.1, caso feliz): Algoritmo estricto de coincidencia

**Datos:**

- San Marcos CSV: `CASTILLO TORIBIO DIEGO`
- API/DB Vonex: `CASTILLO TORIBIO DIEGO FERNANDO SEBASTIAN`
  **Pasos:** Ejecutar el motor de coincidencia para cruzar ambos registros.
  **Esperado:** El sistema evalúa "True" (coinciden exactamente dos apellidos y al menos un nombre) y lo marca automáticamente en la BD como `confirmado_automatico`.

### TC-4 (de AC-2.1, caso de error): Tolerancia a fallos de red/base de datos

**Datos:** Lote de 500 alumnos cargados en memoria.
**Pasos:** Simular pérdida de conexión con la base de datos `academia` PostgreSQL durante la ejecución del proceso.
**Esperado:** El flujo de cruce se detiene inmediatamente. No se escriben registros inconsistentes ni se genera el Excel, y se lanza la alerta "Error de conexión con la BD". El estado del proceso de cruce del lote queda marcado como "En Pausa".

### TC-5 (de AC-2.2, caso borde): Desempate por jerarquía estricta de estados

**Datos:** Alumno `PEREZ RUIZ ANA` que, tras consultar la base de datos `academia`, devuelve tres registros históricos con los estados: `TRASLADADO`, `SUSPENDIDO` y `MATRICULADO`.
**Pasos:** Aplicar el filtro de prioridad de estados al registro enriquecido.
**Esperado:** El sistema clasifica al estudiante usando la prioridad 1. Se descartan `TRASLADADO` y `SUSPENDIDO`, guardando únicamente la etiqueta `MATRICULADO` (Lista 1) en el ingresante cruzado.

### TC-6 (de AC-2.2, caso de error): Exclusión de estados no permitidos

**Datos:** Registro extraído de la base de datos con el estado "DEUDOR EXCLUIDO".
**Pasos:** Procesar el lote para la generación del reporte.
**Esperado:** El sistema detecta que el estado no pertenece a los 8 estados permitidos por negocio, por lo que ignora el cruce y el alumno no aparece en la data enriquecida de la academia.

### TC-7 (de AC-5.1 y AC-5.2, caso feliz): Integridad Estructural del Excel y Dashboard

**Datos:** Cruce automatizado finalizado de un lote de 20 alumnos ingresantes.
**Pasos:** Descargar el Excel generado y abrir el archivo. Navegar a la Hoja 1 y luego a la Hoja 2. Aplicar el filtro por fecha en la Hoja 2.
**Esperado:**

- En la Hoja 1, las columnas A hasta M contienen data estricta de San Marcos.
- A partir de la columna N, aparece la Sede, Ciclo y Estado histórico de la academia.
- En la Hoja 2, el Dashboard se carga correctamente mostrando las gráficas pre-construidas. Al seleccionar una fecha específica en el segmentador, los gráficos se filtran dinámicamente.

### TC-8 (de AC-1.4, caso feliz): Filtrado por campo OBSERVACION

**Datos:** CSV de ingresantes que contiene registros con diferentes valores en el campo `OBSERVACION` (ej. "ALCANZO VACANTE", "NO INGRESÓ", "RETIRO DE VACANTE").
**Pasos:** Subir y procesar el CSV en el sistema.
**Esperado:** El sistema filtra e importa en el lote únicamente aquellos registros cuyo campo `OBSERVACION` contenga exactamente `ALCANZO VACANTE`. Los demás registros son omitidos del proceso.

### TC-9 (de AC-3.2, caso feliz): Cálculo y ranking de candidatos de coincidencia difusa (fuzzy)

**Datos:**
- Ingresante en CSV (cabos sueltos): `GONZALES DE LA FLOR PEDRO` (sin coincidencia exacta).
- BD `academia`: `GONZALEZ DE LA FLOR PEDRO` (similitud 92%), `GONZALES FLOR PEDRO` (similitud 88%), `GONZALEZ FLOR PEDRO` (similitud 84%), `GONZALES PEDRO` (similitud 55%), `FLOR PEDRO` (similitud 40%), y `RODRIGUEZ PEDRO` (similitud 10%).
**Pasos:** Ejecutar el motor de coincidencia difusa para el ingresante.
**Esperado:** El ingresante queda marcado en estado `pendiente`. Se genera una lista ordenada de hasta 5 candidatos potenciales que superan el 30% de similitud, ordenados de mayor a menor porcentaje:
  1. `GONZALEZ DE LA FLOR PEDRO` (92%)
  2. `GONZALES FLOR PEDRO` (88%)
  3. `GONZALEZ FLOR PEDRO` (84%)
  4. `GONZALES PEDRO` (55%)
  5. `FLOR PEDRO` (40%)
  El candidato `RODRIGUEZ PEDRO` (10%) queda excluido por no superar el umbral mínimo del 30%.

### TC-10 (de AC-4.1 y AC-4.2, caso feliz): Validación asistida e interfaz interactiva (React)

**Datos:** Ingresante `GONZALES DE LA FLOR PEDRO` en estado `pendiente` con sus 5 candidatos sugeridos (generados en TC-9).
**Pasos:** Cargar la UI en React. En la fila del ingresante, abrir el componente `<select>` de sugerencias, seleccionar el candidato `GONZALEZ DE LA FLOR PEDRO` y hacer clic en el botón "Confirmar Match".
**Esperado:** El frontend invoca al endpoint del backend enviando los IDs correspondientes. La API ejecuta `GuardarCruceConfirmadoAction`, persiste la asociación, actualiza el estado del ingresante a `confirmado_manual` y remueve al ingresante de la lista de pendientes en la UI React.

### TC-11 (de CB-1, caso de error): Manejo de campos vacíos en CSV de ingresantes

**Datos:** Registro del CSV con el campo `NOMBRES` vacío y campo `FECHA_EXAMEN` como `14/03/2026`.
**Pasos:** Cargar el CSV en el sistema.
**Esperado:** El sistema registra un error en el archivo de log del lote especificando la línea del CSV afectada y la columna vacía, descarta ese registro en específico, y continúa procesando el resto del lote con normalidad.

### TC-12 (de CB-2, caso de error): Validación de estructura de columnas en CSV

**Datos:** Archivo CSV que no posee la columna `OBSERVACION` (contiene columnas `NOMBRES` y `FECHA_EXAMEN` únicamente).
**Pasos:** Subir el archivo CSV al sistema.
**Esperado:** El sistema detiene el proceso de inmediato en la subida, rechaza el archivo sin crear lotes ni registros en la base de datos, y muestra al usuario el mensaje de error: "Estructura de CSV inválida. Falta columna requerida: OBSERVACION".

### TC-13 (de AC-2.1 v2.5.0, caso bugfix): Match por DNI de alumno con estado FINALIZADO

**Datos:**
- CSV ingresante: código=`71178246`, apellidos=`AURIS HUANCA`, nombres=`DARRELL JAASIEL`, EAP=`DERECHO`.
- BD academia: `personas.dni=71178246`, apellido_paterno=`AURIS HUANCA` (compuesto), apellido_materno=``, nombres=`DARRELL JAASIEL`, estado=14 (FINALIZADO), estado_aula=1 (REGULAR).
**Pasos:** Ejecutar el job de cruce completo (exacto + difuso).
**Esperado:** El sistema encuentra al alumno por **DNI** (coincidencia exacta del código 71178246 contra personas.dni), lo asocia automáticamente y marca al ingresante como `confirmado_automatico`. No depende de la correcta separación de apellidos en la BD academia.

### TC-14 (de AD-002 v2.5.0, caso rendimiento): Memoria compartida entre fases exacta y difusa

**Datos:** Lote de 500 ingresantes + 20K alumnos activos en BD academia.
**Pasos:** Ejecutar `ProcessCsvBatchJob` con `memory_limit=128M` configurado.
**Esperado:** El job completa sin error `Allowed memory size exhausted`. Los datos de academia se cargan una sola vez y los índices `byDni`/`byName` contienen solo enteros (no copias de registros). El job procesa exact match + fuzzy batch sin duplicar los 20K registros en memoria.

### TC-15 (de AD-003 v2.5.0, caso feliz): Fuzzy pre-check por DNI antes de scan completo

**Datos:**
- CSV ingresante: código=`12345678`, apellidos=`PEREZ TAPIA`, nombres=`JUAN CARLOS`.
- BD academia: `personas.dni=12345678`, apellido_paterno=`PEREZ TAPIA` (compuesto), apellido_materno=``, nombres=`JUAN CARLOS`, estado=3 (PAGADO).
**Pasos:** Ejecutar la fase difusa del job para este ingresante (simular que el exacto no lo encontró por diferencia en apellidos).
**Esperado:** El pre-check por DNI dentro de `computeFuzzyCandidates` encuentra el match inmediato (100% similitud) y lo confirma como `confirmado_manual`, sin ejecutar el scan Levenshtein contra los 20K alumnos.

### TC-16 (de AC-006 v2.5.0, caso bugfix): Consulta incluye estado FINALIZADO (14)

**Datos:** BD academia con alumno `GARCIA LOPEZ LUIS` con estado=14 (FINALIZADO), estado_aula=1.
**Pasos:** Ejecutar `getActiveAlumnos()` en `RealizarCruceExactoAction`.
**Esperado:** El query SQL incluye `estado IN (2,3,9,13,14)` y retorna al alumno FINALIZADO. El alumno está disponible tanto para match exacto como para fuzzy.

