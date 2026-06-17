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
| **US-1 / AC-1.1** (Carga y Lotes) | Sí $\rightarrow$ Paso 2 (`ProcesarCargaCsvAction`) | [TC-1](file:///c:/Users/rsantos_vonex/develop/proyectovonex/feature-motor-cruce-grupoV2/test-cases.md#L10-L14) | ✅ |
| **US-1 / AC-1.2** (Normalización) | Sí $\rightarrow$ Paso 2 (`NormalizarTextoAction`) | [TC-2](file:///c:/Users/rsantos_vonex/develop/proyectovonex/feature-motor-cruce-grupoV2/test-cases.md#L16-L20) | ✅ |
| **US-1 / AC-1.3** (Apellidos compuestos) | Sí $\rightarrow$ Paso 2 (`NormalizarTextoAction`) | [TC-2](file:///c:/Users/rsantos_vonex/develop/proyectovonex/feature-motor-cruce-grupoV2/test-cases.md#L16-L20) | ✅ |
| **US-1 / AC-1.4** (Filtrado de vacante) | Sí $\rightarrow$ Paso 2 (`ProcesarCargaCsvAction`) | [TC-8](file:///c:/Users/rsantos_vonex/develop/proyectovonex/feature-motor-cruce-grupoV2/test-cases.md#L47-L51) | ✅ |
| **US-2 / AC-2.1** (Conexión directa DB) | Sí $\rightarrow$ Paso 3 (`RealizarCruceExactoAction`) | [TC-4](file:///c:/Users/rsantos_vonex/develop/proyectovonex/feature-motor-cruce-grupoV2/test-cases.md#L27-L31) | ✅ |
| **US-2 / AC-2.2** (Prioridad de estados) | Sí $\rightarrow$ Paso 3 (`RealizarCruceExactoAction`) | [TC-5](file:///c:/Users/rsantos_vonex/develop/proyectovonex/feature-motor-cruce-grupoV2/test-cases.md#L33-L37) y [TC-6](file:///c:/Users/rsantos_vonex/develop/proyectovonex/feature-motor-cruce-grupoV2/test-cases.md#L39-L42) | ✅ |
| **US-3 / AC-3.1** (Match Exacto) | Sí $\rightarrow$ Paso 3 (`RealizarCruceExactoAction`) | [TC-3](file:///c:/Users/rsantos_vonex/develop/proyectovonex/feature-motor-cruce-grupoV2/test-cases.md#L22-L25) | ✅ |
| **US-3 / AC-3.2** (Fuzzy / Cabos sueltos) | Sí $\rightarrow$ Paso 4 (`CalcularSimilitudesCabosAction`) | [CB-3](file:///c:/Users/rsantos_vonex/develop/proyectovonex/feature-motor-cruce-grupoV2/spec.md#L88) (Comportamiento sin candidatos) | ✅ |
| **US-4 / AC-4.1** (React `<select>`) | Sí $\rightarrow$ Paso 5 (Interfaz Web React) | *Verificación de UI de Frontend* | ✅ |
| **US-4 / AC-4.2** (Confirmación manual) | Sí $\rightarrow$ Paso 5 (`GuardarCruceConfirmadoAction`) | *Verificación de Flujo en Frontend* | ✅ |
| **US-5 / AC-5.1** (Hoja Excel - Data) | Sí $\rightarrow$ Paso 6 (`ExportarExcelCruceAction`) | [TC-7](file:///c:/Users/rsantos_vonex/develop/proyectovonex/feature-motor-cruce-grupoV2/test-cases.md#L44-L45) | ✅ |
| **US-5 / AC-5.2** (Hoja Excel - Dashboard) | Sí $\rightarrow$ Paso 6 (`ExportarExcelCruceAction`) | [TC-7](file:///c:/Users/rsantos_vonex/develop/proyectovonex/feature-motor-cruce-grupoV2/test-cases.md#L44-L45) | ✅ |

---

## 🚦 Veredicto del Gate de Claridad (§2.8 & §6)

El grupo revisor ha sometido la especificación (`spec.md`) a evaluación en las siguientes 4 categorías:

1. **Completitud [✓]:** Cada historia de usuario (US) posee criterios de aceptación claros y medibles. Se definieron formalmente casos borde (CB-1 a CB-3) y requisitos no funcionales (NFRs) relativos a tiempo de procesamiento, límites de memoria y velocidad de la API.
2. **Claridad [✓]:** Se han eliminado pronombres ambiguos y adjetivos subjetivos (por ejemplo: "rápido" o "eficiente"). Se reemplazaron por métricas numéricas concretas e inconfundibles (tiempos de respuesta `< 300 ms` y procesamiento `< 5 segundos`).
3. **Consistencia [✓]:** Existe alineación y trazabilidad total entre la terminología técnica empleada en el spec, los nombres de las clases de acciones en el plan de implementación, los esquemas de bases de datos detallados y las asunciones establecidas.
4. **Testabilidad [✓]:** Todos los requisitos y criterios de aceptación están descritos bajo la sintaxis `Dado / Cuando / Entonces`, produciendo resultados observables verificables de manera automatizada o mediante auditoría visual.

### **Veredicto:** 🟢 **TODO PASA (Aprobado)**
*Se cuenta con un nivel de especificación robusto y verificado por el equipo para proceder con la implementación.*
