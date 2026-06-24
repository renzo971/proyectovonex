# Copilot Test Instructions

This file provides instructions for GitHub Copilot to generate and test code effectively in this project.

## Project Overview

This project is a multi-module application with the following key components:

- **Frontend**: React applications using TypeScript and Vite.
- **Backend**: Node.js services with TypeScript.
- **Shared Components**: Reusable components and utilities.

## Key Guidelines for Copilot

### 1. **Frontend (React + Vite)**

- Follow the established component structure in `client/components`.
- Use TypeScript for all components and ensure proper type annotations.
- Use `react-router` for navigation and routing.
- Ensure compatibility with Vite's module system.

### 2. **Backend (Node.js + TypeScript)**

- Follow the structure in `src/` for controllers, services, and routes.
- Use `express` for routing and middleware.
- Ensure all services and controllers are properly typed.
- Use `tsconfig.json` settings for module resolution and strict typing.

### 3. **Shared Components**

- Place reusable components in `client/components`.
- Use `@dap-ui/stratos` for UI elements where applicable.
- Ensure components are modular and reusable across different modules.

### 4. **Testing**

- Write unit tests for all components and services.
- Use `jest` for testing backend services.
- Use `react-testing-library` for frontend components.

### 5. **Code Quality**

- Follow ESLint rules defined in `eslint.config.js`.
- Ensure code is formatted using Prettier.
- Avoid hardcoding values; use environment variables or configuration files.

### 6. **Dependency Management**

- Keep dependencies up-to-date.
- Use `optimizeDeps` in Vite configuration to manage dependency optimization.

### 7. **General Tips**

- Use meaningful variable and function names.
- Add comments and JSDoc annotations where necessary.
- Follow DRY (Don't Repeat Yourself) principles.

## UI Library

React is a JavaScript library for building user interfaces. It provides a component-based architecture, efficient rendering with the virtual DOM, and declarative programming for creating interactive web applications. React is widely used for frontend development and integrates well with various state management and routing solutions.

## Programming Language

TypeScript is a statically typed programming language that builds on JavaScript. It enhances development with type safety, interfaces, and improved tooling, making code more maintainable and reducing runtime errors. TypeScript is widely used in large-scale applications to boost developer productivity and code quality while compiling down to JavaScript for execution.

## Development Essentials

### Form Validation

React Hook Form is a lightweight library for handling form validation in React. It prioritizes performance by minimizing re-renders and leveraging uncontrolled components. It also supports schema-based validation with libraries like Yup and Zod.

### Routing

React Router is the standard solution for handling navigation in React applications. It enables declarative routing, dynamic route matching, and nested routes, making it an ideal choice for building complex, multi-page applications.

### Data Fetching

TanStack Query (formerly React Query) simplifies data fetching, caching, and synchronization in React applications. It provides automatic background refetching, stale time management, and retry mechanisms, improving performance and developer experience.

### HTTP Requests

Axios is a popular promise-based HTTP client for making requests in JavaScript and TypeScript. It simplifies the process of sending and receiving HTTP requests, supports features like request and response interceptors, and has built-in support for JSON transformation and error handling, making it a great tool for interacting with APIs.

### Styling

styled-components is a CSS-in-JS library that allows you to write scoped styles directly in your components. It supports dynamic styling, theming, and automatic critical CSS extraction, making it a powerful tool for styling modern applications.

### UI Components

**DAP Stratos**
DAP Stratos is a UI component library designed and developed by Acme.

## Example Scenarios for Copilot

- Generate a new React component with props and state.
- Create a new Express route with middleware.
- Write a unit test for a service or component.
- Suggest optimizations for existing code.

## Feedback

If Copilot's suggestions are not relevant, provide feedback to improve its understanding of the project.

## State Management

### Use Hooks + Context When:

- The state is local or shared by a few components.
- You do not need advanced middleware, dev-time tracing, or cross-tab sync.

### Choose Redux Toolkit When:

- Multiple domains need to coordinate actions or you require optimistic updates.
- You want time-travel debugging or to persist/rehydrate state easily.
- Your team already knows Redux or other libraries integrate via Redux.
