# Architect — Domain-Specific Patch

> **Source:** Extracted from `Architect.agent.md` — domain-specific building block references.
> **Install:** Review and merge relevant sections into your project's Architect agent.

## Domain-Specific Building Blocks

The following building blocks contain domain-specific implementation references that should be added to the Architect agent when this module is installed:

### Infrastructure Layer Additions

- **Envelope**: Persistence wrapper for aggregates (JSONB storage pattern)
  - *Use when:* You want to persist rich domain models without ORM complexity, or schema needs to evolve frequently
  - *Trade-off:* Flexibility and simplicity vs. query performance on nested fields

- **Repository Implementation**: Concrete persistence using envelope pattern, Panache and Hibernate.
  - *Use when:* Implementing persistence for aggregates defined in domain layer
  - *Responsibilities:* Custom queries beyond basic Panache methods, serialize/deserialize aggregates, manage transactions, handle optimistic locking

- **Kafka Consumer**: External message ingestion and processing
  - *Use when:* System consumes events from external systems or other bounded contexts
  - *Pattern:* Receive message → Validate → Map to domain command/event → Invoke use case

### Architectural Patterns

- **Envelope Pattern**: JSONB persistence for rich domain models
- **CQRS**: Separate write (use cases) and read (query handlers) models
- **Event-Driven**: Domain events for decoupling and eventual consistency

### Pattern Selection — Domain Additions

**Need to persist data?**
- Complex business rules, invariants → Aggregate + Use Case + Envelope Repository

**Need to communicate changes?**
- Across services/contexts → Domain Event → Kafka Producer → External system

**Need to integrate external system?**
- Consuming events → Kafka Consumer
