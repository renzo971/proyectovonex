# 🚀 Proyecto Vonex — Equipo **V2**

¡Bienvenidos al repositorio del **Equipo V2** para el desarrollo del **Proyecto Vonex**! Este espacio está destinado a la colaboración, control de versiones y documentación de todas las funciones y componentes del sistema.

---

## 👥 Integrantes y Funciones del Equipo

A continuación se detallan los miembros del equipo **V2** y sus respectivos roles dentro del desarrollo del proyecto:

| Integrante          | Rol / Especialidad | Área / Función Principal            | Contribución                                                                        |
| :------------------ | :----------------- | :---------------------------------- | :---------------------------------------------------------------------------------- |
| **Samuel Cisneros** | 📋 Analista        | **Product Owner / Product Manager** | Definición de requerimientos, análisis de negocio y dirección de producto.          |
| **Renzo Fabián**    | 💻 Fullstack       | **Tech Lead / Lead Developer**      | Desarrollo de arquitectura frontend y backend, integraciones y lógica de negocio.   |
| **Diego Fernando**  | 🛠️ Soporte         | **Quality Assurance (QA)**          | Control de calidad, diseño y ejecución de planes de pruebas y soporte técnico.      |
| **Yerson Vargas**   | 🛠️ Soporte         | **QA / Apoyo Técnico**              | Soporte de infraestructura, pruebas funcionales y asistencia en control de calidad. |

---

## 🛠️ El proyecto contendra el siguiente Stack Tecnológico

El proyecto está diseñado bajo un ecosistema de tecnologías robustas y modernas para asegurar la escalabilidad, rendimiento y seguridad:

### **Backend & APIs**

- ![PHP](https://img.shields.io/badge/PHP-777BB4?style=for-the-badge&logo=php&logoColor=white) - Lenguaje de programación principal.
- ![Laravel](https://img.shields.io/badge/Laravel-FF2D20?style=for-the-badge&logo=laravel&logoColor=white) - Framework MVC para el desarrollo ágil de APIs y backend estructurado.

### **Base de Datos**

- ![Postgres](https://img.shields.io/badge/postgres-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white) - Motor de base de datos relacional y transaccional.

### **Herramientas de Desarrollo**

- ![Git](https://img.shields.io/badge/git-%23F05033.svg?style=for-the-badge&logo=git&logoColor=white) - Control de versiones.
- ![Composer](https://img.shields.io/badge/Composer-885630?style=for-the-badge&logo=composer&logoColor=white) - Gestor de dependencias de PHP.

---

## 📈 Se debe considerar el flujo de Trabajo (Git Workflow)

Para asegurar la calidad y orden en nuestro repositorio, seguimos las siguientes prácticas:

1. **Rama `main` / `master`**: Producción estable. Solo se sube código verificado mediante pull requests.
2. **Rama `develop`**: Entorno de desarrollo e integración.
3. **Ramas de Características (`feature/`)**: Cada nueva funcionalidad o API se desarrolla en una rama dedicada (ej. `feature/alumno-matricula-api`).
4. **Validaciones**: Antes de fusionar con `develop`, todo código debe pasar por revisiones de QA.

---

## 🚀 Comenzar con el Proyecto

### Requisitos Previos

- PHP >= 8.x
- Composer
- PostgreSQL
- Servidor web local (Laragon, XAMPP, Herd, etc.)

### Instalación Local

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/renzo971/proyectovonex.git
   cd proyectovonex
   ```
2. **Instalar dependencias:**
   ```bash
   composer install
   npm install
   ```
3. **Configurar variables de entorno:**
   - Duplicar el archivo `.env.example` y renombrarlo a `.env`.
   - Configurar las credenciales de la base de datos PostgreSQL en el `.env`.
4. **Generar la clave de la aplicación:**
   ```bash
   php artisan key:generate
   ```
5. **Ejecutar migraciones y seeders:**
   ```bash
   php artisan migrate --seed
   ```
6. **Iniciar el servidor local:**
   ```bash
   php artisan serve
   ```

---

_Desarrollado con ❤️ por el **Equipo V2**._
