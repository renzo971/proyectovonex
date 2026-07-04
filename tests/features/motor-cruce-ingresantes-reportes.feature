Característica: Exportación consolidada de reporte Excel
  El sistema genera un archivo Excel único con el contrato de columnas definido y enriquece la información solo al exportar.

  @US-005 @AC-014 @TC-016
  Escenario: Exigir selector de fecha o consolidado y exportar solo en formato Excel
    Dado un conjunto de lotes procesados
    Cuando el usuario solicita la descarga del reporte
    Entonces el sistema obliga a elegir entre una fecha específica o "Todas las fechas"
    Y solo permite descargar un archivo .xlsx

  @US-005 @AC-015 @TC-017
  Escenario: Generar un Excel con el contrato de columnas y datos enriquecidos
    Dado un lote con registros en estado confirmado_automatico o confirmado_manual
    Cuando se genera el reporte Excel
    Entonces la hoja contiene las columnas del CSV original en A-M
    Y a partir de la columna N incluye campos enriquecidos de academia y catálogo
    Y los campos sin match muestran "SIN MAPEAR"

  @US-006 @AC-017 @TC-018
  Escenario: Cargar catálogo con validación de Magic Bytes y upsert seguro
    Dado un archivo CSV del catálogo oficial con contenido válido
    Cuando el administrador lo sube al módulo independiente
    Entonces el sistema valida los Magic Bytes y sanitiza los campos
    Y actualiza la tabla catalogo_areas_carreras mediante upsert

  @US-006 @AC-018 @TC-019
  Escenario: Usar el catálogo exclusivamente en la exportación final y no en el pipeline de cruce
    Dado el pipeline de carga y cruce está en ejecución
    Cuando se evalúan los ingresantes o se calcula el fuzzy match
    Entonces el catálogo no se consulta ni se utiliza en ninguna etapa intermedia
    Y solo participa en ExportarExcelCruceAction
