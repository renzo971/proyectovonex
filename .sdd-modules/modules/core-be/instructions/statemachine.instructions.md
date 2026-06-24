---
applyTo: "**/*StateMachine.java"
---

> **Note:** Java package examples below use `com.acme.securities` as a fictional placeholder. Replace with your organization's package root before generating production code.

# State Machine Implementation Guidelines

## Overview

State machines manage entity lifecycle and enforce valid state transitions within the domain layer. They encapsulate
state transition logic and provide callbacks for state change notifications.

## Project Context

- Package: `com.acme.securities.{project-name}.domain.model.{aggregate}`
- Framework: Stateless4j state machine library

## Core Principles

- Encapsulate state transition logic within dedicated state machine classes
- Enforce valid state transitions through configuration
- Provide callback mechanisms for state change notifications
- Use enum types for states and events
- Validate state transitions and throw meaningful exceptions for invalid operations
- Integrate with OperationResult pattern for error handling
- **Work with individual status fields** in domain entities, not data objects

## Requirements

### Dependencies

- Add Stateless4j dependency: `com.github.oxo42.stateless4j.StateMachine`
- Add Stateless4j configuration: `com.github.oxo42.stateless4j.StateMachineConfig`

### Class Structure

- State machine classes must be named `{Entity}StateMachine` (e.g., HoldReleaseRequestStateMachine)
- Use Stateless4j StateMachine for state management and transition validation
- Maintain list of change state callbacks for notifications
- Define private Event enum for internal state machine events
- Provide methods for each possible state transition with business-meaningful names

### Constructor Pattern

```java
public EntityStateMachine(
    final EntityStatus initialStatus,
    final Consumer<EntityStatus> callback) {

    var stateMachineConfig = new StateMachineConfig<EntityStatus, EntityStateMachine.Event>();
    stateMachineConfig
        .configure(EntityStatus.STATE_ONE)
        .permit(Event.TRANSITION_EVENT, EntityStatus.STATE_TWO);
    stateMachine = new StateMachine<>(initialStatus, stateMachineConfig);

    changeStateCallbacks.add(callback);
}
```

### State Management

- Use enum types for states (e.g., `PartyStatus`, `AccountStatus`)
- Status enums should provide helper methods for validation (e.g., `isPendingReview()`, `isApproved()`)
- Define private Event enum within state machine class for internal events

### State Validation Pattern

- Use `stateMachine.canFire(event)` to validate transitions before executing
- Throw `ValidationErrorException` with `TemplatedMessage` for invalid transitions
- Include current status and attempted action in error messages with parameter substitution

```java
if (!stateMachine.canFire(event)) {
    throw new ValidationErrorException(
        OperationResult.failure(TemplatedMessage.of(
            "Cannot {event} {entityType} request in status: {currentStatus}",
            java.util.Map.of(
                "event", event.toString().toLowerCase(),
                "entityType", "hold/release",
                "currentStatus", stateMachine.getState().toString()
            )
        ))
    );
}
```

## State Transition Methods

### Public Transition Methods

- Provide public methods for each valid state transition
- Method names should reflect business operations (e.g., `approve()`, `discard()`, `submit()`)
- Each method calls private `changeState(Event)` method which handles validation and execution

```java
/**
 * Approves the request.
 * Valid transition from PENDING to APPROVED.
 */
public void approve() {
    changeState(Event.APPROVE);
}

/**
 * Discards the request.
 * Valid transition from PENDING to DISCARDED.
 */
public void discard() {
    changeState(Event.DISCARD);
}

/**
 * Submits the request.
 * Valid transition from APPROVED to SUBMITTED.
 */
public void submit() {
    changeState(Event.SUBMIT);
}
```

### State Change Implementation

```java
private void changeState(final Event event) {
    if (!stateMachine.canFire(event)) {
        throw new ValidationErrorException(
            OperationResult.failure(TemplatedMessage.of(
                "Cannot {event} {entityType} request in status: {currentStatus}",
                java.util.Map.of(
                    "event", event.toString().toLowerCase(),
                    "entityType", "hold/release",
                    "currentStatus", stateMachine.getState().toString())))
        );
    }

    stateMachine.fire(event);
    for (var callback : changeStateCallbacks) {
        callback.accept(stateMachine.getState());
    }
}

/**
 * Gets the current state of the state machine.
 */
public EntityStatus getState() {
    return stateMachine.getState();
}
```

## Error Handling

### Invalid State Transitions

- Throw `ValidationErrorException` with `OperationResult.failure()` for invalid transitions
- Include current state and attempted event in error message
- Use business-meaningful error messages

