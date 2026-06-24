# api-patterns

Purpose: decision framework for REST API design — resource hierarchy, versioning, status codes, workflow transitions, search/pagination, error envelopes, and backward-compatible schema evolution.

## When to Use

- Designing new REST endpoints or modifying existing OpenAPI specs.
- Operator triggers via `sdd skill run api-patterns <feature-id>`.
- The api-champion agent loads this skill during Phase 2.2 contract definition.

## Decision Framework

For each endpoint, answer in order:

1. **Resource or sub-resource?** Nest only when the child has no independent lifecycle; otherwise promote to top-level.
2. **Naming:** plural resource names, kebab-case paths, descriptive identifiers when more than one `{id}` appears.
3. **Versioning:** prefer path-based (`/v1/`); use header-based only if the constitution explicitly requires it. Increment major version only for breaking changes.
4. **Method + status code:** GET read (`200`), POST create (`201` + `Location`), POST trigger (`202`), PUT replace (`200`), PATCH partial (`200`), DELETE remove (`204`). Use `409` for state/concurrency conflict, `400` for validation.
5. **Multi-tenancy:** if the constitution mandates it, prepend tenant and domain prefixes from the constitution.

## Named Patterns

### Workflow Transitions

Use `POST /{resource}/{id}/workflows/{workflowCode}/transitions`. Keep `transitionCode` in the body; return `201 Created` with the transition record.

### Search And Pagination

- Simple filters: GET with query parameters.
- Complex filters: `POST /search/{resource}` with structured body.
- Combine filter properties with AND; array values inside one property with OR.
- Response metadata: `page`, `pageSize`, `totalItems`, `totalPages`.

### Error Envelope

```json
{ "status": 400, "code": "VALIDATION_ERROR", "message": "...", "details": [...] }
```

### Schema Compatibility

- Add optional fields freely; never silently repurpose existing ones.
- Renamed or retyped fields are breaking → require major version bump.

## Output Contract

When invoked as a standalone skill, produce a `## API Design Decisions` section in the feature spec or plan with one row per endpoint: resource, method, status codes, versioning note, and any constitution overrides applied.

## Input

- `.specify/specs/<feature-id>/plan.md` (architecture plan with API surface)
- `.specify/memory/constitution.md` (path, naming, versioning, auth, tenancy conventions)

## Execution Flow

1. Read constitution for org-specific conventions.
2. Enumerate endpoints from the plan or user request.
3. Apply the 5-step decision framework per endpoint.
4. Emit the API Design Decisions table.
5. Flag any endpoint that deviates from constitution conventions.
