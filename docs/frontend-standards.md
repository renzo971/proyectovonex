---
description: Frontend development standards, best practices, and conventions for the VX Intranet Vue 2 and Blade application including Vue.js integration, styling guidelines, and form submission practices.
globs: ["resources/views/**/*.blade.php", "package.json", "webpack.mix.js"]
alwaysApply: true
---

# Frontend Project Standards and Best Practices

## 1. Overview & Technology Stack

The frontend of VX Intranet is built using **Blade templates** as the entry points and main structure, with **Vue.js 2.x** integrated directly for reactive components and dynamic form logic. Styling is built using **Bootstrap 4** and customized CSS.

### Core Stack
- **Framework**: Vue.js 2.x (Options API)
- **View Layer**: Laravel Blade Templates
- **Styling**: Bootstrap 4, FontAwesome icons, Custom CSS
- **Notifications**: SweetAlert2 (for interactive modals, alerts, and success/error prompts)

---

## 2. Architecture & Conventions

### 2.1 Blade & Vue Integration
- **Blade Entrypoint**: Blade templates serve the page layout (head, navigation, footer, containers).
- **Vue Instances**: Vue instances are mounted onto specific containers or wrappers.
- **Double Curly Braces**: Since Blade uses `{{ ... }}` for string interpolation, you MUST prefix Vue interpolations with an `@` symbol (i.e. `@{{ vueVariable }}`) so Blade ignores them and passes them to Vue.
- **Data Binding**: Pass backend data into Vue by encoding variables to JSON inside a global script block or inline attributes:
  ```html
  <div id="app" data-frecuencias="{{ json_encode($frecuencias) }}">
  ```

### 2.2 Directory Layout & Views
Views are organized by module directories inside `resources/views/`. For instance, the `aula-fusion` module lives in:
```
resources/views/aulaFusion/
├── inicio.blade.php             # Main entry point view containing structural Blade layout
└── modos/
    ├── creacion-rapida.blade.php # Quick creation mode interface using Vue 2 bindings
    ├── fusion-masiva.blade.php   # Massive fusion interface using Vue 2 bindings
    └── traslado-manual.blade.php # Manual student relocation view
```

### 2.3 Component Naming & Event Binding
- Naming conventions: Use `camelCase` for variables and event properties within Vue scripts.
- Vue event handlers: Use standard directives (e.g. `@click="someMethod"`, `@input="someMethod"`).

---

## 3. UI/UX & Styling Guidelines (Bootstrap 4)

To align with the premium corporate design of VX Intranet, components must adhere to the design system utilizing Bootstrap 4:

### 3.1 Design System Tokens & Aesthetics
- **Branding**: Professional primary colors (e.g., standard dark backgrounds, gradients, accent colors like warning yellows and success greens).
- **Layouts**: Wrap components in structured cards (`card`, `card-body`) and use Bootstrap grids (`row`, `col-md-6`, etc.) for responsiveness.
- **Alerts and Callouts**: Use custom callouts (e.g. `.callout-success`, `.callout-info`) for helpful guidance.
- **Badges**: Use pill badges (`badge badge-pill badge-success`) to highlight important meta-information (e.g. aforo, tipo de aula).

### 3.2 Dialogs & Feedback (SweetAlert2)
- Do not use native browser `alert()` or `confirm()` dialogs.
- Use **SweetAlert2** (`Swal.fire`) for user validation warnings, success alerts, and confirm modals.
  ```javascript
  Swal.fire({
      title: '¡Éxito!',
      text: 'El aula de fusión se ha creado correctamente.',
      icon: 'success',
      confirmButtonText: 'Aceptar'
  });
  ```

---

## 4. Language & Translations

- **UI & Labels**: All UI text (button labels, select options, placeholders, notifications, and alert messages) visible to the end user must be written in **Spanish**.
- **Variables & Code**: All JavaScript variables, methods, class names, API response fields, and comments must be in **English**.
