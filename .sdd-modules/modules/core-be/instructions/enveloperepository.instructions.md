---
applyTo: "infrastructure/**/*EnvelopeRepository.java"
---

> **Note:** Java package examples below use `com.acme.securities` as a fictional placeholder. Replace with your organization's package root before generating production code.

# Envelope Repository Implementation Guidelines

## Rules

- Extend `PanacheRepositoryBase<TEnvelope, TId>`
- Annotate with `@RequestScoped`
- Package: `com.acme.securities.{project-name}.infrastructure.persistence.repository.{aggregate}`
- Works with envelope entities (not domain aggregates)
- Add custom query methods as `default` methods

## Naming

- Pattern: `{Aggregate}EnvelopeRepository`
- Examples: `InstructionRequestEnvelopeRepository`, `AmendmentRequestEnvelopeRepository`

## Structure

```java
@RequestScoped
public interface MyAggregateEnvelopeRepository 
    extends PanacheRepositoryBase<MyAggregateEnvelope, MyAggregateId> {
    
    // Panache provides: findById, persist, delete, etc.
    // Add custom queries below
}
```

## Panache Provides

- `findById(id)` / `findByIdOptional(id)`
- `persist(entity)`
- `delete(entity)` / `deleteById(id)`
- `listAll()`
- `find(query, params)`
- `count()`

## Custom Query Patterns

### Query by JSONB Field

```java
default List<MyEnvelope> findByStatus(String status) {
    return find("data->>'status' = ?1", status).list();
}
```

### Query by Nested JSONB Field

```java
default List<MyEnvelope> findByPartyBic(String bic) {
    return find("data -> 'partyDetails' -> 'party' ->> 'bic' = ?1", bic).list();
}
```

### Query with Multiple Conditions

```java
default List<MyEnvelope> findByStatusAndType(String status, String type) {
    return find("data->>'status' = ?1 AND data->>'type' = ?2", status, type).list();
}
```

### Query by Metadata Fields

```java
default List<MyEnvelope> findCreatedAfter(LocalDateTime date) {
    return find("createdAt > ?1", date).list();
}
```

### Count Queries

```java
default long countByStatus(String status) {
    return count("data->>'status' = ?1", status);
}
```

## Implementation Example

```java
package com.acme.securities.settlement.api.infrastructure.persistence.repository.instructionamendmentrequest;

import com.acme.securities.settlement.api.domain.model.instructionamendmentrequest.AmendmentRequestId;
import com.acme.securities.settlement.api.domain.model.instruction.InstructionId;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;

import jakarta.enterprise.context.RequestScoped;
import java.util.List;

@RequestScoped
public interface AmendmentRequestEnvelopeRepository 
    extends PanacheRepositoryBase<AmendmentRequestEnvelope, AmendmentRequestId> {
    
    default List<AmendmentRequestEnvelope> findByInstructionId(InstructionId instructionId) {
        return find("data->>'instructionId' = ?1", instructionId.getValue().toString()).list();
    }
}
```

## JSONB Query Operators

- `->` : Get JSON object field
- `->>` : Get JSON field as text
- `@>` : Contains JSON
- `?` : JSON field exists

```java
// Nested field as text
"data -> 'details' ->> 'code'"

// Contains value
"data @> '{\"status\": \"APPROVED\"}'"

// Field exists
"data ? 'optionalField'"
```

## Package Structure

```
infrastructure/src/main/java/com/acme/securities/{project-name}/infrastructure/persistence/repository/
└── {aggregate}/
    ├── {Aggregate}Envelope.java
    ├── {Aggregate}EnvelopeRepository.java
    └── {Aggregate}DomainRepository.java
```

## Anti-Patterns to Avoid

### Don't Return Domain Aggregates

```java
// ❌ WRONG - envelope repository returns envelopes
default InstructionRequest findDomainById(InstructionRequestId id) {
    return findByIdOptional(id)
        .map(InstructionRequestEnvelope::getAggregate)
        .orElse(null);
}

// ✅ CORRECT - domain repository unwraps
```

### Don't Add Business Logic

```java
// ❌ WRONG
default void approveRequest(InstructionRequestId id) {
    var envelope = findById(id);
    var aggregate = envelope.getAggregate();
    aggregate.approve();
    envelope.updateData(aggregate);
}

// ✅ CORRECT - pure data access only
```

### Don't Use String Concatenation

```java
// ❌ WRONG - SQL injection risk
find("data->>'status' = '" + status + "'")

// ✅ CORRECT - parameter binding
find("data->>'status' = ?1", status)
```

## References

- [#file:envelope.instructions.md](envelope.instructions.md)
- [#file:domainrepository.instructions.md](domainrepository.instructions.md)
- [#file:database.instructions.md](database.instructions.md)

## Dependencies

```java
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.RequestScoped;
import java.util.List;
```