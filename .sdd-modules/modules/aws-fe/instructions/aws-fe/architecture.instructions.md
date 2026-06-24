---
applyTo: "**/*"
---
# Architecture Instructions

## Project Overview

This is a **Micro Frontend React Application** built with TypeScript, designed to be integrated into the dap-portal host application. The architecture follows a modular, scalable approach with strict separation of concerns.

### Tech Stack

- **Framework**: React 19.2.3
- **Language**: TypeScript 5.9.3
- **Build Tool**: Vite
- **State Management**: Redux Toolkit 2.11.1
- **Routing**: React Router DOM 7.10.1
- **Internationalization**: i18next 25.7.2
- **HTTP Client**: Axios 1.13.2
- **UI Library**: @dap-ui/stratos 3.21.3
- **Testing**: Vitest with @testing-library/react

---

## Project Structure

```
src/
├── api/              # API client and service layer
├── components/       # Shared components and providers
├── helpers/          # Pure utility functions
├── i18n/             # Internationalization resources
├── models/           # TypeScript models and types
├── pages/            # Page-level components (isolated features)
├── routes/           # Routing configuration
├── store/            # Redux state management
├── App.tsx           # Root application component
└── index.tsx         # Application entry point
```

---

## Architecture Principles

### 1. Micro Frontend Integration

The application is designed as a standalone micro-frontend that can be:
- Integrated into the dap-portal host application
- Run independently in development mode

**Key Integration Points**:
- **Mount/Unmount Functions**: Exposed via `window.renderMYAPP` and `window.unmountMYAPP`
- **App Trigram**: Configure `appTrigram` in [models/core.ts](src/models/core.ts) to match portal integration
- **Base Path**: Set in [package.json](package.json) `config.base` for deployment paths
- **Port Configuration**: Set unique port in `config.port` for local multi-app development

### 2. Modular Architecture

**Isolation Principle**: Code should be isolated as much as possible. Components related to a specific feature should reside in `src/pages/section-name` folder.

**Benefits**:
- Features can be replaced entirely without affecting the rest of the application
- Easier to maintain and debug
- No ripple effects across the application

**Shared Code Locations** (use sparingly):
- `src/api/` - Only API XHR call functions
- `src/components/` - Only truly reusable basic components
- `src/helpers/` - Only pure utility functions
- `src/models/` - Business logic models for API interactions

### 3. Component Size Guidelines

- **Optimal**: ~150 lines of code
- **Warning**: >200 lines - consider refactoring
- **Monolith**: >300 lines - requires immediate refactoring

---

## Core Architectural Patterns

### 1. Provider Pattern

All application providers are composed in [AppProviders](src/components/AppProviders/AppProviders.tsx) using a reducer pattern:

```typescript
const providers = [
  BrowserRouter,
  ReduxProvider,
  ErrorBoundary,
  ToastProvider,
  BannerProvider,
  ConfigProvider,
  EnvProvider,
];
```

**Provider Hierarchy**:
1. **BrowserRouter** - Routing context
2. **ReduxProvider** - Global state management
3. **ErrorBoundary** - Error handling with fallback UI
4. **ToastProvider** - Toast notification system
5. **BannerProvider** - Banner notification system
6. **ConfigProvider** - Application configuration (auth tokens, base path)
7. **EnvProvider** - Environment-specific configuration (API URLs)

### 2. Configuration Management

**Two-Level Configuration System**:

#### ConfigProvider
- Provides `AppConfig` via React Context
- Contains runtime configuration from portal:
  - `host` - Base path for the application
  - `getAccessToken()` - OAuth access token retrieval
  - `getIdToken()` - OAuth ID token retrieval

#### EnvProvider
- Loads environment configuration from `public/env.json`
- Environment-specific settings:
  - `apiUrl` - Backend API endpoint
- Initializes API client with authentication
- Shows loading state while fetching configuration

**Environment Files**:
- **Local**: `public/env.json` (mock server by default)
- **Deployed**: Replaced by CI/CD pipeline per environment (dev, qa, prod)

### 3. State Management Pattern

**Redux Toolkit with Slice Pattern**:

Located in `src/store/`, organized by domain:

```
store/
├── core/
│   └── slice.ts       # Core domain slice
├── types.ts           # Root state types
└── index.ts           # Store configuration
```

**Slice Structure**:
- State class definition
- Reducers with PayloadAction typing
- Selectors for accessing state
- Export actions and reducer

