Característica: Interfaz de validación asistida para ingresantes pendientes
  El sistema muestra los candidatos sugeridos para cada ingresante pendiente y permite confirmar el match o marcar como no ingresado.

  @US-004 @AC-011 @TC-009
  Escenario: Mostrar en la interfaz los candidatos ordenados con porcentaje de similitud
    Dado un ingresante en estado pendiente con candidatos sugeridos
    Cuando el administrador visualiza la fila en la interfaz React
    Entonces la UI muestra el ingresante con sus datos normalizados
    Y el selector presenta candidatos ordenados por porcentaje de similitud
    Y cada candidato muestra el nombre completo y el porcentaje de similitud

  @US-004 @AC-012 @TC-009
  Escenario: Confirmar match manual y actualizar el estado a confirmado_manual
    Dado un ingresante pendiente y un candidato seleccionado en la UI
    Cuando el administrador presiona "Confirmar Match"
    Entonces se invoca GuardarCruceConfirmadoAction
    Y el estado del ingresante cambia a confirmado_manual
    Y los datos enriquecidos se actualizan en la base de datos analítica

  @US-004 @AC-013 @TC-010
  Escenario: Marcar un ingresante como no_ingresado cuando no hay candidato válido
    Dado un ingresante pendiente sin candidato válido
    Cuando el administrador selecciona "Sin coincidencias encontradas — Marcar como No Ingresado"
    Entonces el estado del ingresante cambia a no_ingresado
    Y la UI confirma la acción

  @US-004 @AC-004b @ERR-006 @TC-026
  Escenario: Manejar confirmación con alumno_id inválido
    Dado la interfaz envía un alumno_id inexistente
    Cuando se hace POST /api/cruce/ingresantes/{id}/confirmar
    Entonces la respuesta es HTTP 404
    Y el estado del ingresante no cambia

  @US-004 @AC-004a @NFR-002 @TC-029
  Escenario: Responder el endpoint de candidatos en menos de 300 ms p95
    Dado un ingresante pendiente con carga representativa de datos
    Cuando se consulta GET /api/cruce/ingresantes/{id}/candidatos
    Entonces la respuesta p95 es menor a 300 ms
