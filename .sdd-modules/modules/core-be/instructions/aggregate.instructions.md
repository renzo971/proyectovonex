---
applyTo: "domain/**/*.java"
---

> **Note:** Java package examples below use `com.acme.securities` as a fictional placeholder. Replace with your organization's package root before generating production code.

# Aggregate Implementation Guidelines

## Overview

Aggregates are the consistency boundaries in the domain model. They ensure data integrity and encapsulate business
rules.

## Project Context

- Package: `com.acme.securities.{project-name}.domain.model.mySampleEntity`
- Framework: Quarkus with JPA/Hibernate

## Structure

Each aggregate has its own package containing:

- `MySampleEntity.java` - Aggregate root entity
- `MySampleEntityChild.java` - Supporting entities
- `MySampleEntityId.java` - Strongly typed identifier value object
- `event/` - Domain events (e.g., `MySampleEntityCreatedEvent`)

## Architectural Approaches

This project supports two persistence approaches. Check the existing codebase patterns before implementing.

### Approach Comparison

| Aspect | Envelope Pattern | Direct JPA |
|--------|------------------|------------|
| Domain purity | Domain is persistence-agnostic | JPA coupled to domain |
| Complexity | Higher (envelope wrappers) | Lower (direct mapping) |
| Flexibility | Easy to change persistence | Harder to decouple |
| Serialization | Jackson-based (JSONB) | JPA column mapping |
| Base class | `implements AggregateRoot<T>` | `extends AggregateRoot<T>` |

---

## Envelope Pattern (Persistence-Agnostic Domain)

Use this approach when the domain layer must remain free of persistence concerns.

### Class Declaration

- Must implement `AggregateRoot<T>` interface
- **No JPA annotations** in domain aggregate classes (domain should be persistence-agnostic)
- Use Lombok: `@Getter`, `@NoArgsConstructor(access = AccessLevel.PROTECTED)`
- Place in domain layer using business terminology (ubiquitous language)
- Domain entities are persisted via **envelope pattern** in infrastructure layer

### Constructor Pattern

- Protected no-args constructor for frameworks: `@NoArgsConstructor(access = AccessLevel.PROTECTED)`
- **Jackson constructor** for deserialization with `@JsonCreator` and `@JsonProperty` annotations
- Static factory `create()` method that takes an Info object as parameter
- Protected constructor that takes ID and Info object for controlled instantiation
- Register creation domain event on instantiation
- All validation logic should be in the factory method, not in Info objects

### Field Structure

- **Individual fields** for each business property (not a single `data` field)
- All fields protected/private with business-meaningful methods for state changes
- **No JPA annotations** on any fields (domain should be persistence-agnostic)
- Use **strongly typed identifiers** for entity IDs
- **No data field** containing Info objects - map Info to individual fields in constructor
- Fields should match the structure of corresponding Info objects for clean mapping

### Data Transfer and Persistence

- Implement `buildInfo()` method that reconstructs Info object from individual fields
- Use **envelope pattern** for persistence - JPA annotations are in infrastructure envelope classes
- Domain aggregates are serialized/deserialized using Jackson annotations
- `buildInfo()` method provides clean data transfer to infrastructure and web layers
- Infrastructure layer handles mapping between domain aggregates and JPA envelope entities

### Domain Events (Envelope Pattern)

- Register events for all state changes using `registerEvent(agg -> MySampleEntityCreatedEvent.from(agg))`
- Include relevant context (aggregate/entity IDs, changed data)
- Use immutable records for events
- Event names reflect business significance (e.g., `MySampleEntityCreatedEvent`)
- Each aggregate must implement the domain event management methods from the interface
- Domain events are stored in a `@Transient` field to avoid persistence

### Child Entity Guidelines (Envelope Pattern)

- **Child entities MUST have strongly typed IDs** wrapping UUID or int/long
- Child entities should have their own `buildInfo()` methods
- Pattern: `ChildEntityId` wrapping UUID, consistent with parent aggregates
- Child entities created using their Info objects from parent aggregate

### Envelope Pattern Example

