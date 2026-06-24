---
applyTo: "**/*Consumer*,**/*Producer*,**/*Handler*,**/*Event*,.specify/specs/**"
description: Detailed async messaging taxonomy, envelope, schema, and compatibility patterns
---

## Messaging Patterns Catalog

See [messaging-patterns.instructions.md](messaging-patterns.instructions.md) for the always-on core rules.

## Message Taxonomy

- **Command:** imperative instruction to perform an action.
- **Event:** notification that something happened.
- **State:** full aggregate snapshot for downstream views or synchronization.

## Topic Naming

Default topic pattern:

```text
{organization}.{domain}.{aggregate}.{messageType}
```

- Commands and events normally share multi-schema topics.
- State messages use versioned topics such as `.state.v1` and `.state.v2` for breaking schema changes.
- Partition by `aggregateId`.

## Envelope Structure

- Keep message-specific fields at the root, not nested under `payload`.
- Include `metadata.messageId` for idempotency.
- Include source metadata for traceability.
- Events and states carry aggregate version information; commands do not.

## Schema Rules

- Use JSON Schema types and formats.
- Document every field with business meaning.
- Use explicit required arrays.
- Set `additionalProperties: false` for strict validation unless the constitution says otherwise.

## Reliability And Compatibility

- Consumers must deduplicate by `messageId`.
- Every consumer needs a retry policy and a DLQ channel, typically `<topic>.dlq`.
- Safe changes include adding optional fields or adding a new message type to a multi-schema topic.
- Breaking changes include adding required fields, renaming fields, or changing field semantics.
- When breaking changes are unavoidable, publish old and new topic versions during migration.

## Schema Registry

If the project uses a schema registry, prefer JSON Schema draft-07 with backward compatibility and a subject naming strategy defined by the constitution.
