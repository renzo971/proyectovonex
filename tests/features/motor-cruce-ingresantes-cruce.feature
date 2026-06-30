Característica: Cruce con la base de datos Academia y resolución de coincidencias
  El motor consulta la base de datos Academia, valida la conexión, extrae estados y realiza coincidencias exactas y difusas.

  @US-002 @AC-005 @TC-005
  Escenario: Validar la conexión a la base de datos academia antes de ejecutar consultas
    Dado la base de datos academia está configurada en el entorno
    Cuando la acción RealizarCruceExactoAction inicia el proceso de cruce
    Entonces el sistema valida la conexión antes de ejecutar cualquier consulta
    Y si la conexión falla, el proceso se aborta limpiamente con un mensaje de error

  @US-002 @AC-005a @TC-005
  Escenario: Recuperar los campos exactos requeridos de la base de datos academia
    Dado la base de datos academia contiene registros de alumnos
    Cuando se consulta la tabla de alumnos desde el motor de cruce
    Entonces la respuesta incluye los campos dni_alumno, apellidos, nombres, anio, local, periodo, aula, fecha, cel_alumno, dni_responsable, cel_responsable, estado_matricula y fecha_registro

  @US-002 @AC-006 @TC-005
  Escenario: Traer registros en todos los estados válidos de academia sin filtrarlos en la extracción
    Dado la base de datos academia contiene alumnos en los estados MATRICULADO, PAGADO, FINALIZADO, SUSPENDIDO, RETIRADO, TRASLADADO, STAND BY y ANULADO
    Cuando se ejecuta la extracción de alumnos para el cruce
    Entonces la consulta devuelve registros en todos esos estados válidos

  @US-002 @AC-007 @TC-005
  Escenario: Resolver el estado de alumno histórico usando la jerarquía de prioridad definida
    Dado un alumno de academia tiene registros en los estados ANULADO, PAGADO y MATRICULADO
    Cuando se determina el estado prevalente para el reporte
    Entonces el estado resuelto es MATRICULADO

  @US-003 @AC-008 @TC-006
  Escenario: Asignar match exacto y estado confirmado_automatico cuando coinciden 2 apellidos y al menos 1 nombre
    Dado un ingresante normalizado cuyo apellido paterno, apellido materno y nombre coinciden con un registro de academia
    Cuando se ejecuta RealizarCruceExactoAction
    Entonces el ingresante recibe el alumno_id correspondiente
    Y su estado se actualiza a confirmado_automatico

  @US-003 @AC-009 @TC-007
  Escenario: Generar lista ordenada de hasta 5 candidatos basados en similitud difusa
    Dado un ingresante pendiente que no obtiene match exacto
    Y existen múltiples candidatos en academia con similitudes diferentes
    Cuando se calcula la lista de candidatos usando frecuencia de letras y Levenshtein
    Entonces se genera una lista ordenada de mayor a menor probabilidad
    Y la lista contiene como máximo 5 candidatos

  @US-003 @AC-010 @TC-008
  Escenario: Dejar la lista vacía y exponer "No Ingresado" cuando ningún candidato alcanza el umbral del 30%
    Dado un ingresante pendiente con similitud máxima menor al 30%
    Cuando se calcula la lista de candidatos
    Entonces la lista de candidatos queda vacía
    Y el sistema muestra la opción "Sin coincidencias encontradas — Marcar como No Ingresado"

  @US-002 @AC-005 @ERR-003 @TC-023
  Escenario: Abortar el cruce cuando la conexión a la base de datos academia no está disponible
    Dado la conexión a academia no está disponible
    Cuando RealizarCruceExactoAction se ejecuta
    Entonces el proceso falla limpiamente con mensaje de usuario
    Y el lote queda en estado paused

  @US-001 @AC-001d @ERR-007 @TC-027
  Escenario: Capturar job fallido y conservar consistencia de lote
    Dado el job ProcessCsvBatchJob lanza una excepción inesperada no recuperable
    Cuando el worker de Redis procesa el job
    Entonces el job aparece en failed_jobs
    Y el lote se marca con estado error
    Y no se pierden ni duplican registros ya insertados

  @US-001 @AC-001f @NFR-001 @TC-028
  Escenario: Procesar un CSV de ~27,000 filas en menos de 50 segundos
    Dado un CSV sintético de aproximadamente 27,000 filas
    Cuando el job de importación se ejecuta en Redis
    Entonces el lote queda en estado completado en menos de 50 segundos

  @US-001 @AC-001e @NFR-006 @TC-033
  Escenario: Soportar reinicio de worker Redis sin pérdida de datos
    Dado un worker Redis activo
    Y un ProcessCsvBatchJob encolado
    Cuando el worker se reinicia durante el procesamiento
    Entonces el job falla a failed_jobs
    Y el lote permanece consistente
    Y el procesamiento puede reintentarse