```java
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class MySampleEntity implements AggregateRoot<MySampleEntity> {
    // Individual fields (not a data field)
    protected MySampleEntityId id;
    protected String businessField;
    protected MySampleEntityStatus status;
    protected OffsetDateTime createdAt;
    
    // Child entities as individual fields
    protected Set<MySampleEntityChild> children = new HashSet<>();
    
    @Transient
    private final List<Object> domainEvents = new ArrayList<>();

    // Jackson constructor for deserialization
    @JsonCreator
    protected MySampleEntity(
        @JsonProperty("id") MySampleEntityId id,
        @JsonProperty("businessField") String businessField,
        @JsonProperty("status") MySampleEntityStatus status,
        @JsonProperty("createdAt") OffsetDateTime createdAt,
        @JsonProperty("children") Set<MySampleEntityChild> children) {
        this.id = id;
        this.businessField = businessField;
        this.status = status;
        this.createdAt = createdAt;
        this.children = children != null ? children : new HashSet<>();
    }

    // Factory method that takes Info object
    public static MySampleEntity create(final MySampleEntityInfo info) {
        // Validation logic here - not in Info object
        if (info == null) {
            throw new ValidationErrorException(
                OperationResult.failure("MySampleEntityInfo cannot be null")
            );
        }
        if (info.getBusinessField() == null) {
            throw new ValidationErrorException(
                OperationResult.failure("Business field is required")
            );
        }
        
        var aggregate = new MySampleEntity(MySampleEntityId.generate(), info);
        aggregate.registerEvent(agg -> MySampleEntityCreatedEvent.from(agg));
        return aggregate;
    }

    // Protected constructor that maps Info to individual fields
    protected MySampleEntity(
        final MySampleEntityId id,
        final MySampleEntityInfo info) {
        this.id = id;
        
        // Map from Info object to individual fields
        this.businessField = info.getBusinessField();
        this.status = info.getStatus();
        this.createdAt = OffsetDateTime.now(ZoneOffset.UTC);
        
        // Create child entities using their Info objects
        if (info.getChildrenInfo() != null) {
            this.children = info.getChildrenInfo().stream()
                .map(childInfo -> new MySampleEntityChild(childInfo))
                .collect(Collectors.toSet());
        }
    }

    // Build Info object from individual fields for data transfer
    // Creates a readonly snapshot of current aggregate state
    // Used to safely pass data without exposing aggregate functionality
    public MySampleEntityInfo buildInfo() {
        return MySampleEntityInfo.builder()
            .businessField(businessField)
            .status(status)
            .createdAt(createdAt)
            .childrenInfo(children.stream()
                .map(MySampleEntityChild::buildInfo)  // Child entities also have buildInfo()
                .collect(Collectors.toSet()))
            .build();
    }

    public void businessOperation(MySampleEntityOperationInfo operationInfo) {
        // Business logic validation
        // State modification using individual fields
        this.businessField = operationInfo.getUpdatedBusinessField();
        this.registerEvent(agg -> new MySampleEntityBusinessOperationPerformedEvent(this.id, agg.buildInfo()));
    }

    @Override
    public void registerEvent(final Function<MySampleEntity, Object> eventFactory) {
        domainEvents.add(eventFactory.apply(this));
    }

    @Override
    public List<Object> getDomainEvents() {
        return new ArrayList<>(domainEvents);
    }

    @Override
    public void clearDomainEvents() {
        domainEvents.clear();
    }
}
```

### Envelope Integration

- **Domain aggregates** contain no JPA annotations - they are persistence-agnostic
- **Infrastructure envelope classes** extend `AggregateEnvelopeBase` and handle JPA persistence
- **Envelope is a wrapper** - no mapper needed, just wraps/unwraps aggregate
- **Repository implementations** wrap domain aggregates in envelopes for persistence
- **Application layer** never accesses envelopes directly - repositories handle all wrapping/unwrapping
- **Example**: `InstructionRequestEnvelope` extends `AggregateEnvelopeBase<InstructionRequest, InstructionRequestId>`
- **JSONB storage**: Complete domain aggregate serialized to `data` column via Jackson
- **buildInfo() method** creates readonly snapshots, not for persistence (envelope handles that)

---

## Direct JPA Pattern (JPA on Domain Entities)

Use this approach for simpler implementations where persistence decoupling is not required.

### Class Declaration

- Must extend `AggregateRoot<T>` base class to inherit domain event functionality
- **Use JPA annotations** for persistence mapping (`@Entity`, `@Table`, etc.)
- Use Lombok: `@Getter`, `@NoArgsConstructor(access = AccessLevel.PROTECTED)`
- Place in domain layer using business terminology (ubiquitous language)
- Domain entities use direct JPA mapping with individual columns for each field

### Constructor Pattern

- Protected no-args constructor for frameworks: `@NoArgsConstructor(access = AccessLevel.PROTECTED)`
- Static factory `create()` method that takes an Info object as parameter
- Protected constructor that takes ID and Info object for controlled instantiation
- Register creation domain event on instantiation
- All validation logic should be in the factory method, not in Info objects

### Field Structure

- **Individual fields** for each business property with JPA annotations
- All fields protected/private with business-meaningful methods for state changes
- **Use `@Entity`, `@Table`, `@Column`** annotations for JPA mapping
- Use **strongly typed identifiers** with `@EmbeddedId`
- **Use `@Convert`** for complex value objects (BIC, ClientId, etc.)
- Fields should match the structure of corresponding Info objects for clean mapping

### Data Transfer and Persistence

