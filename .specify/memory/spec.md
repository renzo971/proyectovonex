# Especificación Funcional: Motor de Cruce Automático de Ingresantes UNMSM

**PO**: Diego Fernando
**Equipo**: Grupo V2 (Vonex)
**Versión**: 2.0 (Laravel 13, React, Coincidencia Asistida y PostgreSQL)

## 1. Resumen Ejecutivo
Automatizar el cruce de datos entre los ingresantes del examen de admisión de la UNMSM (cargados mediante archivo CSV) y los alumnos registrados en la base de datos de la academia en PostgreSQL (academia). El sistema procesará el CSV, normalizará los nombres, realizará un cruce inicial exacto guardando coincidencias inmediatas, y procesará los "cabos sueltos" mediante una búsqueda exhaustiva de similitud para presentarlos en una interfaz web reactiva. En esta pantalla, el usuario podrá validar y seleccionar manualmente los registros parecidos. Las fechas de examen ya cargadas serán ignoradas en futuras importaciones. El resultado final será un Excel descargable estructurado con toda la información consolidada.

## 2. Contexto de Negocio
Actualmente, el cruce de ingresantes a la UNMSM es manual y requiere mucho esfuerzo operativo. Este motor automatizará la validación de identidades en tiempo real utilizando la base de datos academia. También resolverá inconsistencias de escritura de nombres comunes (ej. "Sntos" vs "Santos") mediante un motor de coincidencia asistida por interfaz web, evitando falsos positivos iniciales pero capturando ingresantes con errores tipográficos, garantizando reportes precisos y segmentados por fecha de examen.

## 3. Historias de Usuario (US) y Criterios de Aceptación (AC)

### US-1: Carga, Normalización y Auto-Batching de CSV
Como administrador, quiero subir el CSV de ingresantes para que el sistema normalice y agrupe los registros por fecha de examen.
**AC-1.1 (Carga e Ignorado de Duplicados)**: Al subir un nuevo CSV, el sistema lee la fecha de examen. Si esa fecha de examen ya fue procesada anteriormente, el sistema ignora esos registros para evitar duplicidades en la base de datos.
**AC-1.2 (Normalización Forzada)**: El motor limpia todos los nombres del CSV (MAYÚSCULAS, elimina tildes, reemplazo estricto de "Ñ" por "N").
**AC-1.3 (Separación de Cadenas)**: Separa lógicamente apellidos paterno, materno y nombres, reconociendo apellidos compuestos.

### US-2: Consulta Directa a Base de Datos Academia (PostgreSQL)
Como sistema, quiero consultar directamente la base de datos academia en PostgreSQL para validar a los alumnos matriculados vigentes.
**AC-2.1 (Conexión Directa)**: El motor realiza consultas eficientes a la base de datos en PostgreSQL para traer la información de matrícula histórica y vigente de los alumnos.
**AC-2.2 (Jerarquía de Estados)**: Ante múltiples coincidencias de registros históricos del mismo alumno, se desempata por prioridad estricta: 1. MATRICULADO, 2. PAGADO, 3. FINALIZADO, 4. SUSPENDIDO, 5. RETIRADO, 6. TRASLADADO, 7. STAND BY, 8. ANULADO.

### US-3: Motor de Coincidencia en Dos Pasos (Match Engine)
Como administrador, quiero que el sistema realice un cruce en dos fases (automático exacto y difuso asistido) para emparejar ingresantes.
**AC-3.1 (Paso 1 - Match Exacto)**: Si un ingresante coincide en 2 apellidos exactos + 1 nombre exacto contra un alumno de la academia, el sistema realiza el match automático de forma silenciosa y lo marca en la BD como confirmado_automatico.
**AC-3.2 (Paso 2 - Cabos Sueltos y Búsqueda Exhaustiva)**: Si no hay match exacto, el motor ejecuta un algoritmo de similitud analizando la frecuencia de letras y distancia (como Levenshtein) para encontrar candidatos potenciales de la academia. Los ingresantes se marcan como pendiente.

### US-4: Interfaz de Extracción y Validación Asistida (React)
Como administrador, quiero ver los cabos sueltos y poder seleccionar manualmente el alumno correcto mediante una interfaz interactiva de React.
**AC-4.1 (Componente de Selección)**: La interfaz en React muestra una fila por cada cabo suelto (pendiente). Al lado de los datos del ingresante, se renderiza un selector (<select>) ordenado de mayor a menor probabilidad con los alumnos similares sugeridos.
**AC-4.2 (Confirmación y Persistencia)**: Al elegir un alumno y pulsar confirmar, el sistema asocia el registro, cambia el estado a confirmado_manual y actualiza la base de datos analítica.

### US-5: Exportación de Reporte Consolidado a Excel
Como usuario de negocio, quiero descargar un archivo Excel con la información unificada.
**AC-5.1 (Estructura de Hoja 1 - Datos)**: El reporte Excel consolidado contendrá en sus primeras columnas (A-M) los datos del CSV crudo original de ingresantes, y de la columna N en adelante los datos enriquecidos obtenidos de la base de datos (Sede, Ciclo, Año, Estado, etc.).

## 4. Suposiciones (Assumptions)
La base de datos academia PostgreSQL tiene los índices apropiados en apellidos y nombres para búsquedas rápidas.
El archivo CSV de ingresantes UNMSM tiene una estructura fija que permite extraer la fecha de examen.

## 5. Fuera de Alcance (Out of Scope)
El scraping y obtención del CSV de ingresantes UNMSM.
Generación de reportes dinámicos fuera del formato Excel unificado.