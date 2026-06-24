---
applyTo: '**/*'
---

# Architecture Instructions

## Project Overview

This is a **Micro Frontend React Application** for settlement operations, built with TypeScript and designed for dual-mode operation: as a standalone application and as a federated remote module in the **mfe-shell-portal** host application via Module Federation.

### Tech Stack

- **Framework**: React 19.2.0
- **Language**: TypeScript 5.7.3
- **Build Tool**: Vite 6.2.5
- **Module Federation**: @module-federation/vite 1.9.2
- **State Management**: Zustand 5.0.11
- **API Client**: Axios 1.12.2 with @tanstack/react-query 5.90.11
- **Forms**: react-hook-form 7.67.0
- **Routing**: React Router DOM 7.10.0
- **Internationalization**: react-intl 7.1.11 (en/pt/it)
- **UI Library**: @dap-ui/stratos 3.21.3
- **Styling**: styled-components 6.3.8
- **Testing**: Vitest 3.2.4 with @testing-library/react
- **E2E Testing**: Playwright 1.57.0 with Cucumber

---

## Project Structure

```
mfe-settlement/
├── client/                    # Application source code
│   ├── api/                   # API client and service layer
│   │   ├── hooks/             # React Query hooks (useGetInstructionRequestData, etc.)
│   │   ├── instance.ts        # Axios instance configuration
│   │   └── urls.ts            # API endpoint definitions
│   ├── components/            # Shared components
│   │   ├── RHF/               # React Hook Form wrapper components
│   │   ├── ErrorBoundary/     # Error handling boundary
│   │   ├── CommonErrorState/  # Reusable error state
│   │   └── CommonEmptyState/  # Reusable empty state
│   ├── enums/                 # TypeScript enums
│   ├── hooks/                 # Custom React hooks
│   ├── layouts/               # Layout components
│   ├── models/                # TypeScript models and types
│   │   └── Language.ts        # Language enum (EN/PT/IT)
│   ├── pages/                 # Page-level components (isolated features)
│   │   ├── Instructions/      # Instructions feature
│   │   ├── InstructionCreation/
│   │   └── Detail/
│   ├── providers/             # Context providers
│   │   ├── LanguageProvider/  # React Intl configuration
│   │   ├── CsdProvider/       # CSD-specific context
│   │   └── portalStore/       # Portal store integration
│   ├── routes/                # Routing configuration
│   │   └── config.ts          # Route constants
│   ├── stores/                # Zustand state stores
│   │   └── useInstructionSearchStore.ts
│   ├── translations/          # intl message files
│   │   ├── en.json
│   │   ├── pt.json
│   │   └── it.json
│   ├── types/                 # TypeScript declarations
│   ├── utils/                 # Pure utility functions
│   ├── App.tsx                # Root application component
│   ├── AppRouter.tsx          # Router configuration
│   ├── main.tsx               # Application entry point
│   └── routeDefinitions.tsx   # Exported routes for module federation
├── e2e-tests/                 # End-to-end tests
│   ├── features/              # Cucumber feature files
│   ├── pages/                 # Page Object Models
│   ├── step-definitions/      # Step implementations
│   └── support/               # Test configuration
├── internals/                 # Build and test utilities
│   └── test/                  # Testing utilities
│       ├── test-utils.tsx     # Test helpers
│       ├── setup.ts           # Vitest setup
│       └── mocks/             # Test mocks
├── server/                    # Express server for production
├── .env                       # Environment configuration
├── vite.config.ts             # Vite and Module Federation config
└── package.json
```

---

## Architecture Principles

### 1. Core Development Principles

- Write simple, understandable code - prefer clarity over cleverness
- Add comments **only when complexity is unavoidable**
- Use meaningful names that explain intent
- Avoid premature optimization
- Extract reusable logic into custom hooks, utility functions, or shared components
- Use composition over duplication
- Centralize configuration (API URLs, routes, constants)

---

## Modular Architecture

### Isolation Principle

