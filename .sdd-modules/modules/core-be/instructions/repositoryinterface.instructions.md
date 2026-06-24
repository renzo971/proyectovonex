---
applyTo: "application/**/*Repository.java"
---

> **Note:** Java package examples below use `com.acme.securities` as a fictional placeholder. Replace with your organization's package root before generating production code.

# Repository Interface Guidelines

## Rules

- One repository interface per aggregate root
- Package: `com.acme.securities.{project-name}.application.repository.{aggregate}`
- Use domain types only (no infrastructure types)
- Minimal interface with essential operations
- Return aggregates from save method

## Naming

- Pattern: `{Aggregate}Repository`
- Examples: `InstructionRequestRepository`, `AmendmentRequestRepository`

## Structure

```java
public interface MyAggregateRepository {
    Optional<MyAggregate> findById(MyAggregateId id);
    MyAggregate save(MyAggregate aggregate);
    void delete(MyAggregate aggregate);
}
```

## Core Operations

### Find by ID

```java
Optional<MyAggregate> findById(MyAggregateId id);
```

### Save

```java
MyAggregate save(MyAggregate aggregate);
```
- Returns saved aggregate for event processing
- Handles both insert and update

### Delete

```java
void delete(MyAggregate aggregate);
```

### Custom Queries

```java
List<MyAggregate> findByForeignKey(ForeignKeyId foreignKeyId);
boolean existsById(MyAggregateId id);
long count();
```

## Implementation Example

```java
package com.acme.securities.settlement.api.application.repository.instructionamendmentrequest;

import com.acme.securities.settlement.api.domain.model.instructionamendmentrequest.AmendmentRequest;
import com.acme.securities.settlement.api.domain.model.instructionamendmentrequest.AmendmentRequestId;
import com.acme.securities.settlement.api.domain.model.instruction.InstructionId;

import java.util.List;
import java.util.Optional;

public interface InstructionAmendmentRequestRepository {
    
    Optional<AmendmentRequest> findById(AmendmentRequestId id);
    
    List<AmendmentRequest> findByInstructionId(InstructionId instructionId);
    
    AmendmentRequest save(AmendmentRequest amendmentRequest);
    
    void delete(AmendmentRequest amendmentRequest);
}
```

## Package Structure

```
application/src/main/java/com/acme/securities/{project-name}/application/repository/
└── {aggregate}/
    └── {Aggregate}Repository.java
```

## Best Practices

### Method Naming

- Use `find*` for queries returning Optional or List
- Use `exists*` for boolean checks
- Use `count*` for counting operations
- Use domain terminology

### Return Types

- `Optional<T>` for single results that may not exist
- `List<T>` for multiple results
- Return aggregate from save (not void)
- Use strongly typed IDs

### Parameters

- Use strongly typed IDs and value objects
- No primitive types for IDs
- Clear, business-meaningful names

## Anti-Patterns to Avoid

### Don't Expose Infrastructure

```java
// ❌ WRONG - infrastructure type in interface
MyAggregateEnvelope findEnvelopeById(MyAggregateId id);

// ✅ CORRECT - domain type only
Optional<MyAggregate> findById(MyAggregateId id);
```

### Don't Include Business Logic

```java
// ❌ WRONG - business logic in repository interface
void approveAndSave(MyAggregateId id);

// ✅ CORRECT - pure data access
MyAggregate save(MyAggregate aggregate);
```

### Don't Use Generic Methods

```java
// ❌ WRONG - too generic
List<MyAggregate> findByFilter(Map<String, Object> filters);

// ✅ CORRECT - specific, typed
List<MyAggregate> findByStatus(Status status);
```

### Don't Return Void from Save

```java
// ❌ WRONG - can't process events
void save(MyAggregate aggregate);

// ✅ CORRECT - return for event processing
MyAggregate save(MyAggregate aggregate);
```

## References

- [#file:domainrepository.instructions.md](domainrepository.instructions.md)
- [#file:aggregate.instructions.md](aggregate.instructions.md)

## Dependencies

```java
import java.util.Optional;
import java.util.List;
```
