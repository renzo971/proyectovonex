<!--
SYNC IMPACT REPORT:
- Version change: 2.2.0 -> 2.5.0
- List of modified principles:
  * Art. 2 · Preservación de Patrones y Compatibilidad Heredada: Removida regla de Swal.fire.
  * Art. 3 · Estándares de Calidad: Agregado DNI-based matching como estrategia primaria de cruce; actualizado estado FINALIZADO a valor 14 en BD.
  * Art. 7 · Límites (Las Tres Listas): Agregada regla de ignorar fechas duplicadas en ALWAYS DO y regla de procesar cabos sueltos guiados en NEVER DO. Removida la de Swal.fire.
- Added sections:
  * Flujo del Proceso de Cruce (paso 3 actualizado con DNI matching y paso 4.5 con memoria compartida)
-->

# Constitución del Proyecto Vonex

## Principios Fundamentales

### Art. 1 · Tareas pequeñas, una a la vez

- **Reglas**: Trabajar siempre en pasos de bebé (baby steps), uno a la vez. Nunca avanzar más de un paso a la vez. Asegurar que cada paso esté completamente verificado antes de continuar.
- **Justificación**: Mantiene los cambios manejables, reduce la complejidad de depuración y asegura la corrección del código.

### Art. 2 · Preservación de Patrones y Compatibilidad
- **Reglas**:
  - **Backend**: Seguir el patrón de clases de Acción (`app/Actions/`) con un único método público `execute()` que retorne un arreglo estructurado con `success` (booleano), `data` (modelo o colección) y `error` (mensaje/arreglo de error). Mantener controladores delgados, relaciones de Eloquent limpias y tipado estricto (`declare(strict_types=1);`). Compatibilidad estricta con PHP 8.4+.
  - **Frontend**: React (Vite) en arquitectura SPA con componentes funcionales y Hooks reactivos, consumiendo la API REST de Laravel.
- **Justificación**: Garantiza la legibilidad, mantenibilidad y alineación arquitectónica con el stack moderno del proyecto.

### Art. 3 · Estándares de Calidad

- **Reglas**:
  - **Integridad de Normalización**: Todo texto procesado desde el CSV crudo debe convertirse obligatoriamente a MAYÚSCULAS, sin tildes y con reemplazo estricto de la "Ñ" por "N". No se aceptan excepciones.
  - **Precisión del Cruce (Match por DNI y Nombre)**:
    - La estrategia primaria de cruce es por **DNI**: si el `codigo` del CSV coincide con `personas.dni` en la BD academia, la asociación es automática (O(1), cero falsos positivos).
    - Como fallback, la regla de validación de identidad es estricta: `2 apellidos exactos + 1 nombre exacto` (Cero Falsos Positivos).
    - Los registros que no coincidan de forma exacta (cabos sueltos) deben evaluarse buscando coincidencias o concurrencias similares (match difuso/fuzzy matching) para que el usuario pueda validarlos interactivamente antes de ser guardados.
  - **Prioridad Histórica Inmutable**: La resolución de estados duplicados debe regirse exclusivamente por la jerarquía definida: 1. MATRICULADO, 2. PAGADO, 3. FINALIZADO (valor BD: 14), 4. SUSPENDIDO, 5. RETIRADO, 6. TRASLADADO, 7. STAND BY, 8. ANULADO.
  - **Estándares de Codificación**: Los símbolos técnicos (clases, variables, métodos, comentarios de código) deben escribirse en inglés. Los términos de dominio (tablas, columnas de BD, reglas de negocio) e interfaz de usuario visibles deben estar en español.
  - **Reglas de Linting y Formateador**: Cumplimiento estricto del formateador de código del proyecto sin excepciones.
- **Justificación**: Garantiza precisión analítica absoluta en reportes sin perder la capacidad de capturar coincidencias por ligeras diferencias mediante validación asistida por el usuario.

### Art. 4 · Principios de Arquitectura

- **Reglas**:
  - **Pipeline sin intervención manual**: La orquestación del flujo de trabajo (lectura del CSV, separación por lotes y consultas a la base de datos de la academia) se gestionará mediante un script en PHP, eliminando manipulación manual o filtrado previo en hojas de cálculo.
  - **Centralización Analítica**: Los datos resultantes del cruce y enriquecimiento se descargarán en un archivo Excel final para su distribución; el pipeline interno no debe depender de hojas de cálculo manuales ni de archivos intermedios estáticos.
  - **Gestión de Errores Silenciosos**: Si se produce un timeout o error de conexión, el sistema debe pausar el lote y alertar. Los datos parcialmente procesados deben marcarse para revisión.
  - **Auditoría y trazabilidad**: Registrar cada lote, cada `Fecha de Examen`, el resultado del cruce y cualquier fallo para poder reconstruir el origen de las decisiones analíticas tomadas.
  - **Seguridad de credenciales**: Claves o secretos no se almacenan en el repositorio. Usar variables de entorno (`.env`).
  - **Pruebas automatizadas**: Cobertura de pruebas unitarias e integradas para la lógica de cruce y los endpoints. Las pruebas manuales con `curl` o el navegador MCP complementan, pero no reemplazan la validación.
  - **Integridad de Symlinks**: Los artefactos reutilizables en `ai-specs` deben estar referenciados mediante symlinks para que otros agentes (como `.claude` o `.cursor`) accedan consistentemente.
- **Justificación**: Claridad en la separación de responsabilidades, seguridad, robustez ante fallos de infraestructura y portabilidad del motor analítico.

### Art. 5 · Estándares de Lenguaje

