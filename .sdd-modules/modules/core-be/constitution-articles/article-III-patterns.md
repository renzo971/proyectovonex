# Article III — Architectural Patterns

> **Module:** core-be
> **Purpose:** Merge this into your project's constitution Article III.

## Architecture Style

- **Clean Architecture**: Strict dependency rule (domain → application → infrastructure)
- **Domain-Driven Design (DDD)**: Aggregates, entities, value objects, domain events, bounded contexts
- **CQRS**: Separate write path (use cases) and read path (query handlers)
- **Event-Driven**: Domain events for intra-service decoupling, Kafka for inter-service communication

## Domain Layer (Pure Business Logic)

| Building Block | Purpose |
|---------------|---------|
| **Aggregate** | Consistency boundary, encapsulates business rules, emits domain events |
| **Entity** | Business object with identity and lifecycle |
| **Value Object** | Immutable concept defined by attributes (Money, DateRange, Email) |
| **Info Object** | Passive data snapshot for aggregate creation/transfer |
| **State Machine** | Manages lifecycle transitions with strict state rules |
| **Domain Event** | Immutable record of business occurrence |

## Application Layer (Workflow Orchestration)

| Building Block | Purpose |
|---------------|---------|
| **Use Case** | Single business operation (Input → Validate → Load → Execute → Save → Return) |
| **Repository Interface** | Persistence contract (save, findById, delete) |
| **Gateway Interface** | External system abstraction |
| **Event Handler** | Processes domain events synchronously (same transaction) |

## Infrastructure Layer (Technical Implementation)

| Building Block | Purpose |
|---------------|---------|
| **Envelope** | JSONB persistence wrapper for aggregates |
| **Repository Implementation** | Panache/Hibernate persistence with envelope pattern |
| **Controller** | Thin API layer (generated OpenAPI interface → use case delegation) |
| **Query Handler** | Optimized read operations (CQRS read side) |
| **Kafka Consumer** | External message ingestion and processing |
| **Mapper** | Data transformation across layers (State, Command, Domain, Operation, Workflow) |

## Persistence Approaches

| Approach | When to Use |
|----------|-------------|
| **Envelope Pattern** | Rich domain models, frequent schema evolution, persistence-agnostic domain |
| **Direct JPA** | Simpler implementations where persistence decoupling is not required |

## Message Patterns

| Type | Naming | Topic Pattern |
|------|--------|---------------|
| Commands | Verb form (Create, Update) | `acme.sec.{tenant}.{domain}.{aggregate}.commands` |
| Events | Past tense (Created, Updated) | `acme.sec.{tenant}.{domain}.{aggregate}.events` |
| States | "State" suffix | `acme.sec.{tenant}.{domain}.{aggregate}.state.v{version}` |
