Característica: Carga y normalización de CSV del Motor de Cruce
  El sistema recibe el CSV oficial de ingresantes UNMSM, valida columnas, normaliza texto,
  elimina duplicados y enruta los registros a `ingresantes` o `no_ingresantes`.

  @US-001 @AC-001 @TC-001
  Escenario: Procesar un CSV con múltiples fechas de examen, eliminar duplicados e ignorar fechas ya procesadas
    Dado un administrador sube un CSV válido con registros de dos fechas de examen y filas idénticas duplicadas
    Y la fecha de examen "2026-05-10" ya existe en el historial de lotes procesados
    Cuando el sistema valida el archivo y despacha el job de importación
    Entonces se crean lotes independientes por fecha de examen
    Y el lote con fecha "2026-05-10" se ignora silenciosamente
    Y las filas duplicadas dentro de la misma fecha se eliminan antes de persistir

  @US-001 @AC-001a @TC-014
  Escenario: Rechazar la carga si el CSV no contiene exactamente las 12 columnas requeridas
    Dado un administrador sube un CSV con columnas incorrectas o ausentes
    Cuando el sistema valida la cabecera del archivo
    Entonces la carga se rechaza con HTTP 422
    Y el mensaje indica qué columnas faltan o están mal nombradas

  @US-001 @AC-002 @TC-002
  Escenario: Normalizar texto a MAYÚSCULAS, eliminar tildes y convertir "Ñ" a "N"
    Dado un registro del CSV contiene el valor "María Ñañez de la Cruz" en el campo de nombres
    Cuando se ejecuta la acción de normalización de texto
    Entonces el valor resultante es "MARIA NANEZ DE LA CRUZ"

  @US-001 @AC-003 @TC-003
  Escenario: Separar correctamente apellido paterno, apellido materno y nombres con apellidos compuestos
    Dado un nombre normalizado es "DE LA CRUZ GARCIA JUAN CARLOS"
    Cuando se procesa la cadena para dividir apellidos y nombres
    Entonces el apellido paterno es "DE LA CRUZ"
    Y el apellido materno es "GARCIA"
    Y el nombre es "JUAN CARLOS"

  @US-001 @AC-004 @TC-004
  Escenario: Filtrar OBSERVACION normalizada y enrutar registros a ingresantes o no_ingresantes
    Dado un CSV con una fila cuyo OBSERVACION normalizado es "ALCANZO VACANTE"
    Y otra fila cuyo OBSERVACION normalizado es "NO ALCANZO VACANTE"
    Cuando el job de importación procesa el lote
    Entonces la primera fila se persiste en la tabla ingresantes
    Y la segunda fila se persiste en la tabla no_ingresantes
    Y ambos registros comparten el mismo lote_cruce_id

  @US-001 @AC-001a @ERR-001 @TC-021
  Escenario: Rechazar carga cuando las columnas requeridas tienen nombres incorrectos
    Dado un CSV que contiene 12 columnas con nombres incorrectos
    Cuando se hace POST /api/cruce/upload
    Entonces la carga se rechaza con HTTP 422
    Y el mensaje lista las columnas incorrectas o faltantes
    Y no se crea ningún registro en la base de datos

  @US-001 @AC-001b @ERR-002 @TC-022
  Escenario: Rechazar carga cuando el archivo CSV no está en codificación soportada
    Dado un CSV codificado en UTF-16
    Cuando el sistema recibe el archivo para la importación
    Entonces la carga se rechaza con HTTP 422
    Y el mensaje indica que la codificación no es soportada

  @US-001 @AC-004 @ERR-004 @TC-024
  Escenario: Rechazar carga cuando no hay registros con OBSERVACION=ALCANZO VACANTE
    Dado un CSV donde ninguna fila tiene OBSERVACION=ALCANZO VACANTE
    Cuando se procesa el lote de importación
    Entonces la carga se rechaza con HTTP 422
    Y se informa que no hay registros válidos para procesar

  @US-001 @AC-001c @ERR-005 @TC-025
  Escenario: Rechazar carga de archivo demasiado grande
    Dado un archivo CSV de 21 MB
    Cuando se intenta subir el archivo al endpoint de carga
    Entonces la respuesta es HTTP 413
    Y el mensaje indica que el tamaño excede el límite de 20 MB

  @US-001 @AC-001c @NFR-003 @TC-030
  Escenario: Permitir la subida de un CSV de 20 MB sin errores de memoria
    Dado un archivo CSV válido de 20 MB
    Cuando se sube el archivo al endpoint de carga
    Entonces la respuesta HTTP es exitosa
    Y el job se encola sin error de memoria
