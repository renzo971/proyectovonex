---
description: API-only feature — define and implement REST endpoints without messaging
mode: agent
---

Implement an **API-only feature** (no async messaging).

## Steps

0. **Feature Directory**: Run `.specify/scripts/new-feature.sh 'feature-name'` to create the feature directory with templates.

1. **Requirements**: Invoke `@requirement-analyst` in **Detailed Mode**.
   - Focus on synchronous request/response user stories
   - Define acceptance criteria for each endpoint

2. **Design**: Invoke `@architect`.
   - Skip messaging design — focus on API layer and persistence
   - Classify as NEW or EXTEND

3. **API Contract**: Invoke `@api-champion`.
   - Define OpenAPI spec with all endpoints
   - Include pagination, filtering, error responses

4. **Test Strategy**: Invoke `@test-explorer`.
   - Focus on API contract tests, integration tests
   - Cover HTTP status codes, validation, authorization

5. **Implementation**: `@test-engineer` → `@software-engineer`.

6. **Review**: `@review` for ship-readiness.

> **Note:** Skip `@messaging-champion` — this feature has no async events.
