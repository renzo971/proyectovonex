---
applyTo: '**/*'
---

# Project general coding standards

- Use PascalCase for component names, interfaces, classes, and type aliases
- Use camelCase for variables, functions, and methods
- Use a maximum of 4 words when naming things
- Use try/catch blocks for async operations
- Avoid inline functions - extract to named functions or custom hooks for better readability and testability

## Code Formatting

- All formatting issues should be validated by running `npm run lint`
- ESLint configuration (.eslintrc.cjs) is the source of truth for code formatting rules
- Do NOT report formatting issues that ESLint does not flag

## File Size Management

- Files under 150 lines: No issues
- Files between 150-300 lines (Low Priority): Evaluate for possible refactoring or splitting
- Files over 300 lines (High Priority): Refactoring required to improve maintainability

## File Naming Convention

- Use **camelCase** for all file names (e.g. `restrictionRequest.ts`, `useRestrictionStore.ts`)
- **Never use kebab-case** (hyphens) in file names (e.g. ~~`restriction-request.ts`~~)
- Exception: config/tooling files at project root follow their ecosystem convention (e.g. `vite.config.ts`, `eslint.config.js`)

## Code Formatting (Low Priority)

- Insert an empty line to separate multiline code blocks from the next statement

## Function Declaration

- **Avoid inline functions** - Extract to named functions for better readability, debugging, and testability
- Inline functions are acceptable only for simple callbacks (e.g., `.map()`, `.filter()`) with 1-2 lines
- For event handlers, API calls, complex logic, and JSX expressions, always use named functions or custom hooks

**Bad - Event handlers:**

```typescript
<Button onClick={() => {
  setLoading(true);
  apiCall().then(data => setData(data));
}}>Submit</Button>
```

**Good - Event handlers:**

```typescript
const handleSubmit = async () => {
  setLoading(true);
  const data = await apiCall();
  setData(data);
};

<Button onClick={handleSubmit}>Submit</Button>
```

**Bad - JSX expressions:**

```typescript
<Label
  content={(() => {
    const messageId = taxonomy.parentAttributeId ? taxonomy.displayName : taxonomy.name;
    return messageId && intl.messages[messageId] ? formatMessage({ id: messageId }) : label;
  })()}
  required={isRequired}
/>
```

**Good - JSX expressions:**

```typescript
const getLabelContent = (): string => {
  const messageId = taxonomy.parentAttributeId ? taxonomy.displayName : taxonomy.name;
  return messageId && intl.messages[messageId] ? formatMessage({ id: messageId }) : label || '';
};

<Label
  content={getLabelContent()}
  required={isRequired}
/>
```

**Acceptable - Simple transformations:**

```typescript
// OK: Simple 1-line transformations in .map()
const items = data.map((item) => ({ ...item, formatted: true }));

// OK: Simple predicates in .filter()
const activeUsers = users.filter((user) => user.active);
```

## Internationalization (i18n)

- **Never hardcode user-facing text** - All text visible to users must be translated using react-intl
- **Always add translation keys to ALL language files** in `client/translations/`:
  - `en.json` (English)
  - `pt.json` (Portuguese)
  - `it.json` (Italian)
- Use the `useIntl` hook from `react-intl` for all translations
- Follow the message key pattern: `domain.feature.key`

**Bad:**

```typescript
<Button>Submit</Button>
<h1>Create Instruction</h1>
```

**Good:**

```typescript
import { useIntl } from 'react-intl';

const MyComponent = () => {
  const intl = useIntl();

  return (
    <>
      <h1>{intl.formatMessage({ id: 'instruction.create.title' })}</h1>
      <Button>{intl.formatMessage({ id: 'common.submit' })}</Button>
    </>
  );
};
```

**Translation files (client/translations/):**

```json
// en.json
{
  "instruction.create.title": "Create Instruction",
  "common.submit": "Submit"
}

// pt.json
{
  "instruction.create.title": "Criar Instrução",
  "common.submit": "Enviar"
}

// it.json
{
  "instruction.create.title": "Crea Istruzione",
  "common.submit": "Invia"
}
```
