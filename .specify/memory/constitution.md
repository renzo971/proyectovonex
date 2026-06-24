---
# Wave 23 §23.A.9/§23.A.10 — memory frontmatter for time-decay ranking
last_referenced_at: "2026-04-14T21:22:22.712336+00:00"
reference_count: 0
decay_floor: true
---

# Project Constitution: Vonex

**Version:** 2.2.0
**Established:** 2026-06-16
**Last Amended:** 2026-06-16

---

## Article I: Identidad del Proyecto

### 1.1 Propósito

Este proyecto construye un flujo analítico para ingerir, normalizar, cruzar y validar registros de admisión de estudiantes contra la base de datos académica, generando reportes confiables y decisiones asistidas para el equipo.

### 1.2 Visión

Vonex aspira a convertirse en la base analítica de confianza para los procesos de admisión y emparejamiento académico, permitiendo que el equipo tome decisiones más rápidas, precisas y auditables con menos esfuerzo manual y menos errores operativos.

### 1.3 Usuarios

| Persona                         | Descripción                                                 | Necesidades principales                                                     |
| ------------------------------- | ----------------------------------------------------------- | --------------------------------------------------------------------------- |
| Equipo de admisiones            | Responsable de procesar cargas masivas de registros         | Cargar CSVs, cruzar información y revisar coincidencias dudosas con rapidez |
| Analistas de datos              | Encargados de producir reportes y decisiones de integración | Obtener datos limpios, trazables y consistentes                             |
| Desarrolladores y agentes de IA | Encargados de implementar y mantener el pipeline            | Trabajar con reglas claras, pruebas y documentación actualizada             |
| QA                              | Responsable de validar calidad y regresiones                | Confirmar que los cambios no rompen el flujo de cruce ni la trazabilidad    |

### 1.4 Métricas de Éxito

| Métrica                                                 | Objetivo                                               | Medición                                             |
| ------------------------------------------------------- | ------------------------------------------------------ | ---------------------------------------------------- |
| Precisión del cruce inicial                             | 100% para coincidencias exactas aceptables             | Comparación de resultados contra validación esperada |
| Registros con coincidencia difusa revisados por usuario | 100% de cabos sueltos                                  | Reporte de lotes con casos pendientes de validación  |
| Duplicados evitados                                     | 100% de registros ya procesados ignorados              | Revisión de lotes y auditoría de carga               |
| Tiempo de procesamiento por lote                        | Menor o igual al tiempo operativo aceptable del equipo | Métricas de ejecución del pipeline                   |
| Trazabilidad por lote                                   | 100% de eventos y fallos registrados                   | Auditoría y logs del sistema                         |

---

## Article II: Stack Tecnológico

### 2.1 Entorno de Ejecución y Plataforma

| Component              | Technology                     | Version | Notes                                                             |
| ---------------------- | ------------------------------ | ------- | ----------------------------------------------------------------- |
| Production Environment | Linux / servidor de aplicación | -       | Ejecución en entorno operativo estable y controlado               |
| Container Platform     | None                           | -       | El proyecto se ejecuta directamente sobre el runtime del servidor |
| CI/CD                  | GitHub Actions                 | -       | Validaciones automáticas para pruebas y revisión                  |
| Package Manager        | Composer / npm                 | -       | Backend con Composer; frontend con npm o equivalente              |

### 2.2 Backend

| Component         | Technology      | Version                           | Notes                                                       |
| ----------------- | --------------- | --------------------------------- | ----------------------------------------------------------- |
| Language          | PHP             | 8.4+                              | Requerido con `declare(strict_types=1);`                    |
| Framework         | Laravel         | Version compatible con PHP 8.4+   | Arquitectura orientada a acciones y servicios               |
| Database          | PostgreSQL      | Compatible con la base `academia` | Base de datos operativa del flujo analítico                 |
| ORM/Query Builder | Eloquent / DB   | -                                 | Mantener relaciones limpias y consultas explícitas          |
| Caching           | None by default | -                                 | Se agrega solo cuando el caso lo justifique                 |
| Messaging         | None by default | -                                 | No se introduce infraestructura de mensajería sin necesidad |