**When to Use Redux**:
- ✅ State shared across multiple macro-areas (e.g., user authentication)
- ✅ Data needs to persist after component unmount (e.g., API cache)
- ❌ Local component state (use `useState` instead)
- ❌ Non-serializable values (Date, File) - use local state

**Trade-offs**:
- More development effort required
- More complex testing
- Only serializable values supported

### 4. API Architecture

**Centralized API Client** ([api/ApiClient.ts](src/api/ApiClient.ts)):

- Gateway-based API routing via `AppGateway` enum
- Automatic token injection via Axios interceptors
- Typed HTTP methods: `sendGet`, `sendPost`, `sendPut`, `sendPatch`, `sendDelete`
- Generic response typing for type safety

**API Service Layer** ([api/UserAPI.ts](src/api/UserAPI.ts)):
- Domain-specific API functions
- Use centralized client methods
- Handle request/response transformations

**Setup Flow**:
1. EnvProvider loads `env.json`
2. Calls `setupAPI(apiUrl, config)` to configure API client
3. Axios interceptor injects Bearer token on each request

### 5. Routing Architecture

**Route Organization** ([routes/](src/routes/)):

```
routes/
├── AppRoutes.tsx      # Main route component with Suspense
├── config.ts          # Route path constants
└── homeRoutes.tsx     # Feature-specific routes
```

**Route Configuration**:
- Routes defined as constants in `config.ts` using base path from package.json
- Feature routes split into separate files
- Lazy loading with Suspense boundary
- Fallback redirect to HOME route

**Pattern**:
```typescript
export const ROUTES = {
  HOME: `${base}/home`,
  // Add your application routes here
};
```

### 6. Internationalization (i18n)

**Setup** ([i18n/index.tsx](src/i18n/index.tsx)):
- i18next with React integration
- Browser language detection via cookie and navigator
- Fallback language: English
- Translation files: `i18n/en.json`

**Custom Hook**:
```typescript
const t = useTranslate();
t('key.path', 'default value', { param: value });
```

**Benefits**:
- Type-safe translation function
- Default message support
- Interpolation with typed parameters

### 7. Path Aliasing

**Configured in** [vite.config.ts](vite.config.ts):

```typescript
resolve: {
  alias: [
    { find: 'api', replacement: 'src/api' },
    { find: 'components', replacement: 'src/components' },
    { find: 'helpers', replacement: 'src/helpers' },
    { find: 'i18n', replacement: 'src/i18n' },
    { find: 'models', replacement: 'src/models' },
    { find: 'pages', replacement: 'src/pages' },
    { find: 'routes', replacement: 'src/routes' },
    { find: 'store', replacement: 'src/store' },
  ],
}
```

**Usage**: Import from aliased paths instead of relative paths
```typescript
import { UserAPI } from 'api';
import { useTranslate } from 'i18n';
```

---

## Key Components

### AppProviders

**Location**: [components/AppProviders/AppProviders.tsx](src/components/AppProviders/AppProviders.tsx)

Composes all application-level providers using a reducer pattern to avoid deeply nested JSX.

### ConfigProvider

**Location**: [components/ConfigProvider/ConfigProvider.tsx](src/components/ConfigProvider/ConfigProvider.tsx)

Provides `AppConfig` object via React Context containing:
- `host` - Base URL path
- `getAccessToken()` - OAuth token retrieval
- `getIdToken()` - ID token retrieval

### EnvProvider

**Location**: [components/EnvProvider/EnvProvider.tsx](src/components/EnvProvider/EnvProvider.tsx)

Responsibilities:
- Fetches `env.json` from public folder
- Initializes API client with environment configuration
- Shows loading/error states during initialization
- Provides environment configuration via Context

### Common UI States

**CommonErrorState**: Reusable error state component with reload functionality
**CommonEmptyState**: Reusable empty state component for no-data scenarios

---

## Development Patterns

### 1. Type Safety

- **Never use `any`**: Use proper TypeScript types
- **Model-Driven**: Define models in `src/models/` for all domain entities
- **Generic API Responses**: Type API responses using generics

### 2. Error Handling

**Pattern 1: Using `useCover` Hook**

```typescript
const { loading, reloadData, errorCode } = useCover(
  async(search: SearchModel) => {
    const data = await getDataAPI(search, csd);
    setData(data);
  },
);
```

- Use for page-level data loading (tabs, lists)
- Second parameter converts error codes to strings for i18n
- Renders error states automatically via `errorMessage`

**Pattern 2: Direct API Calls**

