Característica: Exportación de reporte Excel y análisis en Hoja 2
  El sistema genera un reporte consolidado en Excel con 24 columnas en Hoja 1 y gráficos analíticos en Hoja 2.

  @US-005 @AC-014 @TC-011
  Escenario: Generar Excel con 24 columnas en el orden exacto solicitado
    Dado un lote procesado con matches confirmados
    Cuando el administrador descarga el reporte Excel
    Entonces la Hoja 1 contiene exactamente 24 columnas en el orden A-X
    Y las columnas incluyen CODIGO, DNI, APELLIDOS, NOMBRES, EAP, PUNTAJE, MERITO, OBSERVACION, TIPO, MODALIDAD, UNIVERSIDAD, PERIODO, FECHA, ANIO, SEDE, CICLO, F-MATRICULA, CEL-ALUMNO, CEL-APODERADO, ESTADO, LISTA - 1, LISTA - 2, LISTA - 3 y AREA

  @US-005 @AC-015 @TC-012
  Escenario: Incluir gráficos analíticos y segmentadores dinámicos en la Hoja 2 del reporte Excel
    Dado un reporte Excel generado desde un lote procesado
    Cuando el usuario abre la Hoja 2
    Entonces se muestran gráficos de distribución por estado, sede y ciclo
    Y existen segmentadores dinámicos que filtran las métricas por fecha de examen

  @US-005 @AC-014 @TC-034
  Escenario: Mapear correctamente EAP a AREA académica en el reporte
    Dado diferentes carreras profesionales de UNMSM en el campo EAP
    Cuando se calcula la columna AREA en el reporte Excel
    Entonces MEDICINA HUMANA se mapea a Área A
    Y CIENCIAS BIOLOGICAS se mapea a Área B
    Y INGENIERIA DE SOFTWARE se mapea a Área C
    Y ADMINISTRACION se mapea a Área D
    Y DERECHO se mapea a Área E

  @US-005 @AC-014 @TC-035
  Escenario: Validar la estructura de 24 columnas del reporte final
    Dado un lote de cruce finalizado con alumnos coincidentes
    Cuando se genera y descarga el Excel consolidado
    Entonces el archivo contiene exactamente 24 columnas en el orden A-X
    Y los campos en la hoja coinciden con los datos esperados de la base de datos

  @US-005 @AC-014 @TC-036
  Escenario: Calcular LISTA - 1 correctamente para ciclos históricos
    Dado un alumno matriculado en el ciclo "Verano 2024"
    Cuando se exporta el reporte Excel
    Entonces LISTA - 1 es 1
    Y LISTA - 1 también es 1 para el ciclo "Verano 2025"
    Y LISTA - 1 es 0 para el ciclo "Anual 2023"

  @US-005 @AC-014 @TC-037
  Escenario: Calcular LISTA - 2 para ciclos de temporada y alumnos suspendidos o retirados
    Dado un alumno con ciclo "VERANO 2026" y estado "RETIRADO"
    Y otro alumno con ciclo "OCTUBRE 2025" y estado "SUSPENDIDO"
    Y otro alumno con ciclo "ANUAL 2025" y estado "MATRICULADO"
    Cuando se exporta el reporte Excel
    Entonces LISTA - 2 es 1 para los primeros dos alumnos
    Y LISTA - 2 es 0 para el alumno con ciclo "ANUAL 2025" y estado no activo a febrero 2026

  @US-005 @AC-014 @TC-038
  Escenario: Calcular LISTA - 3 para alumnos activos al 27 de febrero de 2026
    Dado un alumno con ciclo "Verano 2026" y estado "MATRICULADO" con fecha de matrícula anterior al 27/02/2026
    Cuando se exporta el reporte Excel
    Entonces LISTA - 3 es 1
    Y para un alumno en estado "RETIRADO" a la misma fecha, LISTA - 3 es 0
