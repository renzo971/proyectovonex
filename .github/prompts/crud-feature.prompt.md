---
description: Standard CRUD feature — full lifecycle from requirements to implementation
mode: agent
---

Implement a **CRUD feature** using the Enterprise SDD workflow.

## Steps

0. **Feature Directory**: Run `.specify/scripts/new-feature.sh 'feature-name'` to create the feature directory with templates.

1. **Requirements**: Invoke `@requirement-analyst` in **Detailed Mode**.
   - Define user stories for Create, Read, Update, Delete operations
   - Include acceptance criteria for each operation
   - Cover validation, authorization, and error handling

2. **Design**: Invoke `@architect` to design the feature.
   - Classify as NEW, EXTEND, or HYBRID
   - Define data model, API endpoints, persistence strategy

3. **API Contract**: Invoke `@api-champion` to define the REST API.
   - Resource naming, HTTP methods, status codes
   - Request/response schemas with validation rules

4. **Test Strategy**: Invoke `@test-explorer` for test case design.
   - Happy path CRUD operations
   - Validation errors, authorization failures, not-found cases

5. **Implementation**: Follow TDD with `@test-engineer` then `@software-engineer`.

6. **Review**: Invoke `@review` for ship-readiness check.
