---
applyTo: "**/*Controller*,**/*Route*,**/*Endpoint*,**/*api*,.specify/specs/**"
description: Detailed REST API resource, workflow, search, schema, and compatibility patterns
---

## API Patterns Catalog

See [api-patterns.instructions.md](api-patterns.instructions.md) for the always-on core rules.

## Resource Naming And Hierarchy

- Use plural resource names and kebab-case paths.
- Use descriptive identifiers when more than one identifier appears in the path.
- Nest only when the child has no independent lifecycle.
- Use a top-level resource when the child can be managed independently.
- Use `POST /search/<resource>` only for complex cross-resource queries.

If the constitution mandates multi-tenancy, use a tenant prefix and domain prefix from the constitution.

## Versioning And Status Codes

- Prefer path versioning such as `/v1/`; use header-based only if the constitution requires it.
- Increment the major version only for breaking changes.
- Use `200` for successful reads and updates, `201` for creation, `202` for async acceptance, `204` for successful delete, `409` for state conflict, and `500` for unexpected failures.

## Workflow Transitions

Use `POST /{resource}/{id}/workflows/{workflowCode}/transitions` for lifecycle transitions. Keep `transitionCode` in the request body and return `201 Created` with the transition record.

## Search, Filter, And Pagination

- Prefer GET with query parameters for simple filters.
- Use `POST /search` for rich multi-field filters, cross-resource search, or structured pagination and sorting.
- Combine filter properties with AND and array values inside one property with OR.
- Response metadata should expose page, pageSize, totalItems, and totalPages.

## Error And Schema Patterns

- Use a reusable error envelope with machine-readable code, human-readable message, and optional field-level errors.
- Name schemas consistently: request, response, and summary types should be explicit.
- Use shared component refs where possible.
- Mark required fields explicitly and use ISO-8601 dates plus UUID identifiers where applicable.

## Compatibility Checklist

Before finalizing an API change, confirm that new fields are optional, existing fields are not renamed or repurposed, field types are unchanged, and existing consumers remain compatible.
