---
applyTo: "**/*.ts,**/*.tsx"
---
# Project coding standards for React
- Use functional components with hooks
- Follow the React hooks rules (no conditional hooks)
- Use React FC type for components
- Keep components small and focused

## Async State Updates
- Prefer pessimistic updates over optimistic updates for data mutations
- Update state only after successful API response
- Use loading states and disabled UI elements to provide clear feedback during operations
- This ensures UI consistency and eliminates the need for error rollback logic

## Error Handling
- Always provide user feedback for API errors using ToastContext
- Never use console.error as the only error handling mechanism
- Use showErrorToast with translated error messages
- Map HTTP status codes to user-friendly messages via apiErrors translations

## Hook Dependencies (useEffect, useMemo, useCallback)
- Empty dependency arrays [] are acceptable when operations should run only on mount (useEffect) or when values should never re-compute (useMemo/useCallback)
- Include only dependencies that should trigger re-execution or re-computation
- Stable functions from custom hooks (like useCover's reloadData) can be intentionally omitted if they shouldn't trigger re-runs
- Exception: Pure helper functions defined outside the component don't need to be included
- Translation functions from useTranslate() are stable and don't need to be included in dependency arrays
- Do NOT report missing dependencies for stable functions like translation helpers or pure functions

## Placeholder Code
- Never use console.log as onClick handler or event callback
- Use empty arrow functions with TODO comments for unimplemented functionality
- Example: onClick={() => { /* TODO: Implement functionality */ }}
- Remove placeholders before production release

## Partial Component Implementation
- Avoid partial component implementations with commented code and empty handlers
- Use string placeholders in parent component instead until feature is ready for full implementation
- Partial implementations with unused state, commented sections, and empty handlers create maintenance burden
- Example: Prefer `element={'<Component />'}` over a component file with commented modal code

## Translation Labels
- Translation label capitalization changes are acceptable and typically low priority
- Verify consistency within the same category (e.g., all field labels should follow the same pattern)
- Both sentence case and title case are acceptable as long as they're used consistently
- Translation values don't need to match enum names exactly - grammatical correctness takes priority

## Test Coverage (High Priority)
- Missing test files for new components, hooks, or utilities must be flagged as high priority
- Every new testable code file should have a corresponding test file
- Test files should follow the naming convention: `*.test.ts`, `*.test.tsx`, or `*.spec.ts`, `*.spec.tsx`

## Testing with Vitest
- Use `expect(screen.getByText(...))` without additional assertions like `.toBeInTheDocument()`
- The `getByText`, `getByRole`, and other `getBy*` queries throw errors if elements are not found, making the test fail automatically
- This pattern is sufficient for basic render tests and is the project standard
- Example: `expect(screen.getByText('Button'));` is correct and will fail if 'Button' is not rendered