**CRITICAL**: Code should be isolated as much as possible. Components related to a specific feature should reside in `client/pages/feature-name/components` folder.

**Benefits:**

- Features can be replaced entirely without affecting the rest of the application
- Easier to maintain and debug
- No ripple effects across the application
- Clear ownership and boundaries

**Shared Code Locations** (use sparingly):

- `client/api/` - Only API call functions
- `client/api/hooks/` - Only React Query hooks
- `client/components/` - Only truly reusable basic components
- `client/utils/` - Only pure utility functions
- `client/models/` - Business logic models for API interactions

**Feature Organization:**

- **5+ related components**: Create subfolder in `pages/`
- Keep all feature-specific components together
- Local components should **not** be imported elsewhere

---

## Module Federation Integration

### Dual-Mode Architecture

The application operates in two modes:

1. **Standalone Mode**: Independent development server
2. **Federated Mode**: Remote module hosted by `mfe-shell-portal`

**Detection:**

```typescript
// main.tsx
export const isFederated = window.__REACT_APP_HOSTED__;
```

### Module Federation Configuration

**Location**: [vite.config.ts](vite.config.ts)

```typescript
federation({
  name: 'settlement',
  filename: 'remoteEntry.js',

  // Exposed modules
  exposes: {
    './routeDefinitions': './client/routeDefinitions.tsx',
    './App': './client/App.tsx',
    './exposedTranslations': './client/providers/LanguageProvider/exposedTranslations.ts',
  },

  // Consumed remotes
  remotes: {
    portal: {
      entry: 'remoteEntry.js',
      name: 'portal',
      type: 'module',
    },
  },

  // Shared dependencies (singleton enforcement)
  shared: {
    react: { singleton: true, requiredVersion: '^19.1.1' },
    'react-dom': { singleton: true, requiredVersion: '^19.1.1' },
    'react-router-dom': { singleton: true, requiredVersion: '^7.9.1' },
    '@dap-ui/stratos': { singleton: true },
    'styled-components': { singleton: true },
    '@tanstack/react-query': { singleton: true },
  },
});
```

**Key Integration Points:**

- **Exposed Routes**: `routeDefinitions.tsx` exported for portal integration
- **Exposed App**: Main App component for standalone rendering
- **Exposed Translations**: Language messages for portal aggregation
- **Portal Store Access**: Uses dynamic import for optional portal global store

### Portal Integration

**Portal Store Hook**: [providers/portalStore/usePortalGlobalStoreValue.ts](client/providers/portalStore/usePortalGlobalStoreValue.ts)

```typescript
// Safely access portal global store when federated
const { value, setValue } = usePortalGlobalStoreValue({
  key: 'language',
  defaultValue: Language.EN,
  missingStoreMessage: 'Portal store not available, using default',
});
```

**Benefits:**

- Graceful degradation when running standalone
- Type-safe access to portal state
- Automatic synchronization when federated

---

## Core Architectural Patterns

### 1. Provider Pattern

**Main Entry**: [main.tsx](client/main.tsx)

```typescript
<QueryClientProvider client={queryClient}>
  {!isFederated ? (
    <BrowserRouter basename={import.meta.env.VITE_CONTEXT_PATH}>
      <LanguageProvider>
        <App />
      </LanguageProvider>
    </BrowserRouter>
  ) : (
    <LanguageProvider>
      <App />
    </LanguageProvider>
  )}
</QueryClientProvider>
```

**Provider Hierarchy:**

1. **QueryClientProvider** - React Query context for server state
2. **BrowserRouter** - Routing (standalone mode only)
3. **LanguageProvider** - Internationalization (react-intl)

**Why Conditional BrowserRouter?**

- In federated mode, the portal host provides the router
- Standalone mode needs its own router instance

### 2. Internationalization (i18n)

**Framework**: react-intl (supports en/pt/it)

**Setup**: [providers/LanguageProvider/index.tsx](client/providers/LanguageProvider/index.tsx)