### Exception Pattern

```java
throw new ValidationErrorException(
    OperationResult.failure(TemplatedMessage.of(
        "Cannot {event} {entityType} request in status: {currentStatus}",
        java.util.Map.of(
            "event", event.toString().toLowerCase(),
            "entityType", "hold/release",
            "currentStatus", stateMachine.getState().toString()
        )
    ))
);
```

## Required Dependencies

### Import Statements

```java
import com.acme.securities.settlement.api.domain.OperationResult;
import com.acme.securities.settlement.api.domain.TemplatedMessage;
import com.acme.securities.settlement.api.domain.exception.ValidationErrorException;
import com.github.oxo42.stateless4j.StateMachine;
import com.github.oxo42.stateless4j.StateMachineConfig;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;
```

### JPA Entity Dependencies

```java
import jakarta.persistence.Entity;
import jakarta.persistence.Enumerated;
import jakarta.persistence.EnumType;
import jakarta.persistence.PostLoad;
import jakarta.persistence.Transient;
```

## Complete Implementation Template

```java
public class EntityStateMachine {

    private final List<Consumer<EntityStatus>> changeStateCallbacks = new ArrayList<>();
    private final StateMachine<EntityStatus, EntityStateMachine.Event> stateMachine;

    public EntityStateMachine(
        final EntityStatus initialStatus,
        final Consumer<EntityStatus> callback) {

        var stateMachineConfig = new StateMachineConfig<EntityStatus, EntityStateMachine.Event>();
        stateMachineConfig
            .configure(EntityStatus.PENDING)
            .permit(Event.APPROVE, EntityStatus.APPROVED)
            .permit(Event.DISCARD, EntityStatus.DISCARDED);
        stateMachineConfig
            .configure(EntityStatus.APPROVED)
            .permit(Event.SUBMIT, EntityStatus.SUBMITTED);
        stateMachine = new StateMachine<>(initialStatus, stateMachineConfig);

        changeStateCallbacks.add(callback);
    }

    /**
     * First transition example.
     * Valid transition from PENDING to APPROVED.
     */
    public void approve() {
        changeState(Event.APPROVE);
    }

    /**
     * Second transition example.
     * Valid transition from PENDING to DISCARDED.
     */
    public void discard() {
        changeState(Event.DISCARD);
    }

    /**
     * Gets the current state of the state machine.
     */
    public EntityStatus getState() {
        return stateMachine.getState();
    }

    private void changeState(final Event event) {
        if (!stateMachine.canFire(event)) {
            throw new ValidationErrorException(
                OperationResult.failure(TemplatedMessage.of(
                    "Cannot {event} {entityType} request in status: {currentStatus}",
                    java.util.Map.of(
                        "event", event.toString().toLowerCase(),
                        "entityType", "hold/release",
                        "currentStatus", stateMachine.getState().toString()
                    )
                ))
            );
        }

        stateMachine.fire(event);
        for (var callback : changeStateCallbacks) {
            callback.accept(stateMachine.getState());
        }
    }

    private enum Event {
        APPROVE,
        DISCARD,
        SUBMIT
    }
}
```

## Integration with Domain Entities

### Entity State Management

- Entity must have a separate status field annotated with `@Enumerated(EnumType.STRING)` (Direct JPA) or as individual field (Envelope)
- State machine field must be marked as `@Transient` to prevent JPA persistence
- State machine callback updates the entity's status field directly
- Initialize state machine in constructor and via initialization method after load

### JPA/Persistence Lifecycle Integration

#### Envelope Pattern (with @PostLoad)

```java
public class DomainEntity {
    
    protected EntityStatus status; // Individual field, no JPA annotations in domain
    
    @Transient
    private EntityStateMachine stateMachine; // Transient to prevent persistence
    
    // Constructor with business logic for initial status
    public DomainEntity(DomainEntityInfo info) {
        var initialStatus = EntityStatus.PENDING;
        
        // Apply business rules to determine initial status
        if (businessConditionMet(info)) {
            initialStatus = EntityStatus.APPROVED;
        }
        
        this.stateMachine = new EntityStateMachine(
            initialStatus,
            newStatus -> this.status = newStatus);
        
        // Set other fields from info
        this.status = initialStatus;
    }
    
    // @PostLoad is REQUIRED to initialize state machine after JPA load
    @PostLoad
    private void initializeStateMachine() {
        if (status != null) {
            this.stateMachine = new EntityStateMachine(
                this.status,
                newStatus -> this.status = newStatus);
        }
    }
    
    // Public methods delegate to state machine directly (no lazy getter needed)
    public void approve() {
        stateMachine.approve();
    }
    
    public void discard() {
        stateMachine.discard();
    }
    
    public void submit() {
        stateMachine.submit();
    }
}
```

