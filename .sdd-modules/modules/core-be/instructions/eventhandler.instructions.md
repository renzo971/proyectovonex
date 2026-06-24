---
applyTo: "application/**/*Handler.java"
---

> **Note:** Java package examples below use `com.acme.securities` as a fictional placeholder. Replace with your organization's package root before generating production code.

# Event Handler Implementation Guidelines

## Overview

Event handlers process domain events to update read models, trigger integration events, and handle side effects. They
implement the event-driven architecture of the project.

## Project Context

- Package: `com.acme.securities.{project-name}.application.eventhandler.{eventtype}`
- Framework: Quarkus with CDI Event Processing

## Requirements

### Core Principles

- Single responsibility: Each handler processes one event type with one specific goal
- Idempotent processing: Safe to process multiple times
- Order independence: No assumptions about event order
- Failure isolation: Contain failures gracefully
- Observable behavior: Monitor and track processing
- **Synchronous execution**: Domain events processed synchronously in the **same database transaction**
- Event-driven architecture: Integration events triggered by domain events, never directly from use cases
- Transactional consistency: Domain Event Listeners participate in the same transaction context

### Listener Design

- Single Responsibility: Each listener class handles one specific type of domain event and should have a single goal
- Multiple Listeners Allowed: More than one listener is allowed for a single event type
- Meaningful Naming: The listener class and package name must have a meaningful name that describes its purpose

### Package Organization

- Listeners should be grouped by the event that they listen to
- Listeners for the same event should be in the same package
- Package name should have the event name at the end

### Event-Driven Architecture

- Integration events triggered by domain events, never directly from use cases
- Always use domain events to trigger integration events or read model updates
- Implement listeners to handle side effects outside the core domain logic

### Transactional Consistency

- Domain Event Listeners execute **synchronously** using `@Observes`
- Handlers execute within the **same transaction context** as the originating use case
- Use `@Transactional` annotation for read model updaters and other transactional operations
- Ensure atomicity of the whole operation (use case + all event handlers)
- Repository decorator dispatches events after persistence within same transaction
- Common use cases: updating read models, publishing integration events, triggering workflows

## Package Organization

### Event Handler Structure

```
application/src/main/java/com/acme/securities/{project-name}/application/eventhandler/
├── {eventtype}/
│   └── {Event}Handler.java           # Event-specific handler
├── {eventtype}/  
│   └── {Event}Handler.java           # Another event handler
```

### Naming Conventions

- Single Responsibility: Each listener class handles one specific type of domain event
- Multiple Listeners Allowed: More than one listener is allowed for a single event type
- Meaningful Naming: The listener class and package name must describe its purpose
- Package name should have the event name at the end

## Implementation Requirements

### Base Event Handler Pattern

- Must use `@ApplicationScoped` annotation for CDI bean management
- Must use `@RequiredArgsConstructor` for dependency injection
- Must handle specific event type using `@Observes` annotation for synchronous processing within the same transaction
- Must include proper validation with meaningful exceptions
- Must provide appropriate logging for observability

### Event Handler Implementation

```java
@Slf4j
@ApplicationScoped
@RequiredArgsConstructor
public class {Event}Handler {
    
    private final ExampleProjectionRepository projectionRepository;

    @Transactional
    void on{Event}(@Observes {Event} event) {
        if (event == null) {
            throw new IllegalArgumentException("Event cannot be null");
        }
        
        log.info("Handling {Event} for aggregate {}, field: {}", 
            event.getAggregateId(), event.getSomeField());
        
        // Process the event - update read model, publish integration event, etc.
        repository.updateProjection(event.getAggregateId(), event.getSomeField());
    }
}
```

### Integration Event Publisher Pattern

```java
@Slf4j
@ApplicationScoped
@RequiredArgsConstructor
public class IntegrationEventPublisher {
    private final MessagePublisher publisher;

    @SneakyThrows
    void on(@Observes {Event} event) {
        log.info("Publishing integration event for {}", event.getAggregateId());
        
        this.publisher.publish(
            TopicsEnum.EVENTS_TOPIC.getTopicName(),
            event.getAggregateId(),
            mapToIntegrationEvent(event),
            Collections.emptyMap()
        );
    }
    
    private IntegrationEvent mapToIntegrationEvent({Event} event) {
        return IntegrationEvent.builder()
            .withId(event.getAggregateId())
            .withField1(event.getField1())
            .withField2(event.getField2())
            .build();
    }
}
```

### Read Model Updater Pattern

```java
@Slf4j
@ApplicationScoped
@RequiredArgsConstructor
public class ExampleReadModelUpdater {
    private final ExampleProjectionRepository projectionRepository;

    @Transactional
    void on(@Observes {Event} event) {
        log.info("Updating read model for {}", event.getAggregateId());
        
        var projection = ExampleProjection.builder()
            .id(event.getAggregateId())
            .field1(event.getField1())
            .field2(event.getField2())
            .status("ACTIVE")
            .createdAt(Instant.now())
            .build();
            
        this.projectionRepository.persist(projection);
    }
}
```

## Transaction Management

- Use `@Transactional` for operations requiring atomicity
- Domain event listeners are processed synchronously using `@Observes` within the same transaction
- Ensure read model updates are transactionally consistent
- Log processing for observability and debugging

## Integration Rules

- Integration events must be triggered by domain events only
- Never trigger integration events directly from use cases
- Use domain events for all side effects outside core domain logic
- Maintain clear separation between domain events and integration events
- Organize event handlers by event type rather than aggregate