### 2.3 Frontend

| Component        | Technology                   | Version                   | Notes                                               |
| ---------------- | ---------------------------- | ------------------------- | --------------------------------------------------- |
| Framework        | React                        | 18.x+                     | SPA con componentes funcionales y hooks             |
| Language         | TypeScript                   | Compatible con React/Vite | Preferido para mayor seguridad y mantenibilidad     |
| State Management | React hooks / contexto local | -                         | Se evita complejidad innecesaria si no es requerida |
| Styling          | CSS Modules o Tailwind       | -                         | Definir según el alcance del módulo                 |
| Build Tool       | Vite                         | -                         | Entorno moderno para el frontend                    |

### 2.4 Testing

| Type                | Framework                 | Version | Notes                                                   |
| ------------------- | ------------------------- | ------- | ------------------------------------------------------- |
| Unit Testing        | Pest / PHPUnit            | -       | Obligatorio para la lógica de cruce y reglas de negocio |
| Integration Testing | Pest / Laravel HTTP tests | -       | Para endpoints y flujo de integración del backend       |
| E2E Testing         | Playwright                | -       | Se usa cuando el flujo de usuario aporta valor crítico  |
| Contract Testing    | None by default           | -       | Solo si el sistema expone contratos externos complejos  |
| Load Testing        | None by default           | -       | Se incorpora si el volumen lo exige                     |

---

## Article III: Estándares de Calidad

### 3.1 Calidad del Código

#### Tipado Estricto

- Tipos estrictos en PHP: **Obligatorio**
- Sin `any` implícito en código frontend; evitar tipado débil cuando sea posible
- Las APIs públicas y los métodos de servicio deben exponer contratos explícitos y devolver estructuras de datos claras

#### Linting

- Herramienta: PHP-CS-Fixer / Pint y ESLint o estándar equivalente del proyecto
- Configuración: Configuración estándar del proyecto; sin excepciones locales sin aprobación
- Aplicación en pre-commit: Sí

#### Formato

- Herramienta: Formateador alineado con el estándar del proyecto
- Configuración: Aplicado en CI y desarrollo local
- Formateo automático al guardar: Recomendado

### 3.2 Cobertura de Pruebas

| Alcance           | Mínimo                                      | Recomendado                                         | Rutas críticas |
| ----------------- | ------------------------------------------- | --------------------------------------------------- | -------------- |
| General           | 80%                                         | 90%                                                 | 100%           |
| Código nuevo      | 100%                                        | 100%                                                | 100%           |
| Pruebas unitarias | Obligatorio para la lógica central          | Obligatorio para todas las reglas de negocio nuevas | -              |
| Integración       | Obligatorio para endpoints y flujo de datos | Obligatorio para flujos por lotes                   | -              |

### 3.3 Rendimiento

| Métrica                  | Objetivo                                    | Umbral de alerta                                       |
| ------------------------ | ------------------------------------------- | ------------------------------------------------------ |
| Respuesta de API (p95)   | 500ms                                       | 1s                                                     |
| Procesamiento por lotes  | Estable dentro de la ventana operativa      | Cualquier timeout o pausa repetida debe revisarse      |
| Consulta a base de datos | Bajo el umbral operativo del volumen actual | Cualquier degradación sostenida requiere investigación |

### 3.4 Seguridad

#### Autenticación

- Método: Autenticación servicio a servicio y controles de sesión de usuario cuando aplique
- Almacenamiento de secretos: Solo variables de entorno; nunca en el repositorio
- Duración de sesión: Breve y explícita cuando la autenticación sea requerida

#### Autorización

- Modelo: Acceso basado en roles cuando sea requerido
- Aplicación: Middleware o verificaciones a nivel de servicio para operaciones sensibles
- Por defecto: Denegar por defecto para acciones privilegiadas

#### Protección de Datos

