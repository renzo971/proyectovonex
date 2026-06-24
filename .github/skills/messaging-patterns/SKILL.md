# messaging-patterns

Purpose: decision framework for async messaging design — message taxonomy (Command / Event / State), topic naming, envelope structure, schema rules, and backward-compatible evolution.

## When to Use

- Designing new async messaging contracts or modifying existing AsyncAPI specs.
- Operator triggers via `sdd skill run messaging-patterns <feature-id>`.
- The messaging-champion agent loads this skill during Phase 2.3 contract definition.

## Decision Framework

For each message, answer in order:

1. **Classify:** is it a **Command** (imperative), **Event** (notification), or **State** (aggregate snapshot)?
2. **Topic name:** apply `{organization}.{domain}.{aggregate}.{messageType}`. Commands and events share multi-schema topics; states use versioned topics (`.state.v1`, `.state.v2`).
3. **Partition key:** use `aggregateId` to preserve per-aggregate ordering.
4. **Envelope layout:** message-specific fields at root (not nested under `payload`); include `metadata.messageId` for idempotency and source metadata for traceability; events/states carry aggregate version.
5. **Schema discipline:** JSON Schema types + formats, every field documented with business meaning, explicit `required` arrays, `additionalProperties: false` unless the constitution says otherwise.
6. **Consumer contract:** require idempotency, correlation ID, retry policy, and a DLQ channel for every production consumer.

## Named Patterns

### Topic Naming

```text
{organization}.{domain}.{aggregate}.{messageType}
```

### Envelope Structure

- Root-level message fields (no `payload` nesting).
- `metadata.messageId` for idempotency.
- Source metadata for traceability.
- Events and states carry aggregate version; commands do not.

### Schema Compatibility

- Added optional fields → backward compatible.
- Added required fields, renamed fields, changed types → **breaking** → new versioned topic.

## Output Contract

When invoked as a standalone skill, produce a `## Messaging Design Decisions` section with one row per message: name, taxonomy (C/E/S), topic, partition key, schema compatibility note, and any constitution overrides.

## Input

- `.specify/specs/<feature-id>/plan.md` (architecture plan with messaging surface)
- `.specify/memory/constitution.md` (broker, naming, schema-registry, namespace conventions)

## Execution Flow

1. Read constitution for org-specific messaging conventions.
2. Enumerate messages from the plan or user request.
3. Apply the 6-step decision framework per message.
4. Emit the Messaging Design Decisions table.
5. Flag any message that deviates from constitution conventions.
