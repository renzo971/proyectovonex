---
applyTo: "**/*.{tsx,ts,jsx}"
---
# Frontend Architecture — MFE Decomposition Rules

## Purpose

Provide a consistent decision framework for microfrontend decomposition, feature isolation, and cross-MFE integration.

## Project Structure

Every MFE follows this canonical folder structure:

```
mfe-<domain>/
├── client/
│   ├── api/                   # API client layer
│   │   ├── hooks/             # React Query hooks (useGet*, useMutate*)
│   │   ├── instance.ts        # Axios instance configuration
│   │   └── urls.ts            # API endpoint definitions
│   ├── components/            # Shared components
│   │   ├── RHF/               # React Hook Form wrappers
│   │   ├── ErrorBoundary/
│   │   └── Common*/           # Reusable state components
│   ├── enums/                 # TypeScript enums
│   ├── hooks/                 # Custom React hooks
│   ├── layouts/               # Layout components
│   ├── models/                # Data models and types
│   ├── pages/                 # Feature pages (isolated)
│   │   └── <Feature>/
│   │       ├── components/    # Feature-specific components
│   │       ├── hooks/         # Feature-specific hooks
│   │       └── index.tsx
│   ├── providers/             # Context providers
│   ├── routes/                # Route configuration
│   ├── stores/                # State stores (Zustand/Redux)
│   └── translations/         # i18n messages
├── e2e-tests/                 # Playwright + Cucumber E2E
├── public/                    # Static assets
└── mock/                      # Mock API server for development
```

## MFE Decomposition Rules

### Rule 1 — Domain Boundary

Each MFE owns exactly one business domain. Cross-domain data access goes through API calls, never direct imports.

### Rule 2 — Feature Isolation

Each feature page is a self-contained folder under `pages/`. Features cannot import from each other's `components/` or `hooks/`.

### Rule 3 — Shared vs. Feature-Specific

| Category | Location | Rule |
|----------|----------|------|
| Used by 2+ features | `client/components/` | Shared |
| Used by 1 feature only | `pages/<Feature>/components/` | Feature-specific |
| API hooks | `client/api/hooks/` | Always shared |
| Feature state | `pages/<Feature>/hooks/` or `stores/` | See state decision tree |

### Rule 4 — Module Federation

MFEs expose entry points via Module Federation for shell integration:
- Standalone mode: full routing, own providers
- Remote mode: single route, shell-provided providers

### Rule 5 — API Layer

- One Axios instance per MFE in `api/instance.ts`
- All endpoints defined in `api/urls.ts`
- All data fetching through React Query hooks in `api/hooks/`
- No direct `fetch()` or `axios.get()` calls in components

## Integration Patterns

| Pattern | When | Implementation |
|---------|------|----------------|
| Shell ↔ Remote | MFE hosted in shell portal | Module Federation, shared provider context |
| API Gateway | Backend communication | Axios instance per MFE, environment-based URL config |
| Event Bus | Cross-MFE notification | Custom events or shared store via shell |
| Route Sync | Navigation between MFEs | Shell router manages route registration |

## Enforcement

- New features must follow the canonical folder structure
- Cross-feature imports trigger `high` severity review findings
- Shared component extraction must be justified by 2+ consumers