```typescript
import { IntlProvider } from 'react-intl';
import messages_en from '../../translations/en.json';
import messages_it from '../../translations/it.json';
import messages_pt from '../../translations/pt.json';

const messages = {
  [Language.EN]: messages_en,
  [Language.IT]: messages_it,
  [Language.PT]: messages_pt,
};

<IntlProvider
  defaultLocale={defaultLocale}
  locale={effectiveLanguage}
  messages={messages[effectiveLanguage]}
>
  {children}
</IntlProvider>
```

**Usage Pattern:**

```typescript
import { useIntl } from 'react-intl';

const MyComponent = () => {
  const intl = useIntl();

  return (
    <div>
      <h1>{intl.formatMessage({ id: 'common.title' })}</h1>
      <p>{intl.formatMessage(
        { id: 'common.greeting' },
        { name: 'User' }
      )}</p>
    </div>
  );
};
```

**Translation Files**: `client/translations/*.json`

```json
{
  "common.title": "Settlement",
  "common.greeting": "Hello, {name}",
  "instruction.create": "Create Instruction"
}
```

**Portal Language Integration**:

```typescript
// usePortalLanguage hook - syncs with portal language when federated
const { language } = usePortalLanguage(defaultLocale);
```

### 3. State Management with Zustand

**When to Use Zustand:**

- ✅ State shared across multiple features
- ✅ State that persists after component unmount (e.g., search filters)
- ✅ Complex state logic that benefits from centralization
- ❌ Local component state (use `useState` instead)
- ❌ Server state (use React Query instead)

**Store Pattern**: [stores/useInstructionSearchStore.ts](client/stores/useInstructionSearchStore.ts)

```typescript
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface InstructionSearchStoreState {
  searchData: InstructionSearchModel;
  setSearchData: (data: InstructionSearchModel) => void;
  resetSearchData: () => void;
}

const getDefaultSearchData = (): InstructionSearchModel => new InstructionSearchModel();

export const useInstructionSearchStore = create<InstructionSearchStoreState>()(
  persist(
    (set: (fn: (state: InstructionSearchStoreState) => Partial<InstructionSearchStoreState>) => void) => ({
      searchData: getDefaultSearchData(),
      setSearchData: (data: InstructionSearchModel) => set(() => ({ searchData: data })),
      resetSearchData: () => set(() => ({ searchData: getDefaultSearchData() })),
    }),
    {
      name: 'mfe-settlement-instruction-search-data',
      partialize: (state: InstructionSearchStoreState) => ({ searchData: state.searchData }),
    },
  ),
);
```

**Usage:**

```typescript
const { searchData, setSearchData } = useInstructionSearchStore();
```

**Best Practices:**

- Keep stores small and focused
- Use middleware (persist, devtools) when needed
- Prefer local state when possible
- Use TypeScript for full type safety

### 4. Form Management with React Hook Form

**Framework**: react-hook-form 7.67.0

**Custom RHF Components**: [components/RHF/](client/components/RHF/)

Provides form field wrappers that integrate:

- React Hook Form validation
- Stratos UI components
- react-intl translations
- Field-level error handling

**Available Components:**

- `RHFTaxonomyTextField` - Text input
- `RHFTaxonomyNumberField` - Numeric input
- `RHFTaxonomySelect` - Select dropdown
- `RHFTaxonomyMultiselect` - Multi-select
- `RHFTaxonomyDatePicker` - Date picker
- `RHFTaxonomyCheckbox` - Checkbox
- `RHFTaxonomyRadio` - Radio buttons
- `RHFTaxonomySwitch` - Toggle switch
- `RHFTaxonomyAutocomplete` - Autocomplete input
- `RHFTaxonomyObjectsTable` - Table with form fields
- `RHFCommonRangeNumber` - Number range input

**Base Controller**: [components/RHF/FormFieldController.tsx](client/components/RHF/FormFieldController.tsx)