- Cifrado en reposo: Requerido para capas de persistencia sensibles
- Cifrado en tránsito: TLS requerido para cualquier conexión externa
- Manejo de PII: Los datos académicos sensibles deben tratarse con cuidado y registrarse mínimamente
- Gestión de secretos: Solo `.env` o secretos gestionados por entorno equivalente

#### Cumplimiento

- [x] OWASP Top 10 abordado en diseño e implementación
- [ ] Marcos de cumplimiento adicionales solo si se requieren explícitamente
- [x] Revisión de seguridad requerida antes de publicar cambios sensibles

### 3.5 Accesibilidad

- Estándar: WCAG 2.1 AA para interfaces orientadas al usuario
- Pruebas: Manuales y automatizadas cuando sea factible
- Herramientas: Lighthouse / axe o equivalentes cuando haya UI involucrada
- Aplicación: Validaciones en CI y revisión manual para cambios de UI de alto impacto

---

## Article IV: Principios de Arquitectura

### 4.1 Principios de Diseño

1. **Pequeños pasos y validación continua**
   Cada cambio debe implementarse en incrementos pequeños y verificables para que los fallos sean fáciles de aislar y corregir.

2. **Preservación de patrones y compatibilidad**
   El proyecto debe conservar los patrones arquitectónicos, los nombres y las expectativas de compatibilidad existentes mientras evoluciona.

3. **Precisión analítica antes que velocidad bruta**
   Las reglas de coincidencia y normalización deben ser estrictas, auditables y resistentes a casos difusos.

4. **Trazabilidad por defecto**
   Cada lote, fecha de examen, resultado de cruce y error debe registrarse para reconstruir decisiones.

5. **Seguridad y portabilidad**
   El flujo debe evitar secretos hardcodeados y mantener las especificaciones para agentes en un lugar compartido y portable.

### 4.2 Organización del Código

El backend debe mantenerse organizado alrededor de controladores delgados, clases de tipo acción y servicios explícitos donde corresponda la lógica de negocio. Los módulos del frontend deben mantenerse enfocados, componibles y alineados con el contrato de la API.

### 4.3 Gestión de Dependencias

- Las nuevas dependencias requieren justificación explícita y aprobación previa.
- Los cambios de esquema de base de datos y los cambios mayores de dependencias requieren revisión antes de implementarse.
- Los artefactos reutilizables en `ai-specs` deben referenciarse mediante symlinks para mantener alineados a agentes y herramientas.

### 4.4 Diseño de API

- Estilo: REST
- Versionado: Versionado por URL solo cuando el contrato deba evolucionar de manera segura
- Nomenclatura: Términos de negocio en español y símbolos técnicos en inglés
- Formato de error: Respuestas JSON estructuradas desde los controladores de API
- Paginación y filtrado: Se agregan cuando el volumen de datos lo requiere

### 4.5 Manejo de Errores

- Los timeouts, fallas de conexión y procesamiento parcial deben pausar el lote y marcar los registros afectados para revisión.
- Los fallos deben registrarse con suficiente contexto para reconstruir la ruta de decisión.
- Los errores de validación y de reglas de negocio deben devolver retroalimentación estructurada en lugar de fallar en silencio.

### 4.6 Logging y Observabilidad

#### Logging

- Se requieren logs estructurados para la ejecución de lotes, estado de conexión, resultados de cruce y fallas.
- Los logs deben incluir marca de tiempo, nivel, operación, contexto de entidad e identificadores relevantes.

#### Observabilidad

- El equipo debe poder reconstruir el origen de cada decisión analítica a partir de los metadatos de lote y los logs.

### 4.7 Flujo del Proceso de Cruce

1. Conectarse a la base de datos académica y extraer los registros actuales de estudiantes.
2. Cargar el archivo CSV entrante proporcionado por el sistema fuente.
3. Aplicar la regla inicial de coincidencia estricta: `2 apellidos exactos + 1 nombre exacto`.
4. Para registros no coincidentes pero similares, ejecutar matching difuso y presentarlos al usuario para validación asistida antes de guardar.
5. Ignorar fechas y registros ya procesados al procesar un nuevo archivo para evitar duplicados.

