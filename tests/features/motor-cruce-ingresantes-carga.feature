Característica: Carga, normalización y filtrado de CSV del motor de cruce
  El sistema recibe el CSV oficial de ingresantes UNMSM, valida la entrada, normaliza los datos,
  elimina duplicados por código y enruta los registros a ingresantes o no_ingresantes mediante un job asíncrono.

  @US-001 @AC-001 @TC-001
  Escenario: Procesar solo los códigos nuevos y evitar duplicados por fecha previa
    Dado un administrador sube un CSV con registros de dos fechas de examen y códigos repetidos
    Y un código ya existe en las tablas ingresantes o no_ingresantes
    Cuando el sistema valida el archivo y despacha el job de importación
    Entonces solo se insertan los códigos nuevos
    Y los registros de fechas ya procesadas se ignoran sin crear duplicados

  @US-001 @AC-002 @TC-002
  Escenario: Normalizar texto completo a mayúsculas, sin tildes y con Ñ convertida a N
    Dado un registro del CSV contiene el valor "María Ñañez de la Cruz"
    Cuando se ejecuta la acción de normalización de texto
    Entonces el valor resultante es "MARIA NANEZ DE LA CRUZ"

  @US-001 @AC-003 @TC-003
  Escenario: Separar correctamente apellido paterno, apellido materno y nombres con apellidos compuestos
    Dado un nombre normalizado es "DE LA CRUZ GARCIA JUAN CARLOS"
    Cuando se procesa la cadena para dividir apellidos y nombres
    Entonces el apellido paterno es "DE LA CRUZ"
    Y el apellido materno es "GARCIA"
    Y los nombres son "JUAN CARLOS"

  @US-001 @AC-004 @TC-004
  Escenario: Enrutar registros según el valor normalizado de OBSERVACION
    Dado un CSV con una fila cuyo OBSERVACION normalizado es "ALCANZO VACANTE"
    Y otra fila cuyo OBSERVACION normalizado es "NO ALCANZO VACANTE"
    Cuando el job de importación procesa el lote
    Entonces la primera fila se persiste en la tabla ingresantes
    Y la segunda fila se persiste en la tabla no_ingresantes
    Y ambos registros comparten el mismo lote_cruce_id

  @US-001 @AC-004b @NFR-007 @TC-005
  Escenario: Sanitizar caracteres especiales y prefijos de inyección antes de persistir
    Dado un registro con valores que comienzan con "=", "+", "-" o "@"
    Cuando el sistema lo procesa para persistencia
    Entonces el valor se guarda de forma segura mediante ORM
    Y no se permite la ejecución de contenido malicioso

  @US-001 @NFR-001 @TC-006
  Escenario: Responder de inmediato con el lote_id y procesar en cola Redis
    Dado un CSV válido de carga masiva
    Cuando el administrador lo sube al sistema
    Entonces el endpoint responde inmediatamente con el lote_id
    Y el procesamiento continúa en background a través del job Redis
