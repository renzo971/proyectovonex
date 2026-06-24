---
description: Event-driven feature — async messaging with no direct API endpoints
mode: agent
---

Implement an **event-driven feature** (no direct user-facing API).

## Steps

0. **Feature Directory**: Run `.specify/scripts/new-feature.sh 'feature-name'` to create the feature directory with templates.

1. **Requirements**: Invoke `@requirement-analyst` in **Detailed Mode**.
   - Focus on event triggers, processing logic, side effects
   - Define acceptance criteria for event handling

2. **Design**: Invoke `@architect`.
   - Focus on event flow, state machines, eventual consistency
   - Classify as NEW or EXTEND

3. **Messaging Contract**: Invoke `@messaging-champion`.
   - Define AsyncAPI spec with event schemas
   - Include topic naming, envelope structure, retry strategy

4. **Test Strategy**: Invoke `@test-explorer`.
   - Cover event consumption, idempotency, error handling
   - Include contract tests for event schemas

5. **Implementation**: `@test-engineer` → `@software-engineer`.

6. **Review**: `@review` for ship-readiness.

> **Note:** Skip `@api-champion` — this feature has no REST endpoints.
