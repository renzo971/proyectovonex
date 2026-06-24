# ddd-aggregate-design

Purpose: guide aggregate boundary decisions through invariant-first modeling, anti-pattern detection, and structured trade-off records — producing an auditable Aggregate Decision Record.

## When to Use

- Designing a new bounded context where aggregate boundaries are not yet established
- Refactoring an existing domain model where aggregate sizing, coupling, or invariant placement is unclear
- During Gate 2 (design complete) for any feature involving new or changed domain aggregates
- When the architecture review identifies aggregate boundary ambiguity in the plan document
- Operator triggers via `sdd skill run ddd-aggregate-design <feature-id>`

## Input

- The feature's domain model context (from `business-context.md` or the constitution domain section)
- Draft aggregate candidate list (from the architect or domain expert, or extracted from the spec)
- Existing event catalog (if event-driven architecture is in use)
- Consistency requirements from the spec (AC referencing transactional boundaries)

## Execution Flow

### Step 1 — Identify Aggregate Candidates

1. List all domain entities mentioned in the spec.
2. For each entity, identify its **invariants**: the rules that MUST always be true and can only be enforced by a single transactional boundary.
3. Group entities by shared invariants → these form aggregate candidate clusters.

### Step 2 — Apply Invariant-First Boundary Test

For each aggregate candidate:

| Test | Pass Condition |
|------|---------------|
| **Invariant ownership** | Every invariant is owned by exactly one aggregate root |
| **Transactional boundary** | All entities in the aggregate can be updated in a single transaction |
| **Reference by ID** | Entities outside the aggregate are referenced only by ID, never by direct object reference |
| **No cross-aggregate consistency** | Consistency between aggregates is achieved via domain events, not direct coupling |

### Step 3 — Check Anti-Patterns

Evaluate each candidate against the following anti-patterns:

| Anti-Pattern | Signal | Correct Action |
|-------------|--------|---------------|
| **God Aggregate** | Aggregate contains more than 5 entities, OR has >10 invariants | Split into smaller aggregates with domain events at the boundary |
| **Anemic Aggregate** | Aggregate root has no invariants — it is just a data container | Move invariants in or reconsider whether an aggregate is needed at all |
| **Cross-Aggregate Reference** | Aggregate A holds a direct object reference to Aggregate B | Replace with ID reference; use domain events for cross-aggregate consistency |
| **Missing Repository** | No repository abstraction for the aggregate root | Define a repository interface in the domain layer |
| **Shared Mutable State** | Two use cases modify the same aggregate root concurrently without explicit concurrency control | Add optimistic locking or event sourcing; consider splitting the aggregate |

### Step 4 — Complete the Decision Matrix

For each aggregate boundary decision, fill in the trade-off record:

| Dimension | Option A | Option B | Selected | Rationale |
|-----------|----------|----------|:--------:|-----------|
| Aggregate size (small vs. large) | | | | |
| Consistency model (strong vs. eventual) | | | | |
| Performance impact | | | | |
| Operational complexity | | | | |
| Team ownership clarity | | | | |

### Step 5 — Produce the Aggregate Decision Record

Write the completed ADR to `.specify/specs/<feature-id>/aggregate-decision-record.md` using the `aggregate-decision-record-template.md` format.

## Output Contract

```markdown
# Aggregate Design Report

## Summary
- **Feature:** [feature-id] — [feature name]
- **Aggregates Analyzed:** [N]
- **Anti-Patterns Found:** [count by type]
- **Verdict:** APPROVED | APPROVED with recommendations | NEEDS REWORK

## Aggregates

### [Aggregate Name]
- **Root:** [entity name]
- **Members:** [list]
- **Invariants:** [list]
- **Anti-Patterns Detected:** [none / list]

## Trade-off Records
[See aggregate-decision-record.md for full matrix]

## Recommendations
[Specific actions to address any anti-patterns or design concerns]
```

## Common Rationalizations

| Rationalization | Why it fails | Correct behavior |
|-----------------|:------------:|-----------------|
| "Our aggregates are fine — we'll refactor when it becomes a problem" | Aggregate boundary problems compound: a God Aggregate at design time becomes a performance bottleneck, a distributed locking nightmare, and a team ownership ambiguity source at scale. The cost of correction increases with every feature built on top. | Run the invariant-first boundary test in Step 2 now. A 30-minute design review with this skill prevents weeks of refactoring. |
| "DDD is overkill for this feature — it's just a CRUD endpoint" | If the spec references domain rules that must always hold (invariants), an aggregate boundary decision exists whether it is made explicitly or not. Implicit decisions produce accidental aggregates. | Check Step 1 — if no invariants are found, the skill confirms CRUD is appropriate. If invariants exist, they must be owned by something. |
| "The domain expert isn't available — I'll decide the boundaries myself" | Aggregate boundaries are domain knowledge, not technical knowledge. An architect deciding invariants without domain input is modelling the wrong domain. | Record the aggregate candidates as `[ASSUMPTION]` items in the ADR and block Gate 2 pending domain expert review. |
| "We don't use DDD — this module doesn't apply" | This module's `README.md` states it is for DDD contexts only. If the project does not use aggregate-based domain modeling, this module should not be activated. Do not run this skill. | Confirm via `sdd module list` that `convergence-ddd-aggregate` is appropriate for the project context before using it. |
