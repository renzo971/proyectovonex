# Evaluación detallada · V2 · Vonex — Motor de Cruce Automático de Ingresantes UNMSM

> Insumo de evaluación asistida por IA (§16.7). CONFIDENCIAL. Cada puntaje va con cita textual.
> Repo: `proyectovonex` · Ruta: `feature-motor-cruce-grupoV2/`

## Integrantes (según README del grupo)
- **Samuel Cisneros** — *Product Owner (PO)*
- **Renzo Fabián** — *Tech Lead*
- **Diego Fernando** — *QA Tester*
- **Yerson Vargas** — *QA / Apoyo*
> ⚠ Roles contradictorios entre artefactos (README vs spec vs constitution) — ver §Coherencia.

## Tabla de criterios

| # | Criterio | Pts | Evidencia citada | Qué falta / por qué no más |
|---|----------|-----|------------------|----------------------------|
| B1 | Resumen ejecutivo en cada artefacto | **5/5** | spec L7-9 "El motor de cruce automatiza la validación…"; plan L5-6 "Este plan define la implementación técnica…"; test L7-9 "Este documento define los casos de prueba…". Los tres ≤150 pal. autoexplicativos. | Cumple en spec+plan+test. |
| B2 | User stories + AC en GWT verificables | **14/14** | 5 US; AC-1.2 "cuando se normaliza… entonces se convierte todo a MAYÚSCULAS, se eliminan las tildes y se reemplaza 'Ñ' por 'N'"; AC-2.2 jerarquía de 8 estados; AC-3.1 "2 apellidos y al menos 1 nombre… `confirmado_automatico`". | US-2 redacta a "el sistema" como actor (menor), pero los AC son verificables. No baja de 14. |
| B3 | Assumptions + [NEEDS_CLARIFICATION] (máx 3) | **4/8** | §5 dos supuestos ("El formato de codificación del CSV es siempre UTF-8 o ISO-8859-1…"; "La base de datos `academia` tiene índices…"). §6 una duda: "[NC-1] ¿El filtrado por… `ALCANZO VACANTE`… debe ser estrictamente exacto…?". | Los supuestos NO declaran consecuencia si resultan falsos. Hay supuestos ocultos sin marcar (umbral 30% de CB-3, top-5 candidatos). Nivel inferior. |
| B4 | Scope con "FUERA" explícito | **6/6** | §7 DENTRO (5 ítems) y "FUERA (explícito): Descarga automática o scraping… Sincronización del estado del alumno en la base de datos original…". | Cumple. |
| B5 | Calidad PROSE | **5/5** | NFR-1 "10,000 registros… en menos de 5 segundos"; NFR-2 "menos de 300 ms"; NFR-3 "hasta 20 MB"; CB-3 "similitud superior al 30%"; AC-5.1 "columnas A hasta M… de la N en adelante". | Preciso y observable. |
| B6 | Enfoque + componentes nombrados | **7/7** | plan §1 enfoque (Acciones Laravel + lote PostgreSQL + fuzzy + API React); §2 árbol con archivos: `ProcesarCargaCsvAction.php`, `CalcularSimilitudesCabosAction.php`, `IngresanteCruce.php`, `UnmatchedRow.jsx`, `api.js`. | Específico. |
| B7 | Mini-ADR con alternativa descartada | **9/9** | plan §3: DECISIÓN "Separar… clases de Acción" + POR QUÉ + "ALTERNATIVA DESCARTADA: lógica en `CruceIngresantesController`… infla el controlador". Segundo ADR: dos fases vs "auto-match difuso con umbral alto… riesgo de emparejar alumnos distintos". | Dos ADR completos. |
| B8 | Casos con datos, pasos y resultado esperado | **6/10** | TC-2 "`De la Cruz Muñoz, María-José`" → "`Apellido 1: DE LA CRUZ`, `Apellido 2: MUNOZ`"; TC-3 `CASTILLO TORIBIO DIEGO` vs `…DIEGO FERNANDO SEBASTIAN`; TC-5 estados. | NO cubre todos los AC: AC-3.2 (fuzzy/ranking) y AC-4.1/4.2 (interfaz React) sin TC con datos — en README aparecen como "Verificación de UI". TC-7 "Dashboard se carga correctamente" es vago. Nivel intermedio. |
| B9 | Cobertura feliz + error + borde | **6/6** | Feliz TC-1/2/3/7/8. Error TC-4 "pérdida de conexión… el flujo se detiene"; TC-6 "estado 'DEUDOR EXCLUIDO'… ignora el cruce". Borde TC-5 "desempate por jerarquía". | Los tres tipos. |
| B10 | Constitution: 2-3 artículos accionables, criterio humano, sin IA | **8/8** | Art. 3 "Precisión del Cruce… `2 apellidos exactos + 1 nombre exacto` (Cero Falsos Positivos)"; Art. 7 NEVER DO "Sobrescribir datos de días de examen anteriores"; ASK FIRST "Antes de alterar… los 8 estados permitidos". | Sync Impact Report y versión 1.1.0; reglas reales del negocio, no boilerplate. |
| B11 | Coverage matrix req→plan→prueba + huecos/scope creep | **3/6** | README §"Matriz de Cobertura": 12 filas AC→Paso plan→TC; "US-3/AC-3.2 → Paso 4 → CB-3". | Marca TODO ✅ sin reconocer huecos: AC-4.1/4.2 sin TC (rotulados "Verificación de UI" pero ✅), y CB-1/CB-2 del spec NO aparecen como filas. Incompleta. |
| B12 | Gate de claridad a OTRO grupo: 4 cat. + veredicto + faltante | **3/6** | README §"Veredicto del Gate de Claridad", "Grupo revisor: Grupo V1", 4 categorías + "🟢 TODO PASA". | Es auto-revisión, no revisión a otro grupo: las 4 categorías describen el PROPIO spec del V2 (cita sus NFR, sus CB-1 a CB-3). No nombra nada faltante. Parcial. |
| B13 | Trazabilidad git: commits incrementales narrados | **2/10** | 4 commits, pero 914b506 "docs: mejora de los docs añadiendo las instrucciones del pdf" crea los 5 artefactos de golpe (+407 líneas). Los otros 3 son retoques (Cambio de nombres, coreccion del stack, grupo revisor del gate). | Commit-volcado inicial + tres parches cosméticos. No narra el refinamiento spec→plan→test. Mensajes pobres ("coreccion"). |

