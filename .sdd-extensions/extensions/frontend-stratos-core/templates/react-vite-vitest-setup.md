# React + Vite + Vitest Setup Template

## Purpose

Baseline setup template for frontend MFE projects using React, Vite, and Vitest with Stratos design system.

## Prerequisites

- Node.js 20+
- Package manager: npm or yarn

## Project Initialization

```bash
npm create vite@latest mfe-<domain> -- --template react-ts
cd mfe-<domain>
```

## Core Dependencies

```bash
# Framework
npm install react@^19 react-dom@^19
npm install react-router-dom@^7

# Stratos Design System
npm install @dap-ui/stratos styled-components

# State Management
npm install zustand
# OR for Redux-based projects:
npm install @reduxjs/toolkit react-redux

# API Layer
npm install axios @tanstack/react-query

# Forms
npm install react-hook-form

# Internationalization
npm install react-intl

# Module Federation (if part of shell)
npm install @module-federation/vite
```

## Dev Dependencies

```bash
# Testing
npm install -D vitest @testing-library/react @testing-library/jest-dom @testing-library/user-event jsdom

# E2E Testing
npm install -D @playwright/test @cucumber/cucumber

# TypeScript
npm install -D typescript@^5.7

# Build
npm install -D vite@^6
```

## Vite Configuration

```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './src/test-setup.ts',
    css: true,
  },
  server: {
    port: 3000,
  },
});
```

## Test Setup

```typescript
// src/test-setup.ts
import '@testing-library/jest-dom';
```

## TypeScript Configuration

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "jsx": "react-jsx",
    "strict": true,
    "moduleResolution": "bundler",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true
  },
  "include": ["src"]
}
```

## Folder Structure

Follow the MFE canonical structure from `fe-frontend-architecture-mfe.instructions.md`.

## Verification

After setup, verify:
1. `npm run dev` starts the dev server
2. `npm run build` produces clean output
3. `npm run test` runs Vitest successfully
4. Stratos components render with correct tokens

## Figma MCP Integration (Optional)

To enable AI-assisted design-to-code workflows using the Figma MCP server, add the following to your project's `.vscode/mcp.json`:

```json
{
  "servers": {
    "figma": {
      "type": "sse",
      "url": "https://figma.mcp.server/sse",
      "env": {
        "FIGMA_API_KEY": "${env:FIGMA_API_KEY}",
        "FIGMA_PROJECT_ID": "${env:FIGMA_PROJECT_ID}"
      }
    }
  }
}
```

**Setup steps:**
1. Obtain a Figma Personal Access Token from your Figma account settings
2. Set `FIGMA_API_KEY` and `FIGMA_PROJECT_ID` as environment variables (or in `.env`)
3. The MCP server enables agents to read Figma frames and extract design tokens
4. Works with `@architect` and `@software-engineer` agents for design-to-component mapping

> **Note:** This is opt-in. The Figma MCP server must be configured per-project and requires a valid Figma API key. See the extension pack README for details.