```typescript
export const FormFieldController = <T extends FieldValues>({
  name,
  control,
  render,
  rules,
  defaultValue,
  shouldUnregister = false,
  disabled = false,
}: FormFieldControllerProps<T>) => {
  return (
    <Controller
      name={name}
      control={control}
      rules={rules}
      defaultValue={defaultValue}
      shouldUnregister={shouldUnregister}
      disabled={disabled}
      render={render}
    />
  );
};
```

**Usage Pattern:**

```typescript
import { useForm } from 'react-hook-form';
import { RHFTaxonomyTextField } from 'components/RHF';

const MyForm = () => {
  const { control, handleSubmit } = useForm<FormData>();

  const onSubmit = (data: FormData) => {
    // Handle form submission
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <RHFTaxonomyTextField
        name="instructionId"
        control={control}
        rules={{ required: 'Field is required' }}
        label="Instruction ID"
      />
    </form>
  );
};
```

**Benefits:**

- Consistent validation across all forms
- Integrated error messages with translations
- Type-safe form data
- Reusable field components
- Performance optimization (minimal re-renders)

### 5. API Architecture with React Query

**Axios Instance**: [api/instance.ts](client/api/instance.ts)

```typescript
import axios from 'axios';

const envBase = import.meta.env.VITE_API_BASE ?? '/settlement-api';
const baseURL = envBase.replace(/\/$/, '');

export const instance = axios.create({
  baseURL,
  withCredentials: true, // Send cookies for authentication
});
```

**React Query Hooks Pattern**: [api/hooks/useGetInstructionRequestData.ts](client/api/hooks/useGetInstructionRequestData.ts)

```typescript
import { useQuery } from '@tanstack/react-query';
import { instance } from '../instance';

const getInstructionRequestData = async (id?: string, useMocks: boolean = false) => {
  const base = 'instruction-requests';
  const path = id ? `${base}/${id}/${useMocks}` : `${base}/${useMocks}`;
  const res = await instance.get(path);
  return res.data;
};

export const useGetInstructionRequestData = (id?: string, useMocks: boolean = false, enabled: boolean = true) => {
  return useQuery({
    queryKey: ['instruction-requests', id ?? null, useMocks],
    queryFn: () => getInstructionRequestData(id, useMocks),
    enabled,
    retry: false,
    refetchOnWindowFocus: false,
    refetchOnReconnect: false,
    refetchOnMount: false,
  });
};
```

**Usage:**

```typescript
const { data, isLoading, error, refetch } = useGetInstructionRequestData(instructionId);

if (isLoading) return <Loader />;
if (error) return <ErrorState error={error} />;
return <InstructionList data={data} />;
```

**Best Practices:**

- One hook per API endpoint
- Descriptive query keys for caching
- Configure refetch behavior per use case
- Use `enabled` flag for conditional queries
- Leverage React Query DevTools in development

**Mutation Pattern:**

```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query';

export const useCreateInstruction = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: InstructionData) => instance.post('/instructions', data),
    onSuccess: () => {
      // Invalidate and refetch
      queryClient.invalidateQueries({ queryKey: ['instructions'] });
    },
  });
};
```

### 6. Routing Architecture

**Route Definitions**: [routeDefinitions.tsx](client/routeDefinitions.tsx)

Exported for module federation to allow portal integration.

```typescript
export interface RouteDescription {
  name: string | ReactNode;
  meta?: Record<string, string>;
  basePath?: string;
  route: Omit<RouteObject, 'element'> & {
    element?: ReactNode | ComponentType<Record<string, unknown>>
  };
  children?: RouteDescription[];
}

const CONTEXT_PATH = import.meta.env.VITE_CONTEXT_PATH || '';

const routeDefinitions: RouteDescription[] = [
  {
    name: 'settlement',
    meta: { id: 'common.appName' },
    basePath: import.meta.env.VITE_CONTEXT_PATH,
    route: {
      index: true,
      path: '/',
      element: <Navigate to={`${CONTEXT_PATH}/home`} replace />,
    },
  },
  // Feature routes...
];
```

