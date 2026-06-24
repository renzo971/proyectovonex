# Aggregate Decision Record: [AGGREGATE_NAME]

**Feature ID:** [NNN]-[feature-slug]
**Date:** [DATE]
**Author:** [Name / Agent]
**Status:** Draft | Under Review | Approved | Superseded

---

## Bounded Context

**Context Name:** [The bounded context this aggregate belongs to]
**Domain:** [Core Domain / Supporting Domain / Generic Subdomain]
**Team Ownership:** [Team responsible for this bounded context]

---

## Aggregate Root

**Root Entity:** [Name of the aggregate root entity]
**Repository Interface:** `[IAggregate_NameRepository` or `Repository<AggregateName>`]
**Identity Type:** [UUID / Long / Domain-specific ID type]

---

## Aggregate Members

> List all entities and value objects that are part of this aggregate (owned by the root, inside the transactional boundary).

| Entity / Value Object | Type | Role | Notes |
|-----------------------|------|------|-------|
| [AggregateName] | Entity (Root) | Aggregate root | |
| [ChildEntity] | Entity | Owned member | |
| [ValueObject] | Value Object | Immutable attribute | |

---

## Invariants

> Invariants are rules that MUST always hold within this aggregate boundary. If a rule requires coordination with another aggregate, it is NOT an invariant — it is an eventual consistency concern.

| # | Invariant | Enforced By | Violation Action |
|---|-----------|:-----------:|-----------------|
| INV-001 | [Rule that must always be true] | [Root method name] | [Exception thrown / event emitted] |
| INV-002 | | | |
| INV-003 | | | |

---

## Anti-Patterns Checked

| Anti-Pattern | Present? | Evidence / Notes |
|-------------|:--------:|-----------------|
| God Aggregate (>5 entities or >10 invariants) | ✅ No / ❌ Yes | |
| Anemic Aggregate (no invariants) | ✅ No / ❌ Yes | |
| Cross-Aggregate Object Reference | ✅ No / ❌ Yes | |
| Missing Repository | ✅ No / ❌ Yes | |
| Shared Mutable State Without Concurrency Control | ✅ No / ❌ Yes | |

---

## Trade-off Record

| Dimension | Option A | Option B | Selected | Rationale |
|-----------|----------|----------|:--------:|-----------|
| **Aggregate size** | Smaller (split at [boundary]) | Larger (keep [entities] together) | | |
| **Consistency model** | Strong (single transaction) | Eventual (domain events) | | |
| **Performance** | [impact description] | [impact description] | | |
| **Operational complexity** | [description] | [description] | | |
| **Team ownership** | Single team | Shared — requires coordination | | |
| **Event sourcing fit** | [Yes / No / Partial] | — | | |

---

## Domain Events Produced

> Events emitted by this aggregate when its state changes. Used to communicate with other aggregates or bounded contexts.

| Event | Trigger | Consumers |
|-------|---------|-----------|
| `[AggregateName]Created` | Root instantiated | [list of downstream consumers] |
| `[AggregateName]Updated` | State change | |
| `[AggregateName]Deleted` | Marked for deletion | |

---

## Cross-Aggregate References

> External aggregates referenced by this aggregate. MUST be by ID only — never by direct object reference.

| External Aggregate | Reference Field | Reference Type | Notes |
|-------------------|-----------------|:--------------:|-------|
| [OtherAggregateName] | `otherAggregateId` | ID only ✅ | |

---

## Open Questions

- [ ] [Question 1 requiring domain expert input]
- [ ] [Question 2]

---

## Decision

**Boundary Decision:** [Brief statement of the final aggregate boundary choice]

**Rationale:** [Why this boundary was chosen over alternatives]

**Risks / Residual Concerns:** [Any risks accepted with this design]

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | [DATE] | [Author] | Initial record |