- Implement `buildInfo()` method that reconstructs Info object from individual fields
- **Use JPA annotations directly** on domain entities for persistence
- `@Transient` annotation for fields that should not be persisted (e.g., state machines)
- `buildInfo()` method provides clean data transfer to infrastructure and web layers
- Repository implementations work directly with domain entities

### Domain Events (Direct JPA Pattern)

- **Domain events are inherited from `AggregateRoot<T>`** base class
- Aggregates extend `AggregateRoot<MySampleEntity>` to get domain event functionality
- Register events for all state changes using `registerEvent(agg -> MySampleEntityCreatedEvent.from(agg))`
- Include relevant context (aggregate/entity IDs, changed data)
- Use immutable records for events
- Event names reflect business significance (e.g., `MySampleEntityCreatedEvent`)
- **Do not manually implement domain event methods** - they're inherited from base class

### Direct JPA Pattern Example

```java
@Entity
@Table(name = "my_sample_entity")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class MySampleEntity extends AggregateRoot<MySampleEntity> {
    // Individual fields with JPA annotations
    @EmbeddedId
    private MySampleEntityId id;
    
    @Column(name = "business_field")
    private String businessField;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    private MySampleEntityStatus status;
    
    @Column(name = "created_at")
    private OffsetDateTime createdAt;
    
    // Child entities with JPA relationship annotations
    @OneToMany(cascade = CascadeType.ALL, orphanRemoval = true)
    @JoinColumn(name = "parent_id")
    private Set<MySampleEntityChild> children = new HashSet<>();

    // Factory method that takes Info object
    public static MySampleEntity create(final MySampleEntityInfo info) {
        // Validation logic here - not in Info object
        if (info == null) {
            throw new ValidationErrorException(
                OperationResult.failure("MySampleEntityInfo cannot be null")
            );
        }
        if (info.getBusinessField() == null) {
            throw new ValidationErrorException(
                OperationResult.failure("Business field is required")
            );
        }
        
        var aggregate = new MySampleEntity(MySampleEntityId.generate(), info);
        aggregate.registerEvent(agg -> MySampleEntityCreatedEvent.from(agg));
        return aggregate;
    }

    // Protected constructor that maps Info to individual fields
    protected MySampleEntity(
        final MySampleEntityId id,
        final MySampleEntityInfo info) {
        this.id = id;
        
        // Map from Info object to individual fields
        this.businessField = info.getBusinessField();
        this.status = info.getStatus();
        this.createdAt = OffsetDateTime.now(ZoneOffset.UTC);
        
        // Create child entities using their Info objects
        if (info.getChildrenInfo() != null) {
            this.children = info.getChildrenInfo().stream()
                .map(childInfo -> MySampleEntityChild.create(childInfo))
                .collect(Collectors.toSet());
        }
    }

    // Build Info object from individual fields for data transfer
    public MySampleEntityInfo buildInfo() {
        return MySampleEntityInfo.builder()
            .businessField(businessField)
            .status(status)
            .createdAt(createdAt)
            .childrenInfo(children.stream()
                .map(MySampleEntityChild::buildInfo)
                .collect(Collectors.toSet()))
            .build();
    }

    // Business method that changes state and registers events
    public void businessOperation(MySampleEntityOperationInfo operationInfo) {
        // Business logic validation
        // State modification using individual fields
        this.businessField = operationInfo.getUpdatedBusinessField();
        registerEvent(agg -> new MySampleEntityBusinessOperationPerformedEvent(this.id, agg.buildInfo()));
    }
}
```

### JPA Integration

- **Domain aggregates** use JPA annotations for direct persistence mapping
- **`@Entity`, `@Table`, `@Column`** annotations on aggregate root entities
- **`@EmbeddedId`** for strongly typed identifiers
- **`@Convert`** with custom converters for value objects
- **Repository implementations** work directly with domain aggregates
- **buildInfo() method** provides clean interface for data transfer to web layer

---

## Common Requirements (Both Patterns)

### State Management

- State changes must register appropriate domain events using `registerEvent()`
- Child entity modifications go through aggregate root
- Only aggregate root exposes public methods
- Validate state transitions using explicit validation methods
- State machine integration works with individual status fields, not data objects

### Business Rules Validation

- Validate mandatory fields before state changes
- Enforce state transition rules
- Validate business constraints (e.g., ISIN format, amount validations)

### Info Object Integration

- **Factory methods** should accept Info objects, not individual parameters
- **Validation logic** belongs in aggregate factory methods, not Info objects
- **Individual fields** in aggregates are mapped from Info objects in constructor
- **buildInfo() method** reconstructs Info objects from individual fields for clean data transfer
- **Child entities** are created using their respective Info objects
- **Use case inputs** should contain Info objects for clean aggregate creation
- **Domain events** should use buildInfo() method instead of direct data access