**Route Organization:**

- Routes defined with metadata for portal navigation
- Lazy loading with React.lazy for code splitting
- Nested routes for complex features
- Fallback redirect to home

**AppRouter**: [AppRouter.tsx](client/AppRouter.tsx)

```typescript
// Main router component that consumes routeDefinitions
```

### 7. TypeScript Configuration

**Path Aliases**: [tsconfig.app.json](tsconfig.app.json)

```json
{
  "compilerOptions": {
    "baseUrl": "./client",
    "paths": {
      "portal/*": ["./node_modules/.vite/deps/portal/*", "./node_modules/portal/*"],
      "*": ["*", "client/*"]
    }
  }
}
```

**Benefits:**

- Import from clean paths: `import { useGetInstructionRequestData } from 'api/hooks'`
- No relative path hell: `../../../utils/helpers`
- Module federation type safety for portal imports

---

## Environment Configuration

**Environment Variables**: [.env](.env)

```bash
# API Configuration
VITE_API_BASE=/settlement-api
VITE_BACKEND_API=https://bff-settlement.int.apps.example.com

# Application Configuration
VITE_CONTEXT_PATH="/settlement"
VITE_PORT=3001

# Monitoring
VITE_METRICS_PORT=9100
VITE_LOG_LEVEL=info
```

**Server Proxy**: [vite.config.ts](vite.config.ts)

```typescript
server: {
  port: PORT,
  proxy: {
    '/settlement-api': {
      target: BACKEND_API,
      changeOrigin: true,
      secure: false,
      rewrite: (path) => path.replace(/^\/settlement-api/, '/api'),
    },
  },
}
```

**Deployment:**

- `.env` - Local development
- `values.yaml` (ops directory) - Kubernetes/OpenShift deployments
- Environment-specific overrides via ConfigMaps

---

## Testing Strategy

### Unit Testing with Vitest

**Configuration**: [vitest.config.ts](vitest.config.ts)

```typescript
export default defineConfig({
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./internals/test/setup.ts'],
    include: ['client/**/*.{test,spec}.{ts,tsx}'],
  },
  resolve: {
    alias: {
      'test-utils': resolve(__dirname, './internals/test/test-utils.tsx'),
      'portal/store': resolve(__dirname, './internals/test/mocks/portal-store.ts'),
    },
  },
});
```

**Test Utilities**: [internals/test/test-utils.tsx](internals/test/test-utils.tsx)

```typescript
export const renderWithAllProviders = (
  ui: ReactElement,
  { routerEntry = '/', path = '/' } = {}
) =>
  render(
    <MemoryRouter initialEntries={[routerEntry]}>
      <QueryClientProvider client={createTestQueryClient()}>
        <LanguageProvider>
          <Routes>
            <Route path={path} element={ui} />
          </Routes>
        </LanguageProvider>
      </QueryClientProvider>
    </MemoryRouter>
  );
```

**Testing Principles:**

1. **Isolate Dependencies** - Mock external libraries and child components
2. **Test Behavior** - Focus on business logic, not implementation details
3. **Use Providers** - Always render with `renderWithAllProviders`
4. **Mock API Calls** - Use MSW or mock React Query hooks
5. **Accessibility** - Include axe-core tests for components

**Example Test:**

```typescript
import { describe, it, expect, vi } from 'vitest';
import { renderWithAllProviders, screen } from 'test-utils';
import MyComponent from './MyComponent';

describe('MyComponent', () => {
  it('renders correctly', () => {
    renderWithAllProviders(<MyComponent />);
    expect(screen.getByText('Expected Text')).toBeInTheDocument();
  });

  it('handles user interaction', async () => {
    const handleClick = vi.fn();
    renderWithAllProviders(<MyComponent onClick={handleClick} />);

    await userEvent.click(screen.getByRole('button'));
    expect(handleClick).toHaveBeenCalled();
  });
});
```

