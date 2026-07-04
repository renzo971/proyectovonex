Característica: Interfaz de validación asistida para ingresantes pendientes
  El sistema muestra los candidatos sugeridos para cada ingresante pendiente y permite confirmar el match o marcarlo como no ingresado.

  @US-004 @AC-011 @TC-013
  Escenario: Mostrar un pending row con placeholder, datos del CSV y candidatos ordenados
    Dado un ingresante en estado pendiente con candidatos sugeridos
    Cuando el administrador visualiza la fila en la interfaz React
    Entonces se muestra el apellido paterno, materno, nombres, fecha de examen y el selector de candidatos
    Y el selector inicia con un placeholder no seleccionable
    Y los candidatos aparecen ordenados por porcentaje de similitud

  @US-004 @AC-012 @TC-014
  Escenario: Confirmar match manual y actualizar el estado y los datos enriquecidos
    Dado un ingresante pendiente y un candidato seleccionado en la UI
    Cuando el administrador presiona "Confirmar Match"
    Entonces se invoca GuardarCruceConfirmadoAction
    Y el estado del ingresante cambia a confirmado_manual
    Y los datos enriquecidos se actualizan en la base de datos analítica

  @US-004 @AC-013 @TC-015
  Escenario: Marcar un ingresante como no_ingresado cuando no hay candidato válido
    Dado un ingresante pendiente sin candidato válido
    Cuando el administrador selecciona "Sin coincidencias encontradas — Marcar como No Ingresado"
    Entonces el estado del ingresante cambia a no_ingresado
    Y la interfaz refleja la decisión mediante feedback visual

  @US-004 @AC-011 @TC-024
  Escenario: Mostrar solo los pendientes con coincidencia máxima igual o superior al 70%
    Dado un ingresante con similitud máxima de 69% y otro con 70%
    Cuando la bandeja de pendientes se carga en la interfaz
    Entonces solo el ingresante con similitud igual o mayor a 70% aparece en la lista

  @NFR-002 @TC-034
  Escenario: Responder el endpoint de candidatos en menos de 300 ms p95
    Dado un ingresante pendiente con carga representativa de datos
    Cuando se consulta GET /api/cruce/ingresantes/{id}/candidatos
    Entonces la respuesta p95 es menor a 300 ms