---

## Article V: Flujo de Desarrollo

### 5.1 Flujo de Git

- **Estrategia de ramas:** `main` para producción estable, `develop` para integración y ramas `feature/*` para trabajo nuevo.
- **Mensajes de commit:** Commits convencionales en inglés para símbolos técnicos y en español para lenguaje de negocio cuando sea apropiado.
- **Requisitos de PR:** Cada fusión a `develop` o `main` debe revisarse, probarse y documentarse.

### 5.2 Proceso de Revisión

- **Revisores requeridos:** Tech Lead y QA o revisor designado.
- **Criterios de revisión:** corrección, trazabilidad, pruebas, seguridad y adherencia a la constitución.
- **Requisitos de aprobación:** Al menos una revisión aprobatoria más validación aprobada antes de fusionar.

### 5.3 Definición de Hecho

Una funcionalidad está lista cuando:

- [ ] La implementación está completa y verificada.
- [ ] Existen pruebas automatizadas y pasan.
- [ ] La documentación y las especificaciones relevantes están actualizadas.
- [ ] Los comentarios de revisión están resueltos.
- [ ] El cambio es seguro para fusionar y no introduce regresiones.

### 5.4 Pruebas y Ejecución

- Pruebas de backend: `php artisan test` (Pest/PHPUnit).
- La validación manual de endpoints con `curl` o el navegador MCP se permite como complemento, pero no reemplaza las pruebas automatizadas.
- La generación de Wayfinder es obligatoria cuando cambian las rutas del backend: `php artisan wayfinder:generate`.

### 5.5 TDD Mode

```yaml
tdd_mode: true
```

Cuando `tdd_mode` está habilitado, el trabajo de implementación debe comenzar con al menos una prueba fallida o un test stub para el comportamiento objetivo antes de escribir código de producción.

---

## Article VI: Límites

### 6.1 Siempre Hacer

1. Etiquetar cada registro entrante con su fecha de examen correspondiente antes de insertarlo en la base de datos analítica.
2. Validar la conectividad y la autenticación a la base de datos académica antes de procesar cualquier lote.
3. Ignorar fechas y registros ya procesados al manejar un nuevo CSV para evitar duplicaciones.
4. Entregar trabajo en pasos cortos e incrementales con verificación frecuente.
5. Devolver JSON estructurado desde los controladores de API.
6. Validar endpoints manualmente con `curl` o el navegador MCP antes de finalizar una iteración.
7. Mantener la documentación técnica actualizada.

### 6.2 Preguntar Primero

1. Antes de cambiar o ampliar la lista de estados permitidos para el matching.
2. Antes de cambiar la estructura de las columnas del CSV entrante.
3. Antes de agregar nuevas dependencias de Composer o npm.
4. Antes de cambiar esquemas de base de datos.

### 6.3 Nunca Hacer

1. Volver a la manipulación manual de datos o delegar el filtrado de fechas a intervención humana.
2. Sobrescribir datos de días de examen previos al procesar un nuevo lote.
3. Guardar coincidencias no exactas directamente sin permitir que el usuario las revise mediante validación asistida.
4. Escribir SQL directamente en vistas Blade.
5. Colocar lógica de negocio directamente en controladores.
6. Almacenar credenciales o secretos en el repositorio.

---

## Article VII: Enmiendas

### 7.1 Proceso de Enmienda

1. **Propuesta:** Crear una propuesta de cambio o PR que modifique esta constitución.
2. **Revisión:** El Tech Lead y QA o revisores designados evalúan el cambio.
3. **Discusión:** Discusión del equipo para cambios significativos.
4. **Aprobación:** Aprobación del equipo y actualización de versión antes de fusionar.

### 7.2 Registro de Enmiendas

| Fecha      | Versión | Artículo | Cambio                                                                              | Autor  |
| ---------- | ------- | -------- | ----------------------------------------------------------------------------------- | ------ |
| 2026-06-16 | 2.2.0   | -        | Constitución inicial alineada al flujo de Vonex y a la estructura de SDD Enterprise | Equipo |
