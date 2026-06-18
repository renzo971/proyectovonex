# Casos de Prueba: Motor de Cruce Automático de Ingresantes UNMSM

**Dueño (QA)**: Yerson Vargas
**Equipo**: Grupo V2 (Vonex)
**Versión**: 2.2.0

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
