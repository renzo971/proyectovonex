Característica: Cruce exacto y fuzzy con la base de datos academia
  El motor valida la conexión a academia, realiza el match exacto y calcula candidatos difusos dentro del job batch.

  @US-002 @AC-005 @TC-007
  Escenario: Validar la conexión a academia antes de ejecutar consultas
    Dado la base de datos academia está configurada en el entorno
    Cuando la acción RealizarCruceExactoAction inicia el proceso de cruce
    Entonces el sistema valida la conexión antes de ejecutar cualquier consulta
    Y si la conexión falla, el proceso se aborta de forma controlada

  @US-002 @AC-006 @AC-007 @TC-008
  Escenario: Consultar alumnos en todos los estados válidos y resolver la jerarquía de prioridad
    Dado la base de datos academia contiene alumnos en los estados MATRICULADO, PAGADO, FINALIZADO, SUSPENDIDO, RETIRADO, TRASLADADO, STAND BY y ANULADO
    Cuando se ejecuta la extracción de alumnos para el cruce
    Entonces la consulta devuelve registros en todos esos estados válidos
    Y el estado prevalente se resuelve según la jerarquía MATRICULADO > PAGADO > FINALIZADO > SUSPENDIDO > RETIRADO > TRASLADADO > STAND BY > ANULADO

  @US-003 @AC-008 @TC-010
  Escenario: Asignar match exacto y estado confirmado_automatico cuando coinciden apellidos y un nombre
    Dado un ingresante normalizado cuyo apellido paterno, apellido materno y al menos un nombre coinciden con un registro de academia
    Cuando se ejecuta RealizarCruceExactoAction
    Entonces el ingresante recibe el alumno_id correspondiente
    Y su estado se actualiza a confirmado_automatico

  @US-003 @AC-009 @TC-011
  Escenario: Generar candidatos difusos ordenados con hasta 5 opciones
    Dado un ingresante pendiente que no obtiene match exacto
    Y existen varios candidatos en academia con diferentes niveles de similitud
    Cuando el motor calcula la similitud difusa dentro del job batch
    Entonces se genera una lista ordenada de mayor a menor probabilidad
    Y la lista contiene como máximo 5 candidatos

  @US-003 @AC-010 @TC-012
  Escenario: Dejar la lista vacía y exponer la opción de no ingresado cuando el mejor candidato no supera el 30%
    Dado un ingresante pendiente con similitud máxima menor al 30%
    Cuando se calcula la lista de candidatos
    Entonces la lista de candidatos queda vacía
    Y el sistema expone la opción "Sin coincidencias encontradas — Marcar como No Ingresado"

  @US-002 @ERR-003 @TC-026
  Escenario: Marcar el lote como paused cuando falla la conexión a academia
    Dado la conexión a academia no está disponible durante el cruce
    Cuando RealizarCruceExactoAction se ejecuta
    Entonces el proceso queda en un estado recuperable
    Y el lote se marca como paused sin perder registros ya procesados

  @NFR-001 @NFR-006 @TC-033
  Escenario: Procesar un lote grande en menos de 50 segundos con Redis activo
    Dado un CSV sintético de aproximadamente 27.000 filas
    Cuando el job de importación se ejecuta en Redis
    Entonces el lote queda en estado completado en menos de 50 segundos
