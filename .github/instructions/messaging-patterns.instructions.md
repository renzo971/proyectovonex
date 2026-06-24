---
applyTo: "**/*Consumer*,**/*Producer*,**/*Handler*,**/*Event*,.specify/specs/**"
description: Reusable async messaging design rules parameterized by the constitution
---

## Messaging Design Rules

Before applying these rules, check the constitution for broker, naming, schema-registry, and namespace conventions.

## Core Rules

- Classify every message as a **Command**, **Event**, or **State** before designing it.
- Use a topic pattern derived from organization, domain, aggregate, and message type.
- Keep command and event topics multi-schema; keep state topics versioned for breaking schema changes.
- Partition by `aggregateId` to preserve per-aggregate ordering.
- Require idempotency, correlation, retry policy, and a DLQ channel for production consumers.
- Treat added required fields, renamed fields, and changed field types as breaking changes.

For the full decision framework, named patterns, and worked examples use the `messaging-patterns` skill (`sdd skill run messaging-patterns`). See also [messaging-patterns-catalog.instructions.md](messaging-patterns-catalog.instructions.md) for the quick-reference catalog.
