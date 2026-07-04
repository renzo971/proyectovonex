Característica: Casos de borde, errores y resiliencia del motor de cruce
  El sistema debe manejar filas incompletas, formatos inválidos, fallos de conexión y errores de worker sin perder trazabilidad.

  @EC-001 @TC-020
  Escenario: Registrar error y continuar cuando una fila tiene nombre o apellido vacío
    Dado una fila CSV con los campos de nombres o apellidos vacíos
    Cuando el job de importación procesa el lote
    Entonces se registra un error en el log del lote con el número de fila afectada
    Y el procesamiento continúa con las demás filas válidas

  @EC-002 @ERR-001 @TC-021
  Escenario: Rechazar carga cuando faltan columnas requeridas en el CSV
    Dado un CSV sin las columnas obligatorias NOMBRES, OBSERVACION o FECHA
    Cuando se intenta subir el archivo por POST /api/cruce/upload
    Entonces la carga se rechaza con HTTP 422
    Y el mensaje indica las columnas faltantes

  @EC-003 @TC-022
  Escenario: Mantener lista vacía y exponer la opción de no ingresado cuando la similitud es menor al 30%
    Dado un ingresante cuya similitud máxima es menor al 30%
    Cuando se genera la lista de candidatos difusos
    Entonces la lista queda vacía
    Y la opción "Sin coincidencias encontradas — Marcar como No Ingresado" está disponible

  @EC-004 @TC-023
  Escenario: Ignorar registros de fechas ya procesadas y registrar la omisión
    Dado un CSV con una fecha de examen ya procesada en lotes_cruce
    Cuando se vuelve a subir el CSV
    Entonces los registros correspondientes a esa fecha se ignoran silenciosamente
    Y el log del lote registra la fecha omitida

  @EC-005 @TC-024
  Escenario: Limitar candidatos a 5 y desempatar por apellido paterno cuando hay igualdad de similitud
    Dado más de 5 alumnos con la misma similitud
    Cuando se ordenan los candidatos sugeridos
    Entonces se muestran solo los 5 primeros
    Y los empates se resuelven por apellido paterno alfabético

  @EC-006 @ERR-002 @TC-025
  Escenario: Rechazar CSV con codificación no soportada y mostrar error descriptivo
    Dado un archivo CSV codificado en UTF-16
    Cuando el sistema intenta procesarlo
    Entonces la carga se rechaza con HTTP 422
    Y el mensaje describe la codificación inválida

  @EC-007 @TC-026
  Escenario: Pausar el lote cuando la conexión a academia falla durante el cruce
    Dado la conexión a la base de datos academia falla durante el proceso
    Cuando RealizarCruceExactoAction se ejecuta
    Entonces el lote se marca como paused
    Y los registros ya procesados conservan su estado

  @ERR-005 @TC-032
  Escenario: Registrar job fallido en failed_jobs sin perder consistencia del lote
    Dado el worker Redis se reinicia durante el procesamiento de un job activo
    Cuando el job falla en ejecución
    Entonces el job aparece en failed_jobs
    Y el lote permanece consistente sin duplicar ni perder registros
