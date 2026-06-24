# API Champion — Domain-Specific Patch

> **Source:** Extracted from `API Champion.agent.md` — Acme-specific API patterns.
> **Install:** Review and merge relevant sections into your project's API Champion agent.

## Multi-Tenancy Pattern

All endpoints start with `/tenants/{tenant}/{project-domain}/`:

```
/tenants/{tenant}/settlement/v1/instructions
/tenants/{tenant}/settlement/v1/restrictions
```

## API Versioning

- `/v1/` — Stable, production-ready
- `/v1alpha/` — Experimental, may change

## Resource Hierarchy

Parent-child through URL nesting:

```
/tenants/{tenant}/settlement/v1/instructions/{id}
/tenants/{tenant}/settlement/v1/instructions/{id}/amendments
```

## Workflow Transitions

Workflow transitions use the pattern:

```
POST /{resource}/{id}/workflows/{workflowCode}/transitions
```

With discriminator pattern on `transitionCode` — each transition adds its own required fields.
Response: `201 Created` with `WorkflowTransitionItem`.

## Tags & Organization

Use descriptive tags for related API operations (e.g., "Instruction Management", "Restriction Management").

## Acme-Specific Status Codes

- `409 Conflict` — Concurrent modifications or invalid state transitions
- `422 Unprocessable Entity` — Business validation failures

## Search & Filter Patterns

- Search Request with filters, sorting, pagination
- All filter properties optional
- Array filters with OR logic within property, AND between properties
- Pagination with `page`/`pageSize`/`totalItems`/`totalPages`

## Error Response Structure

```json
{
  "status": "error",
  "code": "ERROR_CODE",
  "message": "Message with placeholders",
  "errors": [{ "field": "fieldName", "code": "CODE", "message": "Message" }]
}
```

## Audit Fields

All resources include: `createdAt`, `updatedAt`, `createdBy`
