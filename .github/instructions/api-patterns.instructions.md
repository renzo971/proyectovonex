---
applyTo: "**/*Controller*,**/*Route*,**/*Endpoint*,**/*api*,.specify/specs/**"
description: Reusable REST API design rules parameterized by the constitution
---

## API Design Rules

Before applying any rule below, check the constitution for path, naming, versioning, auth, and tenancy conventions.

## Core Rules

- Use plural resource names and descriptive identifiers when plain `{id}` is ambiguous.
- Prefer path-based versioning unless the constitution explicitly chooses another strategy.
- Use standard HTTP semantics: GET read, POST create or trigger, PUT replace, PATCH partial update, DELETE remove.
- Use `201` for creation with `Location`, `202` for deferred completion, `409` for state or concurrency conflict, and `400` for validation failures.
- Prefer GET with query parameters for simple filtering; reserve `POST /search` for complex cross-resource filters.
- Keep schema changes backward compatible: add optional fields, never silently repurpose existing ones.

For the full decision framework, named patterns, and worked examples use the `api-patterns` skill (`sdd skill run api-patterns`). See also [api-patterns-catalog.instructions.md](api-patterns-catalog.instructions.md) for the quick-reference catalog.