**Accessibility Testing:**

```typescript
import { axe } from 'vitest-axe';
import { act } from '@testing-library/react';

it('has no a11y violations', async () => {
  const { container } = renderWithAllProviders(<App />);

  let results;
  await act(async () => {
    results = await axe(container);
  });

  expect(results.violations).toHaveLength(0);
});
```

**NPM Scripts:**

- `npm test` - Run tests once
- `npm run test:watch` - Watch mode
- `npm run test:coverage` - Generate coverage report

### E2E Testing with Playwright & Cucumber

**Framework**: Playwright + Cucumber BDD

**Structure**: [e2e-tests/](e2e-tests/)

```
e2e-tests/
├── features/              # Gherkin feature files
├── step-definitions/      # Step implementations
├── pages/                 # Page Object Models
├── support/               # Test configuration
└── reports/               # HTML reports
```

**Feature File Example**: [features/settlement-navigation.feature](e2e-tests/features/settlement-navigation.feature)

```gherkin
Feature: Settlement Navigation

  Scenario: User navigates to instructions page
    Given I am on the settlement home page
    When I click on "Instructions" tab
    Then I should see the instructions list
```

**Page Object Pattern**: [pages/SettlementListPage.ts](e2e-tests/pages/SettlementListPage.ts)

```typescript
export class SettlementListPage {
  constructor(private page: Page) {}

  selectors = {
    navigation: {
      instructionsTab: '[data-qa="instructions-tab"]',
    },
    table: {
      container: '[data-qa="instructions-table"]',
      row: 'tbody tr',
    },
  };

  async clickInstructionsTab() {
    await this.page.click(this.selectors.navigation.instructionsTab);
  }

  async isTableVisible() {
    return await this.page.isVisible(this.selectors.table.container);
  }
}
```

**Selector Convention**: `domain.component.element-type`

- Example: `settlement.table.delete-button`
- Prefer `data-qa` attributes for stability

**NPM Scripts:**

- `npm run test:e2e` - Run E2E tests and open report
- `E2E_BASE_URL=http://localhost:3000 npm run test:e2e` - Custom URL

**Detailed Guidelines**: See [.github/instructions/e2e-testing.instructions.md](.github/instructions/e2e-testing.instructions.md)

---

## UI Component Patterns

### Stratos Design System

All UI components use **@dap-ui/stratos** design system.

**Detailed Guidelines**: See [.github/instructions/stratos.instructions.md](.github/instructions/stratos.instructions.md)

**Common Components:**

- **Layout**: `VerticalFlex`, `HorizontalFlex`, `ResponsiveGrid`
- **Typography**: `HeadingL`, `HeadingM`, `RegularTextM`
- **Actions**: `Button`, `IconButton`, `Link`
- **Forms**: `TextField`, `Select`, `DatePicker`, `Checkbox`
- **Feedback**: `Toast`, `Banner`, `Loader`, `StatusBadge`
- **Navigation**: `Tabs`, `Breadcrumb`, `Stepper`
- **Structure**: `Table`, `Card`, `Modal`, `Accordion`

**Example:**

```typescript
import { VerticalFlex, Space, HeadingM, Button } from '@dap-ui/stratos';

<VerticalFlex $gap={Space.V16}>
  <HeadingM>Section Title</HeadingM>
  <Button variant="primary" onClick={handleClick}>
    Submit
  </Button>
</VerticalFlex>
```

### Custom Component Guidelines

**Reusable Components** (`client/components/`):

- Only truly generic, reusable components
- Examples: `CommonErrorState`, `CommonEmptyState`, `AccessibleLoader`

**Feature Components** (`client/pages/feature-name/`):

- Feature-specific components
- Should not be imported by other features
- Extract to `components/` only when needed by 2+ features

---

## Best Practices Summary

### Development

1. **Component Size**
   - Optimal: ~150 lines
   - Warning: >200 lines (consider refactoring)
   - Critical: >300 lines (requires refactoring)

