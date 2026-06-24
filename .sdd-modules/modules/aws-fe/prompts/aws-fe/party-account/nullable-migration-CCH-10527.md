---
agent: neo 
---

# Nullable Fields Migration Guide

> **Scope**: These changes apply to any model that can **ever be assigned data originating from a backend response**:
> - **API response models** (e.g. list/overview items received from the backend).
> - **Form models that are pre-filled with API response data** — even if the same model is also used for creation. If the model can receive a `null` field in the update flow, it must be nullable throughout.
>
> Do **not** apply to models that are **only ever constructed locally** (i.e. never assigned API response data) — those should keep their default empty string values to remain functional. Examples:
> - **Search/filter models** — built entirely from user input and passed as query parameters to the API, never populated from a response.
> - **Taxonomy/options models** — assembled locally from API response data but mapped into a fixed structure, never directly assigned from a response.

## 0. Discovery — Identify all qualifying models before making any changes

Before applying any changes, search the codebase to build a complete list of models in scope. Do **not** skip this step.

**A. API response models** — find classes in `src/models/` that are used as return types of API functions in `src/api/`:
```ts
// Look for patterns like:
return sendGet<SomeModel>(...)
return sendPost<SomeModel>(...)
```

**B. Form models pre-filled with API response data** — find classes in `src/models/` that are assigned API response data in page hooks or page components. Look for these patterns:
```ts
// A local form variable is initialised empty, then overwritten with an API response:
let sourceForm = new SomeSetupDataModel();
if (isUpdate) {
  const response = await getSomeRequestAPI(...);
  sourceForm = response;   // ← response (which extends SomeSetupDataModel) is assigned here
}

// Also check classes that are extended by request/response models:
class SomeRequestModel extends SomeSetupDataModel { ... }
// → SomeSetupDataModel is in scope because it can receive API data via the assignment above
```

Grep for `extends` in `src/models/` to catch base models used by request models. Any class that is a base of a request/response model inherits the same API-data exposure.

After discovery, list all found models explicitly before proceeding to Step 1.

## 1. Models — Make fields nullable

Only migrate fields that are **`string` in the Swagger definition**. This covers two TypeScript representations:

- **Plain strings** — fields typed as `string` and defaulting to `''`
- **Frontend enums** — fields that are `string` in the API but mapped to a TypeScript enum on the client side

```ts
// Before
id = '';                      // string in Swagger
status = SomeStatus.DRAFT;    // string in Swagger, enum on the client

// After
id: string | null = null;
status: SomeStatus | null = null;
```

## 2. API functions — Update signatures to accept `string | null`

```ts
// Before
async function doSomethingAPI(id: string, clientId: string, csd: string)

// After
async function doSomethingAPI(id: string | null, clientId: string | null, csd: string)
```

## 3. `generatePath` calls — Use `?? ''` to fallback nullable IDs to empty string

```ts
generatePath(ROUTES.SOME_ROUTE, {
  id: item.id ?? '',
  clientId: item.clientId ?? '',
})
```

## 4. List row keys — Replace `item.id` with index-based keys (since `id` is now nullable)

```ts
// Before
items.map((item) => ({ key: item.id, ... }))

// After
items.map((item, index) => ({ key: `row-${index}`, ... }))
```

## 5. Badge/status components — Conditionally render when status is nullable

```tsx
// Before
<SomeBadge status={item.status} />

// After
{item.status && <SomeBadge status={item.status} />}
```

## 6. Text/input components — Use `?? ''` fallback for nullable string props

```tsx
// Before
<TextField value={model.name} />

// After
<TextField value={model.name ?? ''} />
```
