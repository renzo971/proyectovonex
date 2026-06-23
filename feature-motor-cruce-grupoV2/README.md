# 🚀 Entregable Taller 2: Motor de Cruce Automático de Ingresantes UNMSM

## 👥 Miembros del Equipo - Grupo V2 (Vonex)

| Integrante | Rol en el Taller | Especialidad / Función Principal |
| :--- | :--- | :--- |
| **Samuel Cisneros** | Product Owner (PO) | Definición de requerimientos, análisis de negocio y dirección de producto. |
| **Renzo Fabián** | Tech Lead | Desarrollo de arquitectura frontend y backend, integraciones y lógica de negocio. |
| **Diego Fernando** | QA Tester | Control de calidad, diseño y ejecución de planes de pruebas y soporte técnico. |
| **Yerson Vargas** | QA / Apoyo | Soporte de infraestructura, pruebas funcionales y asistencia en control de calidad. |

---

## 📈 Matriz de Cobertura (Coverage Matrix - §2.7)

Esta matriz mapea cada criterio de aceptación y caso de borde definido en `spec.md` con su respectiva sección en `plan.md` y su caso de prueba en `test-cases.md`.

| Requisito (US / AC / Borde) | ¿Está en el Plan? | ¿Tiene Caso de Prueba? | Estado |
| :--- | :--- | :--- | :---: |
| **US-1 / AC-1.1** (Carga y Lotes) | Sí $\rightarrow$ Paso 2 (`ProcesarCargaCsvAction`) | [TC-1](test-cases.md#L13-L17) | ✅ |
| **US-1 / AC-1.2** (Normalización) | Sí $\rightarrow$ Paso 2 (`NormalizarTextoAction`) | [TC-2](test-cases.md#L19-L23) | ✅ |
| **US-1 / AC-1.3** (Apellidos compuestos) | Sí $\rightarrow$ Paso 2 (`NormalizarTextoAction`) | [TC-2](test-cases.md#L19-L23) | ✅ |
| **US-1 / AC-1.4** (Filtrado de vacante) | Sí $\rightarrow$ Paso 2 (`ProcesarCargaCsvAction`) | [TC-8](test-cases.md#L62-L66) | ✅ |
| **US-2 / AC-2.1** (Conexión directa DB) | Sí $\rightarrow$ Paso 3 (`RealizarCruceExactoAction`) | [TC-4](test-cases.md#L34-L38) | ✅ |
| **US-2 / AC-2.2** (Prioridad de estados) | Sí $\rightarrow$ Paso 3 (`RealizarCruceExactoAction`) | [TC-5](test-cases.md#L40-L44) y [TC-6](test-cases.md#L46-L50) | ✅ |
| **US-3 / AC-3.1** (Match Exacto) | Sí $\rightarrow$ Paso 3 (`RealizarCruceExactoAction`) | [TC-3](test-cases.md#L25-L32) | ✅ |
| **US-3 / AC-3.2** (Fuzzy / Cabos sueltos) | Sí $\rightarrow$ Paso 4 (`CalcularSimilitudesCabosAction`) | [TC-9](test-cases.md#L68-L79) | ✅ |
| **US-4 / AC-4.1** (React `<select>`) | Sí $\rightarrow$ Paso 5 (Interfaz Web React) | [TC-10](test-cases.md#L81-L86) | ✅ |
| **US-4 / AC-4.2** (Confirmación manual) | Sí $\rightarrow$ Paso 5 (`GuardarCruceConfirmadoAction`) | [TC-10](test-cases.md#L81-L86) | ✅ |
| **US-5 / AC-5.1** (Hoja Excel - Data) | Sí $\rightarrow$ Paso 6 (`ExportarExcelCruceAction`) | [TC-7](test-cases.md#L52-L60) | ✅ |
| **US-5 / AC-5.2** (Hoja Excel - Dashboard) | Sí $\rightarrow$ Paso 6 (`ExportarExcelCruceAction`) | [TC-7](test-cases.md#L52-L60) | ✅ |
| **CB-1** (Campos Vacíos en CSV) | Sí $\rightarrow$ Paso 2 (`ProcesarCargaCsvAction`) | [TC-11](test-cases.md#L88-L92) | ✅ |
| **CB-2** (Columnas Incorrectas) | Sí $\rightarrow$ Paso 2 (`ProcesarCargaCsvAction`) | [TC-12](test-cases.md#L94-L98) | ✅ |
| **CB-3** (Sin Candidatos Sugeridos) | Sí $\rightarrow$ Paso 4 (`CalcularSimilitudesCabosAction`) | [CB-3](spec.md#L65) | ✅ |

---

## 🚦 Veredicto del Gate de Claridad (§2.8 & §6)

**Grupo Evaluador:** Grupo V2 (Vonex)  
**Grupo Evaluado (Otro Grupo):** Grupo V1 (Sistema de Asignación de Aulas)

Sometimos a revisión la especificación funcional (`spec.md`) del **Grupo V1** bajo las 4 categorías de claridad técnica:

1. **Completitud [🟡 Observado]:** Las historias de usuario (US) describen bien el flujo feliz de asignación, pero omiten definir qué ocurre cuando el volumen de alumnos excede la capacidad física del aula por un margen menor (ej. 1 o 2 alumnos sobrantes).
2. **Claridad [✓ Aprobado]:** Se eliminaron adjetivos ambiguos. La capacidad de asignación y las restricciones se definen con variables numéricas claras.
3. **Consistencia [✓ Aprobado]:** La terminología técnica de asignaciones y turnos se mantiene uniforme en todos los artefactos de diseño presentados.
4. **Testabilidad [🟡 Observado]:** Faltan datos específicos o ejemplos en los criterios de aceptación para validar el comportamiento del algoritmo heurístico bajo condiciones de empate de prioridades de horarios.

### **Faltante Crítico Detectado:**
Falta definir el requisito no funcional (**NFR**) del tiempo de respuesta máximo para el endpoint de asignación en tiempo real cuando se consultan múltiples facultades simultáneamente.

### **Veredicto:** 🟡 **APROBADO CON OBSERVACIONES**
*El Grupo V1 puede avanzar a la fase de diseño siempre que subsane la definición del NFR de rendimiento y el criterio de desempate de prioridades.*