#### Direct JPA Pattern (with lazy getter)

```java
public class DomainEntity {
    
    protected EntityStatus status; // Individual field
    
    @Transient
    private EntityStateMachine stateMachine; // Transient to prevent persistence
    
    // Constructor with business logic for initial status
    public DomainEntity(DomainEntityInfo info) {
        var initialStatus = EntityStatus.PENDING;
        
        // Apply business rules to determine initial status
        if (businessConditionMet(info)) {
            initialStatus = EntityStatus.APPROVED;
        }
        
        this.stateMachine = new EntityStateMachine(
            initialStatus,
            newStatus -> this.status = newStatus);
        
        // Set other fields from info
        this.status = initialStatus;
    }
    
    // Initialize state machine after deserialization/loading
    private void initializeStateMachine() {
        if (status != null) {
            this.stateMachine = new EntityStateMachine(
                this.status,
                newStatus -> this.status = newStatus);
        }
    }
    
    // Public methods delegate to state machine via lazy getter
    public void approve() {
        getStateMachine().approve();
    }
    
    public void discard() {
        getStateMachine().discard();
    }
    
    public void submit() {
        getStateMachine().submit();
    }
    
    private EntityStateMachine getStateMachine() {
        if (stateMachine == null) {
            initializeStateMachine();
        }
        return stateMachine;
    }
}
```

### Constructor Business Logic Pattern

- Determine initial status based on business rules in constructor
- Common approach: check dates, conditions, or info object data
- Example: If opening date is before/equal to current date, start as APPROVED instead of PENDING

```java
public DomainEntity(DomainEntityInfo info) {
    var initialStatus = EntityStatus.PENDING;
    
    if (DateTimeUtils.isBeforeOrEqual(info.getOpeningDate(), new Date())) {
        initialStatus = EntityStatus.APPROVED;
    }
    
    this.stateMachine = new EntityStateMachine(
        initialStatus,
        newStatus -> this.status = newStatus);
    
    // ... other initialization from info object
    this.status = initialStatus;
}
```

## Best Practices

### State Machine Design

- Keep state machines focused on a single entity's lifecycle
- Define clear, business-meaningful state names
- Use enum helper methods for state validation (e.g., `isPendingReview()`, `isApproved()`)
- Validate transitions explicitly in each transition method before calling `changeState()`

### Entity Integration Best Practices

- Always mark state machine field as `@Transient` in domain entities (avoid persistence)
- **Envelope Pattern**: Use `@PostLoad` to initialize state machine after JPA entity loading
- **Direct JPA Pattern**: Use lazy getter pattern - initialize state machine on first access
- Use lambda expression callbacks for direct field updates: `newStatus -> this.status = newStatus`
- Apply business logic in constructor to determine appropriate initial status
- Delegate state transition methods from entity to state machine
- **Individual status fields** instead of data objects for clear architecture
- State machine is reconstructed from persisted status field after entity load

### JPA Persistence Considerations

- State machine instances are not persisted - only the status field matters
- **Envelope Pattern**: No JPA annotations on status field in domain entities - envelope handles persistence
- **Direct JPA Pattern**: Status field uses `@Enumerated(EnumType.STRING)` annotation
- Status field is persisted via infrastructure envelope entities (Envelope) or directly (Direct JPA)
- State machine is recreated on entity access using current status from individual field
- Callback pattern ensures entity status field stays synchronized with state machine

### Callback Management

- Use list of callbacks to update entity state after successful transitions
- Keep callbacks lightweight and focused on state updates
- Prefer direct field assignment in callbacks for simple status updates: `newStatus -> this.status = newStatus`
- Consider registering domain events in callbacks for complex workflows
- Iterate through all callbacks in `changeState()` method to notify all registered listeners

### Error Handling

- Always validate state transitions explicitly in each transition method
- Provide clear error messages for invalid transitions
- Use OperationResult pattern for consistent error handling
- Include current state and attempted transition in error messages

### Business Logic Integration

- Determine initial status in constructor based on business rules
- Common patterns include date comparisons, info object validation, or external conditions
- Example: Entities may start as APPROVED if opening date has passed, otherwise PENDING
- Validate business preconditions before calling state machine transition methods
- **Work with individual status fields** in domain entities, not data objects
