---
applyTo: "infrastructure/**/*Envelope.java"
---

> **Note:** Java package examples below use `com.acme.securities` as a fictional placeholder. Replace with your organization's package root before generating production code.

# Envelope Implementation Guidelines

## Rules

- Extend `AggregateEnvelopeBase<TAggregate, TAggregateId>`
- Annotate with `@Entity` and `@Table`
- Package: `com.acme.securities.{project-name}.infrastructure.persistence.repository.{aggregate}`
- Protected no-args constructor for JPA
- Public constructor accepting ID and aggregate
- NO business logic - pure infrastructure wrapper

## Naming

- Pattern: `{Aggregate}Envelope`
- Examples: `InstructionRequestEnvelope`, `AmendmentRequestEnvelope`

## Structure

```java
@Entity
@Table(name = "table_name")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class MyAggregateEnvelope
    extends AggregateEnvelopeBase<MyAggregate, MyAggregateId> {

    public MyAggregateEnvelope(final MyAggregateId id, final MyAggregate data) {
        super(id, data);
    }
}
```

## Base Class Provides

```java
@EmbeddedId
protected TAggregateId id;                    // Strongly typed aggregate ID

@Column(name = "data", columnDefinition = "jsonb")
@JdbcTypeCode(SqlTypes.JSON)
protected TAggregate data;                    // Complete aggregate as JSONB

@Version
@Column(name = "version", nullable = false)
protected Long version;                       // Optimistic locking

@Column(name = "created_at", nullable = false, updatable = false)
protected LocalDateTime createdAt;

@Column(name = "updated_at")
protected LocalDateTime updatedAt;
```

## Base Class Methods

**Constructor:**
```java
new MyEnvelope(id, aggregate);
// Sets id, data, createdAt
// Leaves version null (Hibernate sets on persist)
```

**Update:**
```java
envelope.updateData(modifiedAggregate);
// Updates data, sets updatedAt
// Hibernate auto-increments version
```

**Get Aggregate:**
```java
var aggregate = envelope.getAggregate();
```

## Implementation Example

```java
package com.acme.securities.settlement.api.infrastructure.persistence.repository.instructioncreationrequest;

import com.acme.securities.settlement.api.domain.model.instructioncreationrequest.InstructionRequest;
import com.acme.securities.settlement.api.domain.model.instructioncreationrequest.InstructionRequestId;
import com.acme.securities.settlement.api.infrastructure.persistence.repository.AggregateEnvelopeBase;

import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "instruction_request")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class InstructionRequestEnvelope
    extends AggregateEnvelopeBase<InstructionRequest, InstructionRequestId> {

    public InstructionRequestEnvelope(final InstructionRequestId id, final InstructionRequest data) {
        super(id, data);
    }
}
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

### ⚠️ NEVER Manually Set Version

```java
// ❌ WRONG - breaks optimistic locking
protected AggregateEnvelopeBase(TAggregateId id, TAggregate data) {
    super(id, data);
    this.version = 1L;  // DON'T DO THIS
}

// ❌ WRONG - breaks optimistic locking
public void updateData(TAggregate data) {
    this.data = data;
    this.version++;  // DON'T DO THIS
}

// ✅ CORRECT - let Hibernate manage version
protected AggregateEnvelopeBase(TAggregateId id, TAggregate data) {
    super(id, data);
    // version stays null, Hibernate sets it
}
```

### Don't Add Business Logic

```java
// ❌ WRONG
public void approve() {
    var aggregate = this.getAggregate();
    aggregate.approve();
    this.updateData(aggregate);
}

// ✅ CORRECT - envelopes are pure wrappers
```

### Don't Override Base Methods

```java
// ❌ WRONG
@Override
public void updateData(MyAggregate data) {
    super.updateData(data);
    // Custom logic
}

// ✅ CORRECT - use base implementation as-is
```

### Don't Add Additional Fields

```java
// ❌ WRONG
@Column(name = "status")
private String status;  // Duplicates JSONB data

// ✅ CORRECT - all domain data in JSONB only
```

## References

- [#file:aggregate.instructions.md](aggregate.instructions.md)
- [#file:database.instructions.md](database.instructions.md)
- [#file:domainrepository.instructions.md](domainrepository.instructions.md)
- [#file:enveloperepository.instructions.md](enveloperepository.instructions.md)

## Dependencies

```java
import com.acme.securities.settlement.api.infrastructure.persistence.repository.AggregateEnvelopeBase;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.NoArgsConstructor;
```
