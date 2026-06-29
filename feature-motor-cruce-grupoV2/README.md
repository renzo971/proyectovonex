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
| **US-3 / AC-3.2** (Fuzzy / Cabos sueltos) | Sí $\rightarrow$ Paso 4 (`CalcularSimilitudesCabosAction`) | [TC-9](test-cases.md#L68-L80) | ✅ |
| **US-4 / AC-4.1** (React `<select>`) | Sí $\rightarrow$ Paso 5 (Interfaz Web React) | [TC-10](test-cases.md#L82-L87) | ✅ |
| **US-4 / AC-4.2** (Confirmación manual) | Sí $\rightarrow$ Paso 5 (`GuardarCruceConfirmadoAction`) | [TC-10](test-cases.md#L82-L87) | ✅ |
| **US-5 / AC-14** (Hoja Excel - Data) | Sí $\rightarrow$ Paso 6 (`ExportarExcelCruceAction`) | [TC-7](test-cases.md#L52-L61) | ✅ |
| **US-5 / AC-15** (Hoja Excel - Dashboard) | Sí $\rightarrow$ Paso 6 (`ExportarExcelCruceAction`) | [TC-7](test-cases.md#L52-L61) | ✅ |
| **CB-1** (Campos Vacíos en CSV) | Sí $\rightarrow$ Paso 2 (`ProcesarCargaCsvAction`) | [TC-11](test-cases.md#L89-L93) | ✅ |
| **CB-2** (Columnas Incorrectas) | Sí $\rightarrow$ Paso 2 (`ProcesarCargaCsvAction`) | [TC-12](test-cases.md#L95-L99) | ✅ |
| **CB-3** (Sin Candidatos Sugeridos) | Sí $\rightarrow$ Paso 4 (`CalcularSimilitudesCabosAction`) | [TC-9](test-cases.md#L68-L80) | ✅ |

---

## 🚦 Veredicto del Gate de Claridad (§2.8 & §6)

**Grupo Evaluador:** Grupo V2 (Vonex)  
**Grupo Evaluado (Otro Grupo):** Grupo V1 (Sistema de Asignación de Aulas)

Sometimos a revisión técnica la especificación funcional (`spec.md`) del **Grupo V1** bajo las 4 categorías obligatorias de claridad:

1. **Completitud [🟡 Observado]:** La descripción del algoritmo de asignación detalla adecuadamente el caso feliz. Sin embargo, no se especifica el comportamiento esperado del sistema cuando la cantidad de alumnos excede la capacidad física del aula asignada por un margen mínimo (ej. sobre-inscripción menor de 1 a 2 alumnos).
2. **Claridad [✓ Aprobado]:** El spec del Grupo V1 evita el uso de adjetivos ambiguos (como "rápido" o "eficiente"). La capacidad del aula y el proceso de distribución están bien acotados con variables numéricas claras.
3. **Consistencia [✓ Aprobado]:** La terminología del dominio (como "Aula", "Turno", "Facultad") se mantiene coherente a lo largo de todo el documento.
4. **Testabilidad [🟡 Observado]:** Los criterios de aceptación carecen de datos concretos de entrada y de un criterio explícito de desempate para validar el comportamiento del algoritmo heurístico en caso de igualdad de prioridades horarias.

### **Faltantes Críticos Detectados en el Spec del Grupo V1:**
- **NFR de Rendimiento Ausente:** Falta definir el requisito no funcional (**NFR**) del tiempo de respuesta máximo admitido para el endpoint de consulta de aulas en tiempo real bajo condiciones de alta concurrencia de facultades.
- **Criterio de Desempate No Especificado:** El spec no define la lógica de resolución para asignación de aulas ante solicitudes concurrentes con idéntico nivel de prioridad horaria y aforo.

### **Veredicto:** 🟡 **APROBADO CON OBSERVACIONES**
*El Grupo V1 puede proceder a la fase de diseño siempre que se resuelvan las observaciones descritas de aforo excedido, desempate de prioridades y el NFR de rendimiento.*

