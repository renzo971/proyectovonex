**Feature:** Motor de Cruce Automático de Ingresantes UNMSM
**PO:** Diego Fernando
**Equipo:** Grupo V2 (Vonex)
**Versión:** 1.1 (Reporte Excel, Dashboard y Reglas de Estado)

### 1. Resumen Ejecutivo
Automatizar el cruce de datos entre los resultados del examen de admisión de San Marcos (UNMSM) y la base de datos de Vonex. El sistema aceptará un CSV "crudo" con resultados de múltiples días, agrupará los datos y los cruzará contra la API de Vonex. El resultado final será un archivo Excel descargable que consolidará en su primera hoja los datos originales (columnas A-M) junto con los datos enriquecidos de Vonex (columna N en adelante), e incluirá una segunda hoja con un Dashboard interactivo filtrable por fecha de examen. La asignación de datos históricos se regirá por una tabla estricta de prioridad de estados.

### 2. Contexto de Negocio
Actualmente, el cruce de ingresantes a la UNMSM es manual y la presentación de resultados carece de un formato estandarizado. Se requiere un sistema "Zero-Touch" que automatice el cruce consultando a la API de Vonex en tiempo real y genere un reporte Excel estructurado. Adicionalmente, el sistema debe resolver conflictos de registros históricos múltiples aplicando una jerarquía de estados validada por el negocio, para que las áreas académicas y de marketing tengan información exacta y filtrable por fecha de examen sin trabajo adicional.

### 3. Historias de Usuario (US) y Criterios de Aceptación (AC)

**US-1: Carga Cruda (Raw) y Agrupación Automática (Auto-Batching)**
*Como administrador, quiero subir el CSV de resultados de San Marcos tal como se descarga del scraping, para que el sistema identifique y procese los días de examen automáticamente.*
* **AC-1.1 (Detección de Fechas y Lotes):** Dado que se sube un CSV crudo, cuando el sistema lo procesa, entonces identifica la columna de fecha y divide internamente los registros en lotes por día de examen.
* **AC-1.2 (Limpieza de texto):** Dado un lote válido, el sistema debe convertir todo a MAYÚSCULAS, eliminar tildes y reemplazar "Ñ" por "N".
* **AC-1.3 (Separación de cadenas):** El sistema debe identificar y separar lógicamente los dos apellidos de los nombres individuales, considerando apellidos compuestos.

**US-2: Integración Directa con Base de Datos Vonex (API)**
*Como sistema, quiero conectarme a la API de Vonex procesando lote por lote para obtener los estados actualizados de los alumnos.*
* **AC-2.1 (Conexión y Consulta por Lote):** Dado un lote de fecha específico, el sistema solicita datos a la API de Vonex y recibe la información histórica y actual eficientemente.
* **AC-2.2 (Manejo de Caídas y Reintentos):** Si la API no responde o da timeout, el sistema pausa el procesamiento del lote, alerta sobre el error y no genera falsos negativos.

**US-3: Motor de Coincidencia (Matching Engine)**
*Como administrador, quiero que el sistema compare los lotes normalizados contra la data de la API para encontrar coincidencias exactas.*
* **AC-3.1 (Match Exitoso):** Cuando coinciden exactamente los DOS apellidos y AL MENOS UN nombre, el sistema lo marca como "Match Confirmado".
* **AC-3.2 (Enriquecimiento):** Tras un match, el sistema extrae de la API los datos de Vonex (Sede, Ciclo, Año, Estados, etc.).

**US-4: Clasificación y Prioridad de Estados Estricta**
*Como administrador, quiero que el cruce arroje a los estudiantes clasificados según su histórico en Vonex, resolviendo duplicados mediante una tabla de validación de estados.*
* **AC-4.1 (Lista 3):** Estado "Matriculado" o "Pagado" en ciclo actual = Lista 3.
* **AC-4.2 (Lista 2):** Al menos un día de matrícula en un ciclo activo (incluso si está retirado) = Lista 2.
* **AC-4.3 (Lista 1):** Registro histórico desde el año base = Lista 1.
* **AC-4.4 (Desempate por Prioridad):** Dado un alumno con múltiples registros históricos, el sistema evaluará y mostrará el registro basándose en la siguiente prioridad estricta: 1. MATRICULADO, 2. PAGADO, 3. FINALIZADO, 4. SUSPENDIDO, 5. RETIRADO, 6. TRASLADADO, 7. STAND BY, 8. ANULADO.
* **AC-4.5 (Filtro de Estados Excluidos):** Dado un registro en la base de Vonex, cuando su estado NO coincida con los 8 estados mencionados en AC-4.4, entonces el sistema no lo toma en cuenta para el cruce.

**US-5: Generación de Reporte Excel y Dashboard**
*Como usuario de negocio, quiero descargar un archivo Excel con los datos estructurados y un dashboard dinámico para analizar los ingresos filtrados por fecha.*
* **AC-5.1 (Estructura de Hoja 1 - Datos):** Dado el cruce finalizado, cuando el sistema genera el Excel, en la "Hoja 1" las columnas desde la A hasta la M deben contener exclusivamente los datos extraídos del CSV scrapeado de San Marcos, y desde la columna N en adelante los datos enriquecidos de Vonex.
* **AC-5.2 (Estructura de Hoja 2 - Dashboard):** Dado el archivo Excel, cuando se abre la "Hoja 2", debe mostrar un Dashboard pre-construido basado en los datos de la Hoja 1.
* **AC-5.3 (Filtro por fecha en Dashboard):** Dado el Dashboard en la Hoja 2, debe existir un control o segmentador que permita filtrar la información por la "Fecha de examen" específica.

### 4. Suposiciones (Assumptions)
* El CSV de scraping contiene siempre un número de columnas igual o menor a 13 (A-M) para que la data de Vonex empiece consistentemente en la columna N.
* La API de Vonex expone los endpoints necesarios (protegidos por autenticación) para consultar alumnos y sus estados.
* La librería o herramienta de automatización utilizada para generar el Excel soporta la creación de tablas dinámicas/dashboards incrustados (o la inyección de datos en una plantilla preexistente con el dashboard ya configurado).

### 5. Dudas Abiertas [NEEDS_CLARIFICATION]
* **Volumen y Paginación de API:** ¿La API de Vonex está optimizada para recibir consultas masivas o el sistema implementará un *rate limit*?
* **Plantilla vs Generación:** ¿El sistema generará el Dashboard desde cero por código (librería Excel) o inyectará los datos de la Hoja 1 en un archivo `.xlsx` plantilla donde el Dashboard de la Hoja 2 ya está diseñado? *(Nota técnica: Inyectar en una plantilla es más eficiente y evita problemas de formato).*

### 6. Fuera de Alcance (Out of Scope)
* El desarrollo y mantenimiento del bot de scraping de la UNMSM.
* Interfaz de resolución manual ("Human-in-the-loop") para nombres difusos.
* Creación de un Dashboard web externo (Looker Studio, PowerBI, etc.); el entregable requerido es estrictamente un archivo Excel descargable.
* Procesamiento de registros con estados que no estén en la lista de los 8 permitidos.