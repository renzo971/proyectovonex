Característica: Casos de borde y errores del Motor de Cruce
  El sistema debe manejar condiciones atípicas de CSV, fallos de conexión y procesos asincrónicos sin perder consistencia.

  @EC-001 @TC-013
  Escenario: Continuar procesamiento y registrar error cuando hay nombre o apellido vacío en el CSV
    Dado una fila CSV con el campo NOMBRES vacío
    Cuando el job de importación procesa el lote
    Entonces se registra un error en el log del lote con el número de fila afectada
    Y el job continúa con las demás filas válidas

  @EC-002 @TC-014
  Escenario: Rechazar carga cuando faltan columnas requeridas en el CSV
    Dado un CSV faltando NOMBRES, OBSERVACION o FECHA
    Cuando se intenta subir el archivo por POST /api/cruce/upload
    Entonces la carga se rechaza con HTTP 422
    Y el mensaje indica las columnas faltantes

  @EC-003 @TC-015
  Escenario: Mantener lista vacía y exponer opción "No Ingresado" cuando la similitud es menor al 30%
    Dado un ingresante cuya similitud máxima es menor al 30%
    Cuando se genera la lista de candidatos difusos
    Entonces la lista queda vacía
    Y la opción "Sin coincidencias encontradas — Marcar como No Ingresado" está disponible

  @EC-004 @TC-016
  Escenario: Ignorar registros de fechas ya procesadas y registrar el salto
    Dado un CSV con una fecha de examen ya procesada en lotes_cruce
    Cuando se vuelve a subir el CSV
    Entonces los registros correspondientes a esa fecha se ignoran silenciosamente
    Y el log del lote registra la fecha omitida

  @EC-005 @TC-017
  Escenario: Limitar candidatos a 5 y desempatar por apellido paterno cuando hay igualdad de similitud
    Dado más de 5 alumnos con similitud igual
    Cuando se ordenan los candidatos sugeridos
    Entonces se muestran solo los 5 primeros
    Y los empates se desempatan por apellido paterno alfabético

  @EC-006 @TC-018
  Escenario: Rechazar CSV con codificación no soportada y mostrar error descriptivo
    Dado un archivo CSV codificado en UTF-16
    Cuando el sistema intenta procesarlo
    Entonces la carga se rechaza con HTTP 422
    Y el mensaje describe la codificación inválida

  @EC-007 @TC-019
  Escenario: Pausar lote y dejar registros pendientes cuando falla la conexión a academia
    Dado la conexión a la base de datos academia falla durante el proceso
    Cuando RealizarCruceExactoAction se ejecuta
    Entonces el lote se marca como paused
    Y los registros ya procesados conservan su estado
    Y los registros no procesados quedan en pendiente para reintento

  @EC-008 @TC-020
  Escenario: Registrar job fallido en failed_jobs sin perder consistencia de lote
    Dado el worker Redis reinicia durante el procesamiento de un job activo
    Cuando el job falla en ejecución
    Entonces el job aparece en failed_jobs
    Y el lote permanece en estado procesando o error sin duplicar ni perder registros
