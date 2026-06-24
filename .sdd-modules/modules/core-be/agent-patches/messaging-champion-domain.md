# Messaging Champion — Domain-Specific Patch

> **Source:** Extracted from `Messaging Champion.agent.md` — Acme-specific Kafka patterns.
> **Install:** Review and merge relevant sections into your project's Messaging Champion agent.

## Topic Naming Convention

- **Commands**: `acme.sec.{tenant}.{domain-name}.{aggregate-name}.commands`
- **Events**: `acme.sec.{tenant}.{domain-name}.{aggregate-name}.events`
- **States**: `acme.sec.{tenant}.{domain-name}.{aggregate-name}.state.v{version}`

Key rules:
- Commands and Events: multiple schemas per topic
- States: single schema per topic (dedicated topic per version)

## Message Types

### Commands (Imperative Instructions)
- Naming: Verb form (Create, Update, Cancel, Process)
- Example entities: `CreateInstruction`, `CancelRestriction`, `ProcessAllegement`

### Events (State Change Notifications)
- Naming: Past tense (Created, Updated, Cancelled)
- Aggregate version in metadata

### States (Current State Snapshots)
- Naming: "State" suffix
- Dedicated topic per version

## Standard Message Envelope

Root-level fields: `aggregateId` + message-specific fields

Metadata object:
- `messageId` — Unique message identifier
- `sourceReference` — External reference
- `sourceApplication` — Producing application name
- `sourceDomain` — Business domain
- `version` — Aggregate version (events/states only)

## JSON Schema Template

Use Draft-07 with `javaType` for generated Java classes:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "javaType": "com.acme.securities.{tenant}.{domain}.infrastructure.messaging.schemas.{SchemaName}",
  "type": "object",
  "properties": { ... },
  "required": [ ... ],
  "additionalProperties": false
}
```

## Schema Registry Configuration

- Subject naming strategy: topic-based
- Backward compatibility mode for new → old data reading

## Schema Design Rules

- camelCase field names
- `javaType` for generated class package control
- Appropriate types with format specifiers
- Required vs optional field semantics
- Clear descriptions for every field
- Validation constraints (minLength, maxLength, pattern, enum)