```typescript
try {
  showProgressToast(t('common.loading'));
  await actionAPI(id, csd, params);
  showSuccessToast(t('common.successMessage'));
  await reloadData();
} catch (error) {
  const errorResponse = (error as AxiosError)?.response;
  const errorMessage = t(`apiErrors.${errorResponse?.status}.text`, t('common.genericErrorText'));
  showErrorToast(errorMessage);
}
```

- Use for button actions, modals, form submissions
- Template literals auto-convert status to string
- Map to i18n keys: `apiErrors.${status}.text`
- Always provide fallback message

### 3. Validation

**Helper Function**:

```typescript
getTranslatedValidation(t, fields, i18nPrefix)
```

- Converts API validation errors to translated field-level messages
- Returns `ValidationFieldMap` for form field mapping

### 4. Code Organization

**Component with Complex Logic**:
- Extract logic into custom hooks
- Place hooks in same folder as component
- Keep component file focused on rendering

**Feature Organization** (5+ components):
- Create subfolder in `pages/`
- Keep all related components together
- Local components should not be imported elsewhere

### 5. KISS Principle

- Keep code simple and understandable
- Add comments only when complexity is unavoidable
- Prefer clarity over cleverness

---

## Testing Strategy

### Test Configuration

**Framework**: Vitest with jsdom environment
**Location**: All tests in `src/**/*.test.{ts,tsx}`
**Setup**: [setupTests.tsx](src/setupTests.tsx)

### Testing Principles

1. **Mock Dependencies** - Isolate from external libraries
2. **Mock Child Components** - Test component logic only
3. **Test Business Logic** - Focus on behavior, not styling
4. **Use Test Blocks** - `beforeAll` and `beforeEach` to reduce redundancy
5. **Measure Complexity** - Hard-to-test code indicates need for refactoring

### Test Utilities

**Location**: [TestTools.tsx](src/TestTools.tsx)

```typescript
// Render with all providers
renderWithProviders(component)

// Render with mocked toast and banner
const { instance, mockToast, mockBanner } = renderWithMocks(component)
```

### Coverage

**Command**: `npm run coverage`
**Thresholds**: Currently set to 0% (should be increased per project needs)

---

## Build and Development

### NPM Scripts

- `npm start` - Start development server with mock API (port 8090)
- `npm run build` - Production build
- `npm run lint` - Check code quality
- `npm run lint:fix` - Auto-fix linting issues
- `npm test` - Run unit tests
- `npm run coverage` - Generate coverage report

### Build Configuration

**Output**: `build/` directory
**Manifest**: `asset-manifest.json` for module federation
**Chunk Size Warning**: 2500KB limit

### Mock API

Uses `jgloo` for local API mocking on port 8090.
Mock definitions: `mock/api/` directory

---

## Best Practices Summary

### Development

1. **Refactor Early** - Keep files under 300 lines
2. **Isolate Features** - Use `pages/` for feature-specific code
3. **Minimize Shared Code** - Only share truly reusable utilities
4. **KISS Principle** - Simple, commented code when needed
5. **Minimize Redux** - Prefer local state when possible
6. **Organize by Feature** - Subfolder for 5+ related components
7. **Extract Complex Logic** - Use custom hooks for business logic
8. **English Only** - All code, comments, and file names
9. **Avoid `any` Type** - Track and fix typing issues
10. **Minimize Dependencies** - Each package adds maintenance burden

### State Management

- Local state (`useState`) for component-specific data
- Redux only for:
  - Cross-feature shared state
  - Cached/persistent data
- Keep state serializable

### Testing

- Mock all dependencies and child components
- Focus on business logic, not presentation
- Use test difficulty as refactoring indicator

---

## Integration Checklist

When creating a new application from this kit:

1. **package.json**:
   - Set `config.base` to deployment path
   - Set `config.port` to unique local port

2. **src/models/core.ts**:
   - Update `appTrigram` to match portal configuration

3. **src/index.tsx**:
   - Update `renderMYAPP` and `unmountMYAPP` method names

4. **index.html**:
   - Update render and host references

5. **public/env.json**:
   - Configure local `apiUrl` (default: mock server)

6. **dap-portal**:
   - Add widget configuration
   - Match `appTrigram` in portal settings

---

## Additional Resources

- **Design System**: @dap-ui/stratos components library
- **Build Tool**: @dap-ui/gear for build, lint, test commands
- **Mock Server**: jgloo for local API mocking

---

## Notes

This architecture is designed for:
- Scalability through modular design
- Maintainability through isolation
- Type safety through TypeScript
- Developer experience through tooling and conventions
- Integration flexibility between standalone and micro-frontend modes
