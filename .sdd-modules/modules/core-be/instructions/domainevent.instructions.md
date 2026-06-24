---
applyTo: "domain/**/*Event.java"
---

> **Note:** Java package examples below use `com.acme.securities` as a fictional placeholder. Replace with your organization's package root before generating production code.

# Domain Event Implementation Guidelines

## Rules

- Implement as Java `record` for immutability
- Implement `DomainEvent` interface
- Package: `com.acme.securities.{project-name}.domain.model.{aggregate}/event`
- Register in aggregates via `registerEvent()`
- Carry aggregate ID and Info object as immutable snapshot

## Structure

- Java `record` implementing `DomainEvent` interface
- Located in `{aggregate}/event/` package
- Include JavaDoc describing business meaning

## Naming

- Pattern: `{Aggregate}{BusinessAction}Event`
- Use past tense: `Created`, `Approved`, `Submitted`, `Discarded`
- Examples: `InstructionRequestCreatedEvent`, `AmendmentRequestApprovedEvent`

## Content

**Standard Pattern:**
- Aggregate ID (strongly typed)
- Info object (immutable snapshot)

**Extended Pattern:**
- Aggregate ID (strongly typed)
- Info object (immutable snapshot)
- Additional context fields (timestamps, user IDs) when needed

## Required Methods

- Static factory method `of()` for creating instances
- Implement `aggregateId()` returning UUID from strongly typed ID:
```java
@Override
public UUID aggregateId() {
    return aggregateId.getValue();
}
```

## Implementation Example

### Standard Event Pattern

```java
package com.acme.securities.settlement.api.domain.model.restrictioncreationrequest.event;

import com.acme.securities.settlement.api.domain.model.restrictioncreationrequest.RestrictionRequestId;
import com.acme.securities.settlement.api.domain.model.restrictioncreationrequest.RestrictionRequestInfo;
import com.acme.securities.settlement.api.domain.model.DomainEvent;

import java.util.UUID;

/**
 * Domain event fired when a RestrictionRequest is created.
 * This event triggers read model updates and integration event publication.
 */
public record RestrictionRequestCreatedEvent(
    RestrictionRequestId restrictionRequestId,
    RestrictionRequestInfo restrictionRequestInfo
) implements DomainEvent {

    public static RestrictionRequestCreatedEvent of(
        final RestrictionRequestId restrictionRequestId,
        final RestrictionRequestInfo restrictionRequestInfo
    ) {
        return new RestrictionRequestCreatedEvent(restrictionRequestId, restrictionRequestInfo);
    }

    @Override
    public UUID aggregateId() {
        return restrictionRequestId.getValue();
    }
}
```

### Extended Event Pattern (with additional context)

```java
package com.acme.securities.settlement.api.domain.model.instructionamendmentrequest.event;

import com.acme.securities.settlement.api.domain.model.instructionamendmentrequest.AmendmentRequestId;
import com.acme.securities.settlement.api.domain.model.instructionamendmentrequest.AmendmentRequestInfo;
import com.acme.securities.settlement.api.domain.model.DomainEvent;
import com.acme.securities.settlement.api.domain.valueobject.UserId;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Domain event fired when an AmendmentRequest is approved.
 * Includes approval timestamp and approver information for audit trail.
 */
public record AmendmentRequestApprovedEvent(
    AmendmentRequestId amendmentRequestId,
    AmendmentRequestInfo amendmentRequestInfo,
    UserId approvedBy,
    OffsetDateTime approvedAt
) implements DomainEvent {

    public static AmendmentRequestApprovedEvent of(
        final AmendmentRequestId amendmentRequestId,
        final AmendmentRequestInfo amendmentRequestInfo,
        final UserId approvedBy,
        final OffsetDateTime approvedAt
    ) {
        return new AmendmentRequestApprovedEvent(
            amendmentRequestId,
            amendmentRequestInfo,
            approvedBy,
            approvedAt
        );
    }

    @Override
    public UUID aggregateId() {
        return amendmentRequestId.getValue();
    }
}
```

## Package Structure

```
domain/src/main/java/com/acme/securities/{project-name}/domain/model/
└── {aggregate}/
    └── event/
        ├── {Aggregate}CreatedEvent.java
        ├── {Aggregate}ApprovedEvent.java
        └── {Aggregate}DiscardedEvent.java
```

## Anti-Patterns to Avoid

### Don't Modify Events After Creation

```java
// Wrong - events are immutable
var event = MyEvent.of(id, info);
event.setTimestamp(newTime); // Compilation error with records

// Correct - create new event if needed
var event = MyEvent.of(id, info, OffsetDateTime.now());
```

### Don't Fire Events Directly

```java
// Wrong - bypasses aggregate event management
cdiEvent.fire(new MyEvent(id, info));

// Correct - register event in aggregate
this.registerEvent(agg -> MyEvent.of(this.id, this.buildInfo()));
```

### Don't Include Mutable References

```java
// Wrong - aggregate reference can change
public record MyEvent(
    MyAggregateId id,
    MyAggregate aggregate  // Mutable reference!
) implements DomainEvent { }

// Correct - use immutable Info object
public record MyEvent(
    MyAggregateId id,
    MyAggregateInfo info  // Immutable snapshot
) implements DomainEvent { }
```

### Don't Create Events for Technical Operations

```java
// Wrong - technical concern
public record MyAggregatePersistedEvent(...) { }

// Correct - business concern
public record MyAggregateCreatedEvent(...) { }
```

### Don't Use Events for Queries

```java
// Wrong - events are for notifications, not queries
public record GetMyAggregateEvent(...) { }

// Correct - use query handlers for reads
// Events should represent state changes only
```

## References

- [#file:aggregate.instructions.md](aggregate.instructions.md)
- [#file:eventhandler.instructions.md](eventhandler.instructions.md)
- [#file:info.instructions.md](info.instructions.md)

## Dependencies

```java
import com.acme.securities.settlement.api.domain.model.DomainEvent;
import java.util.UUID;
```
- Event content should be immutable (records preferred)
