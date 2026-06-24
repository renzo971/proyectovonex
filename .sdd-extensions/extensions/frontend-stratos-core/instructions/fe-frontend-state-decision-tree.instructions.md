---
applyTo: "**/*.{tsx,ts,jsx}"
---
# Frontend State Decision Tree

## Purpose

Provide a deterministic decision framework for where application state belongs. Every state decision must be recorded in feature artifacts.

## Decision Tree

```
Is this state needed outside the current component?
├── NO → Local State (useState / useReducer)
│
├── YES → Is it fetched from an API?
│   ├── YES → Server State (React Query / TanStack Query)
│   │   └── Cache managed by query key, revalidation policy
│   │
│   └── NO → Is it navigation-relevant or shareable via URL?
│       ├── YES → URL State (search params / route params)
│       │
│       └── NO → Is it needed across multiple features?
│           ├── YES → Global Store (Zustand / Redux Toolkit)
│           │   └── Only for cross-feature state, user session, app config
│           │
│           └── NO → Feature-scoped Store or Context
│               └── Zustand store in feature folder, or React Context
```

## State Categories

| Category | Tool | Location | Lifetime | Example |
|----------|------|----------|----------|---------|
| **Local** | `useState`, `useReducer` | Component file | Component mount | Form field values, toggle visibility |
| **Server** | `@tanstack/react-query` | `api/hooks/` | Cache + refetch | API responses, pagination data |
| **URL** | `useSearchParams`, `useParams` | Route config | Navigation | Current filter, selected item ID |
| **Global** | Zustand / Redux Toolkit | `stores/` | App session | User context, feature flags, search criteria |
| **Feature-scoped** | Zustand store / Context | `pages/<Feature>/` | Feature mount | Complex form state, wizard step |

## Rules

### Rule 1 — Default to Local
Start with `useState`. Elevate only when a explicit need arises.

### Rule 2 — API Data is Always Server State
Never put API response data into Zustand/Redux. Use React Query for caching, refetching, and optimistic updates.

### Rule 3 — Redux/Zustand Only for Derived Cross-Feature State
Global store is for:
- Search criteria shared between list and detail views
- User session context
- Feature flags or app configuration
- Sidebar/navigation state

### Rule 4 — No State Duplication
The same data must not live in both server cache and global store. Pick one source of truth.

### Rule 5 — Form State Stays Local
Form state managed by `react-hook-form` or `useState`. Do not sync form fields to global store unless search criteria must persist across navigation.

## Recording Requirement

When making a state location decision, record it:

```markdown
## State Decision: [State Name]

**Date:** [ISO date]
**Category:** Local | Server | URL | Global | Feature-scoped
**Tool:** useState | React Query | useSearchParams | Zustand | Context
**Rationale:** [Why this category]
**Consumers:** [Which components use this state]
```

Write to the feature's `decisions.md` for non-trivial state (global, feature-scoped).

## Enforcement

- Review agents must verify state location matches the decision tree
- Misplaced state (e.g., API data in Redux) is a `high` severity finding
- Missing state decision documentation for global/feature-scoped state is `medium` severity