- **Reglas**: Toda codificación técnica (variables, clases, funciones y commits) se escribe en inglés. Todo elemento visible al usuario y conceptos de negocio de base de datos se escriben en español.
- **Justificación**: Mantiene la profesionalidad del código y garantiza un sistema entendible para usuarios y administradores.

### Art. 6 · Portabilidad Multi-Agente

- **Reglas**: Mantener los archivos de especificaciones e instrucciones de los agentes en `ai-specs` como la fuente de verdad. Actualizar symlinks en los directorios de agentes específicos cuando cambien las rutas de archivos.
- **Justificación**: Asegura que cualquier asistente de IA trabaje con el mismo contexto unificado.

### Art. 7 · Límites (Las Tres Listas)

- **SIEMPRE HACER (ALWAYS DO)**:
  - Etiquetar cada registro entrante con su respectiva "Fecha de Examen" extraída automáticamente antes de insertarlo en la base de datos analítica.
  - Validar la conexión y autenticación con la base de datos de la academia antes de iniciar el procesamiento de cualquier lote.
  - Ignorar las fechas y registros ya cargados al procesar un nuevo archivo CSV para evitar duplicidades.
  - Realizar desarrollos en pasos cortos con entregas incrementales y frecuentes.
  - Retornar respuestas JSON desde controladores de API.
  - Probar manualmente endpoints mediante `curl` o navegador MCP antes de finalizar una iteración.
  - Mantener la documentación técnica actualizada.
- **PREGUNTAR PRIMERO (ASK FIRST)**:
  - Antes de alterar o expandir la lista de los 8 estados permitidos para el cruce.
  - Si la estructura de columnas del CSV de origen sufre alguna modificación.
  - Agregar nuevas dependencias a Composer o npm.
  - Modificar esquemas de bases de datos.
- **NUNCA HACER (NEVER DO)**:
  - Volver a la manipulación manual de datos o delegar el filtrado de fechas a la intervención humana.
  - Sobrescribir datos de días de examen anteriores al procesar un nuevo lote.
  - Guardar directamente coincidencias no exactas sin permitir al usuario revisarlas mediante la funcionalidad de validación de registros similares.
  - Escribir consultas SQL directas en vistas Blade.
  - Escribir lógica de negocio directamente en controladores.
- **Justificación**: Reglas de control estrictas para salvaguardar la calidad del código, evitar reprocesamientos y prevenir riesgos de seguridad.

## Flujo del Proceso de Cruce

1. **Conexión y Extracción**: El sistema se conecta a la base de datos `academia` para extraer los datos de los alumnos matriculados vigentes (`estado IN (2,3,9,13,14)`, `estado_aula = 1`). Los datos se cargan una sola vez por lote en un arreglo plano con índices de enteros para evitar duplicación de memoria.
2. **Carga de Archivo**: El usuario sube el archivo CSV de ingresantes a San Marcos.
3. **Cruce Inicial (Coincidencia Exacta por DNI y Nombre)**: Primero se intenta match por **DNI** (`codigo` CSV vs `personas.dni`). Si no hay coincidencia, se usa el matching por `2 apellidos exactos + 1 nombre exacto`. Los registros válidos se guardan automáticamente en la DB.
4. **Tratamiento de Cabos Sueltos (Match Intensivo/Difuso)**: Para los alumnos que no tuvieron match exacto, el sistema ejecuta pre-cheques por DNI y nombre exacto. Solo si ambos fallan realiza el scan Levenshtein completo. Los candidatos con ≥ 99.5% de similitud se auto-confirman. El resto se ofrece en interfaz React para validación manual asistida.
5. **Control de Cargas Futuras**: Al procesar una nueva carga, el sistema ignora las fechas de examen que ya fueron cargadas y procesadas previamente.

## Flujo de Trabajo Git y Colaboración

- **Rama `main` / `master`**: Producción estable. Solo se sube código verificado mediante pull requests.
- **Rama `develop`**: Entorno de desarrollo e integración.
- **Ramas de Características (`feature/`)**: Cada nueva funcionalidad o API se desarrolla en una rama dedicada (ej. `feature/alumno-matricula-api`).
- **Validaciones**: Antes de fusionar con `develop`, todo código debe pasar por revisiones de QA.
- **Integrantes y Funciones**:
  - **Samuel Cisneros**: Product Owner (PO) / Product Manager
  - **Renzo Fabián**: Tech Lead / Lead Developer
  - **Diego Fernando**: QA Tester / Co-Lead de Constitución
  - **Yerson Vargas**: QA / Apoyo Técnico

## Configuración y Ejecución de Pruebas

- **Configuración del Entorno**:
  - Backend: PHP (>= 8.4 local y en producción), Composer, PostgreSQL (Base de datos: `academia`), Servidor Laravel.
  - Wayfinder: `php artisan wayfinder:generate` debe ejecutarse al modificar rutas del backend.
- **Ejecución de Pruebas**:
  - Backend: `php artisan test` (Pest/PHPUnit).

## Gobernanza de la Constitución

- **Ratificación**: Esta constitución está ratificada por el equipo de desarrollo principal y es de cumplimiento obligatorio para programadores y agentes de IA.
- **Enmiendas**: Cualquier modificación requiere acuerdo del equipo, documentación de la enmienda, incremento de versión y propagación en plantillas.
- **Revisión de Cumplimiento**: Se verificará la adherencia en cada Pull Request y revisión de código.

**Versión**: 2.5.0 | **Ratificado**: 2026-06-16 | **Última Enmienda**: 2026-07-02