## Base: 78/100
Spec 34 (5+14+4+6+5) · Plan 16 · Test 12 (6+6) · Constitution 8 · Gates 6 (3+3) · Proceso 2

## Valor agregado: +2/10
- **+1** — Constitution con Sync Impact Report versionado (1.0.0→1.1.0) documentando principios modificados/agregados (constitution L1-16, §2.8/§6).
- **+1** — Trazabilidad explícita US→plan dentro del plan.md (§5, L61-67).
- No premio: longitud, árbol de archivos ni los 8 estados (ya contados en base). No hay tasks.md con T-XXX ni cadena completa US→AC→TC→T.

## Mérito final: 78 + 2 = 80/110 · Veredicto base 🟡
> Nota: la base (78) es 🟡; el bonus suma al puntaje pero NO cambia la banda cualitativa.

## Coherencia entre artefactos
- **US sin prueba (incoherencia real):** US-4 (AC-4.1/4.2, interfaz React) NO tiene TC; el README lo declara "Verificación de UI" pero no existe caso. AC-3.2 (fuzzy/ranking de 5 candidatos) tampoco tiene TC propio; el README lo mapea a CB-3, que solo prueba "sin candidatos".
- Casos borde CB-1 (campos vacíos) y CB-2 (columnas faltantes) en spec §4 sin TC ni fila en matriz.
- **Roles contradictorios:** README dice Diego Fernando = "QA Tester" y Samuel Cisneros = "PO"; spec L3 dice "PO: Diego Fernando"; constitution L105-107 dice Diego = "QA/Co-Lead", Samuel = "PO". Los tres artefactos asignan roles distintos.
- Versionado desalineado: spec/test "2.2.0", constitution "1.1.0", plan sin versión.
- **Rutas con fuga de entorno local:** plan L3 y README enlazan `file:///c:/Users/rsantos_vonex/develop/...` (ruta Windows), no rutas relativas del repo.

## 3 mejoras priorizadas
- **P1 (bloqueante):** TC reales con datos para AC-3.2 (ranking fuzzy top-5) y AC-4.1/4.2 (UI React) + CB-1/CB-2; matriz que deje de ocultar huecos (§2.7).
- **P2:** rehacer el gate como revisión genuina a otro grupo, nombrando ≥1 faltante real en vez de "🟢 TODO PASA".
- **P3:** unificar roles, versión y rutas (quitar `file:///c:/Users/rsantos_vonex/...`); declarar consecuencia de cada supuesto y marcar los ocultos (umbral 30%, top-5).

## Sustentación (sorteo, /20)
⬜ Pendiente — completar con transcripción.
