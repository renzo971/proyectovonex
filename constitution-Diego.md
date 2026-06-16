**Proyecto:** Motor de Cruce Automático de Ingresantes UNMSM
**Equipo:** Grupo V2 (Vonex) - Diego Fernando, Renzo Fabián, Samuel y Yerson

Este documento establece los principios no negociables y las reglas de juego para la implementación de la automatización del cruce de ingresantes. Estas reglas prevalecen sobre cualquier decisión de implementación futura.

## Art. 3 Quality Standards (Estándares de Calidad)
* **Integridad de Normalización:** Todo texto procesado desde el CSV crudo debe convertirse obligatoriamente a MAYÚSCULAS, sin tildes y con reemplazo estricto de la "Ñ" por "N". No se aceptan excepciones que rompan el motor de coincidencia.
* **Precisión del Cruce (Zero False Positives):** La regla de validación de identidad es estricta: `2 apellidos exactos + 1 nombre exacto`. No se permite la implementación de algoritmos de coincidencia difusa (fuzzy matching) para evitar falsos ingresos en el reporte.
* **Prioridad Histórica Inmutable:** La resolución de estados duplicados debe regirse exclusivamente por la jerarquía definida: 1. MATRICULADO, 2. PAGADO, 3. FINALIZADO, 4. SUSPENDIDO, 5. RETIRADO, 6. TRASLADADO, 7. STAND BY, 8. ANULADO.

## Art. 4 Architecture Principles (Principios de Arquitectura)
* **Pipeline sin intervención manual:** La orquestación del flujo de trabajo (lectura del CSV, separación por lotes y consultas a la API de Vonex) se gestionará mediante un script en PHP, eliminando cualquier manipulación manual o filtrado previo en hojas de cálculo.
* **Centralización Analítica:** Los datos resultantes del cruce y enriquecimiento no se volcarán en archivos estáticos. Se descargarán en un archivo Excel final para distribución y archivo; el pipeline interno no debe depender de hojas de cálculo manuales ni de archivos intermedios estáticos.
* **Gestión de Errores Silenciosos:** Si la API de Vonex devuelve un timeout o error 5xx, el sistema debe pausar el lote y alertar. No se permite continuar el flujo ignorando errores de red, ya que generaría falsos negativos.
* **Manejo de errores y reintentos:** Definir canales de alerta claros y una política de reintentos o abortos. Un lote pausado no debe reanudarse automáticamente sin validación, y los datos parcialmente procesados deben marcarse para revisión.
* **Auditoría y trazabilidad:** Registrar cada lote, cada `Fecha de Examen`, el resultado del cruce, y cualquier fallo. Los logs deben permitir reconstruir qué datos entraron, qué decisiones se tomaron y cuándo.
* **Seguridad de credenciales:** Las claves o tokens de Vonex y otros secretos no deben almacenarse en el repositorio. Usar variables de entorno o un gestor de secretos aprobado.
* **Pruebas automatizadas:** Debe existir cobertura de pruebas unitarias e integradas para la lógica de cruce y los endpoints de la API. Las pruebas manuales con `curl` o el navegador MCP complementan, pero no reemplazan, la validación automatizada.
* **Control de cambios:** Cualquier cambio en dependencias, esquema de datos, rutas o estructura de carpetas debe documentarse y revisarse antes de su despliegue.
* **Definiciones operativas:** Antes de implementar un flujo nuevo, definir claramente qué se entiende por “lote”, “registro entrante”, “fecha de examen” y la estructura esperada del CSV de origen.

* **Reglas de Desarrollo:**
    * **Separación jerárquica:** Controlador (validación HTTP, formateo de respuesta) -> Acción (unidad de lógica de negocio, interacción con BD) -> Modelos Eloquent (mapeo de datos, relaciones).
    * **No consultas DB en vistas / Controladores delgados:** No consultas directas a la base de datos en vistas. Controladores delgados; la lógica de negocio nunca debe residir en controladores.
    * **Integridad de symlinks:** Los artefactos reutilizables dentro de `ai-specs` deben estar referenciados mediante symlinks para que otros agentes (por ejemplo `.claude`, `.cursor`) puedan accederlos de forma consistente.
    * **Justificación:** Claridad en la separación de responsabilidades, cumplimiento de DRY y portabilidad entre agentes para facilitar reutilización y auditoría.

## Art. 7 Boundaries (Límites)
* **ALWAYS DO (Siempre hacer):** 
    * Etiquetar cada registro entrante con su respectiva "Fecha de Examen" extraída automáticamente antes de insertarlo en la base de datos analítica.
    * Validar la conexión y autenticación con la API interna de Vonex antes de iniciar el procesamiento iterativo de cualquier lote.
    * **Ciclos pequeños y entregas incrementales:** Desarrollar en pasos pequeños con entregas parciales frecuentes y verificaciones continuas.
    * **Tipado estricto en PHP:** Usar `declare(strict_types=1);` en los scripts PHP.
    * **Endpoints de API en JSON:** Los controladores de API deben devolver siempre respuestas JSON.
    * **Pruebas manuales de endpoints:** Probar manualmente los endpoints con `curl` o el navegador MCP antes de dar por finalizada una iteración.
    * **Mantener la documentación actualizada:** Mantener la documentación actualizada junto con los cambios del código.
* **ASK FIRST (Preguntar primero):** 
    * Antes de alterar o expandir la lista de los 8 estados permitidos para el cruce.
    * Si la estructura de columnas del CSV de origen proveniente del scraping de San Marcos sufre alguna modificación.
    * Añadir nuevas dependencias (npm/composer).
    * Cambiar el esquema de la base de datos (migraciones).
    * Cambiar rutas principales o la estructura de directorios.
    * Degradar o promover reglas de la constitución.
* **NEVER DO (Nunca hacer):** 
    * Volver a la manipulación manual de datos o delegar el filtrado de fechas a la intervención humana.
    * Sobrescribir datos de días de examen anteriores al procesar un nuevo lote.
    * Escribir consultas directas a la base de datos en vistas Blade.
    * Escribir lógica de negocio directamente en controladores.
    * Usar `alert()` o `confirm()` nativos.
    * Usar características de PHP 8+ en archivos legacy compatibles con PHP 7.1+.
    * Omitir pruebas manuales o verificación de base de datos.
