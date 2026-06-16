**Feature:** Motor de Cruce Automático de Ingresantes UNMSM
**Dueño (QA):** Diego Fernando
**Equipo:** Grupo V2 (Vonex)

## Resumen Ejecutivo
Este documento define las pruebas del flujo automatizado que cruza el CSV crudo de San Marcos contra la API de Vonex y genera el Excel final. El enfoque principal es validar la normalización de apellidos compuestos, garantizar que la caída de la API no genere falsos negativos, y verificar matemáticamente el algoritmo estricto de coincidencia (2 apellidos + 1 nombre). Los casos límite contemplan el desempate por prioridad de estados y el correcto desplazamiento de la data enriquecida a partir de la columna N en el reporte descargable.

## Casos de Prueba (Test Cases)

### TC-1: Agrupación por lotes de fechas múltiples (de AC-1.1)
**Datos:** CSV crudo de San Marcos que contiene 100 filas del examen del sábado `14/03/2026` y 100 filas del domingo `15/03/2026` mezcladas.
**Pasos:** Ejecutar la carga del CSV en el sistema automatizado.
**Esperado:** El sistema no sobreescribe la data; separa internamente la ejecución creando exactamente 2 lotes independientes (Batch 1: 14/03/2026, Batch 2: 15/03/2026) con 100 registros cada uno.

### TC-2: Limpieza y normalización de textos (de AC-1.2 y AC-1.3)
**Datos:** Fila del CSV con el campo Apellidos y Nombres ingresado como: `De la Cruz Muñoz, María-José`.
**Pasos:** Pasar el registro por el módulo de limpieza y separación de cadenas.
**Esperado:** El texto se normaliza a mayúsculas y sin tildes. El sistema reconoce el apellido compuesto resultando en `Apellido 1: DE LA CRUZ`, `Apellido 2: MUNOZ`, `Nombres: MARIA-JOSE`.

### TC-3: Algoritmo estricto de coincidencia (de AC-3.1)
**Datos:** 
- San Marcos CSV: `CASTILLO TORIBIO DIEGO`
- API Vonex: `CASTILLO TORIBIO DIEGO FERNANDO SEBASTIAN`
**Pasos:** Ejecutar el motor de coincidencia para cruzar ambos registros.
**Esperado:** El sistema evalúa "True" (coinciden exactamente dos apellidos y al menos un nombre) y lo marca como "Match Confirmado".

### TC-4: Tolerancia a fallos de red (de AC-2.2)
**Datos:** Lote de 500 alumnos.
**Pasos:** Bloquear intencionalmente el acceso al endpoint de la API de Vonex (simular un error HTTP 504 Gateway Timeout) e iniciar el procesamiento del lote.
**Esperado:** El flujo se detiene de inmediato. No se envían datos nulos al Excel y se lanza la alerta "Error de conexión con la BD". El estado del proceso queda "En Pausa", permitiendo reintentar.

### TC-5: Desempate por jerarquía estricta de estados (de AC-4.4)
**Datos:** Alumno `PEREZ RUIZ ANA` que, tras consultar la API de Vonex, devuelve tres registros históricos con los estados: `TRASLADADO`, `SUSPENDIDO` y `MATRICULADO`.
**Pasos:** Aplicar el filtro de prioridad de estados al registro enriquecido.
**Esperado:** El sistema clasifica al estudiante usando la prioridad 1. Se descartan `TRASLADADO` y `SUSPENDIDO`, enviando únicamente la etiqueta `MATRICULADO` (Lista 3) al resultado final.

### TC-6: Exclusión de estados no permitidos (de AC-4.5)
**Datos:** Registro extraído de la API de Vonex con el estado "DEUDOR EXCLUIDO".
**Pasos:** Procesar el lote para la generación del reporte.
**Esperado:** El sistema detecta que el estado no pertenece a los 8 permitidos por negocio, por lo que ignora el cruce y el alumno no aparece en la data enriquecida de Vonex.

### TC-7: Integridad Estructural del Excel y Dashboard (de AC-5.1, AC-5.2 y AC-5.3)
**Datos:** Cruce automatizado finalizado de un lote de 20 alumnos ingresantes.
**Pasos:** Descargar el Excel generado y abrir el archivo. Navegar a la Hoja 1 y luego a la Hoja 2. Aplicar el filtro por fecha en la Hoja 2.
**Esperado:** 
- En la Hoja 1, las columnas A hasta M contienen data estricta de San Marcos.
- A partir de la columna N, aparece la Sede, Ciclo y Estado histórico de Vonex.
- En la Hoja 2, el Dashboard se carga correctamente mostrando las gráficas pre-construidas. Al seleccionar una fecha específica en el segmentador, los gráficos se actualizan filtrando la información al instante.