2. **Code Organization**
   - Feature-specific code in `pages/`
   - Shared code only when truly reusable
   - Extract complex logic into custom hooks

3. **Type Safety**
   - **Never use `any`** - Use proper TypeScript types
   - Define models in `client/models/`
   - Use generics for reusable logic

4. **Naming Conventions**
   - PascalCase: Components, Types, Interfaces
   - camelCase: Functions, variables, hooks
   - UPPER_SNAKE_CASE: Constants
   - English only for all code and comments

5. **Imports**
   - Use path aliases: `import { X } from 'api/hooks'`
   - Group imports: external → internal → relative
   - Order: React → libraries → local

6. **Implementation Verification**
   - **ALWAYS** run `npm run lint` - must pass with 0 errors
   - **ALWAYS** run `npm run build` - must complete without TypeScript errors
   - Run both before every commit: `npm run lint && npm run build`
   - See [Development Workflow](#implementation-verification) for details

### State Management

**Decision Tree:**

```
Need state?
├─ Server data? → Use React Query
├─ Form data? → Use React Hook Form
├─ Shared across features? → Use Zustand
├─ Portal integration data? → Use usePortalGlobalStoreValue
└─ Local to component? → Use useState/useReducer
```

**Rules:**

- Prefer local state when possible
- Keep Zustand stores small and focused
- Never duplicate server state (use React Query)
- Use TypeScript for all state types

### Form Handling

1. **Always Use React Hook Form** for forms with validation
2. **Use RHF Wrapper Components** from `components/RHF/`
3. **Type Form Data** with TypeScript interfaces
4. **Validate on Blur** for better UX
5. **Handle Errors** with translated messages

### API Calls

1. **One Hook Per Endpoint** in `api/hooks/`
2. **Use React Query** for all server state
3. **Configure Caching** based on data freshness needs
4. **Handle Errors** at component level
5. **Use QueryClient** to invalidate caches after mutations

### Testing

1. **Mock Dependencies** - Isolate component under test
2. **Test Behavior** - Not implementation details
3. **Use renderWithAllProviders** - Consistent test setup
4. **Include A11y Tests** - Run axe-core checks
5. **Aim for Coverage** - Focus on critical paths

### Internationalization

1. **All User-Facing Text** must be translated
2. **Use react-intl** `useIntl` hook
3. **Message IDs** follow pattern: `domain.feature.key`
4. **Provide All Languages** (en/pt/it)
5. **Test with Different Locales**

### Performance

1. **Lazy Load Routes** with React.lazy
2. **Minimize Bundle Size** - Check bundle analyzer
3. **Optimize Images** - Use appropriate formats
4. **Memoize Expensive Calculations** - `useMemo`
5. **Prevent Unnecessary Renders** - `React.memo` for pure components

---

## Module Federation Checklist

When integrating with `mfe-shell-portal`:

### 1. Vite Configuration

- ✅ Module federation plugin configured
- ✅ Correct remote name: `settlement`
- ✅ Exposed modules: `routeDefinitions`, `App`, `exposedTranslations`
- ✅ Shared dependencies marked as singleton

### 2. Route Definitions

- ✅ Export `routeDefinitions` from [routeDefinitions.tsx](client/routeDefinitions.tsx)
- ✅ Include route metadata for portal navigation
- ✅ Use `VITE_CONTEXT_PATH` for base path

### 3. Translations

- ✅ Export translations via `exposedTranslations.ts`
- ✅ Support all required languages (en/pt/it)

### 4. Portal Store

- ✅ Use `usePortalGlobalStoreValue` for portal state access
- ✅ Provide defaults for standalone mode
- ✅ Handle missing portal store gracefully

### 5. Testing

- ✅ Test both standalone and federated modes
- ✅ Mock portal dependencies in unit tests
- ✅ Verify routing works in both modes

### 6. Environment Variables

- ✅ Set `VITE_CONTEXT_PATH` correctly
- ✅ Configure `VITE_API_BASE` for BFF routing
- ✅ Update values.yaml for deployments

---

## Development Workflow

### Local Development

```bash
# Start development server (standalone mode)
npm run dev

# Runs on port from .env (default: 3001)
# Access at: http://localhost:3001/settlement
```

### Building

```bash
# Type check and build for production
npm run build

# Output: dist/ directory
# Includes: remoteEntry.js for module federation
```

### Linting

```bash
# Check code quality
npm run lint

# Auto-fix issues
npm run lint:fix
```

### Testing

```bash
# Unit tests
npm test
npm run test:watch
npm run test:coverage

# E2E tests
npm run test:e2e
```

### Implementation Verification

**MANDATORY:** After every code implementation (new features, bug fixes, refactoring), you MUST verify:

1. **Build Success:**

   ```bash
   npm run build
   ```

   - ✅ Must complete without TypeScript compilation errors
   - ✅ All modules must transform successfully
   - ⚠️ Build warnings are acceptable, errors are NOT

2. **Lint Success:**

   ```bash
   npm run lint
   ```

   - ✅ Must complete with 0 errors
   - ⚠️ Warnings are acceptable (but should be minimized)
   - ❌ Never commit code with lint errors

3. **Verification Order:**
   - First: `npm run lint` (fast feedback on code quality)
   - Then: `npm run build` (verify TypeScript compilation)
   - Finally: Test the changes manually or with automated tests

**Failure Handling:**

- If build fails → Fix TypeScript errors before proceeding
- If lint fails with errors → Fix critical issues immediately
- If tests fail → Fix broken functionality before committing

**Best Practice:** Run `npm run lint && npm run build` before every commit to ensure code quality.

---

## Deployment

### Build Artifacts

- **dist/** - Production build
- **remoteEntry.js** - Module federation entry point
- **asset-manifest.json** - Asset mapping for portal

### Environment Configuration

Deployments use environment-specific configuration:

- **Development**: `.env` file
- **QA/Production**: Kubernetes ConfigMaps + values.yaml

### Docker

**Dockerfile** uses Node 22 base image:

- Copies application source
- Runs `npm run preview` for production server
- Exposes port 8080

### Kubernetes

**Resource Requirements:**

- CPU: 1 core (request & limit)
- Memory: 1Gi (request & limit)

**Volumes:**

- Trusted CA certificates: `/etc/nginx/certs`

---

## Additional Resources

- **Design System**: [Stratos Documentation](.github/instructions/stratos.instructions.md)
- **E2E Testing**: [E2E Testing Guide](.github/instructions/e2e-testing.instructions.md)
- **API Documentation**: [Swagger/OpenAPI] (if available)
- **Portal Integration**: [fe-shell-portal Documentation]

---

## Troubleshooting

### Common Issues

**Module Federation Errors:**

- Ensure shared dependencies versions match host
- Check `remoteEntry.js` is accessible
- Verify singleton enforcement for React/ReactDOM

**Portal Store Not Available:**

- Expected in standalone mode
- Check `usePortalGlobalStoreValue` provides defaults
- Verify dynamic import path: `portal/store`

**Translation Missing:**

- Check message ID exists in all language files
- Verify language fallback to `en`
- Use `intl.formatMessage` with default message

**Build Errors:**

- Run `npm run lint` to catch type errors
- Check TypeScript version compatibility
- Verify all imports resolve correctly

---

## Notes

This architecture is designed for:

- **Scalability** through modular, feature-based organization
- **Maintainability** through isolation and clear boundaries
- **Type Safety** through comprehensive TypeScript usage
- **Developer Experience** through tooling, conventions, and documentation
- **Flexibility** between standalone and federated deployment modes
- **Quality** through comprehensive testing strategies (unit, integration, E2E, a11y)

**Core Philosophy**: Keep it simple, avoid duplication, maintain single responsibility, and always prioritize developer experience and code maintainability.
