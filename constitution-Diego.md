**Proyecto:** Motor de Cruce Automático de Ingresantes UNMSM
**Equipo:** Grupo V2 (Vonex) - Diego Fernando, Renzo Fabián, Samuel y Yerson

Este documento establece los principios no negociables y las reglas de juego para la implementación de la automatización del cruce de ingresantes. Estas reglas prevalecen sobre cualquier decisión de implementación futura.

## Art. 3 Quality Standards (Estándares de Calidad)
* **Integridad de Normalización:** Todo texto procesado desde el CSV crudo debe convertirse obligatoriamente a MAYÚSCULAS, sin tildes y con reemplazo estricto de la "Ñ" por "N". No se aceptan excepciones que rompan el motor de coincidencia.
* **Precisión del Cruce (Zero False Positives):** La regla de validación de identidad es estricta: `2 apellidos exactos + 1 nombre exacto`. No se permite la implementación de algoritmos de coincidencia difusa (fuzzy matching) para evitar falsos ingresos en el reporte.
* **Prioridad Histórica Inmutable:** La resolución de estados duplicados debe regirse exclusivamente por la jerarquía definida: 1. MATRICULADO, 2. PAGADO, 3. FINALIZADO, 4. SUSPENDIDO, 5. RETIRADO, 6. TRASLADADO, 7. STAND BY, 8. ANULADO.

## Art. 4 Architecture Principles (Principios de Arquitectura)
* **Zero-Touch Pipeline:** La orquestación del flujo de trabajo (lectura del CSV, separación por lotes y consultas a la API de Vonex) se gestionará mediante flujos automatizados en n8n, eliminando cualquier manipulación manual o filtrado previo en hojas de cálculo.
* **Centralización Analítica:** Los datos resultantes del cruce y enriquecimiento no se volcarán en archivos estáticos. Se enviarán directamente a BigQuery para mantener un registro histórico centralizado, permitiendo que la visualización final se consuma dinámicamente a través de dashboards interactivos (ej. Looker Studio).
* **Gestión de Errores Silenciosos:** Si la API de Vonex devuelve un timeout o error 5xx, el sistema debe pausar el lote y alertar. No se permite continuar el flujo ignorando errores de red, ya que generaría falsos negativos.

## Art. 7 Boundaries (Límites)
* **ALWAYS DO (Siempre hacer):** 
    * Etiquetar cada registro entrante con su respectiva "Fecha de Examen" extraída automáticamente antes de insertarlo en la base de datos analítica.
    * Validar la conexión y autenticación con la API interna de Vonex antes de iniciar el procesamiento iterativo de cualquier lote.
* **ASK FIRST (Preguntar primero):** 
    * Antes de alterar o expandir la lista de los 8 estados permitidos para el cruce.
    * Si la estructura de columnas del CSV de origen proveniente del scraping de San Marcos sufre alguna modificación.
* **NEVER DO (Nunca hacer):** 
    * Volver a la manipulación manual de datos o delegar el filtrado de fechas a la intervención humana.
    * Sobrescribir datos de días de examen anteriores al procesar un nuevo lote.