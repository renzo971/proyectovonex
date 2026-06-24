---
applyTo: "domain/**/*.java"
---

> **Note:** Java package examples below use `com.acme.securities` as a fictional placeholder. Replace with your organization's package root before generating production code.

# Domain Entity Implementation Guidelines

## Overview

Domain entities represent business objects with identity and lifecycle within the domain layer. They are the core
business concepts and rules, forming the foundation of the domain layer.

This document covers two architectural approaches:

1. **Envelope Pattern**: Domain entities are persistence-agnostic and use the envelope pattern for JPA integration (no JPA annotations in domain)
2. **Direct JPA Pattern**: Domain entities use JPA/Hibernate annotations for direct database mapping

## Project Context

- Package: `com.acme.securities.{project-name}.domain.model.mySampleEntity`
- Framework: Quarkus with JPA/Hibernate
- Architecture: Hexagonal Architecture with Clear Separation of Concerns

## Key Rules

### Naming and Structure

- Use business terminology in class and method names (ubiquitous language)
- Domain layer must not depend on other layers (infrastructure, application)
- Package organization follows aggregate boundaries
- Each aggregate has its own package with entities, value objects, and events
- Use strongly typed identifiers for all entities and aggregates
- Keep domain layer free of technical or infrastructure concerns

### Architecture Constraints

#### Envelope Pattern

- **Domain layer** must be technology-agnostic (no JPA annotations in domain entities)
- **All entities** should have NO JPA annotations - persistence is handled via envelope pattern
- **Individual fields** should not have JPA annotations in domain entities
- **Jackson annotations** are used for serialization/deserialization (`@JsonCreator`, `@JsonProperty`)
- **Envelope pattern** separates domain logic from persistence concerns

#### Direct JPA Pattern

- **Domain entities** use JPA annotations (`@Entity`, `@Table`, `@Column`, etc.)
- **Individual fields** are mapped to database columns using JPA annotations
- **Strongly typed IDs** use `@EmbeddedId` for type safety
- **Converters** handle complex value objects (e.g., `@Convert(converter = BicConverter.class)`)

### Common Requirements

- All business rules must be enforced within the domain layer
- Use domain exceptions for business rule violations
- **Info objects** provide clean data transfer from web layer to domain
- **Validation logic** belongs in entity factory methods, not Info objects

### Package Organization

```
domain/src/main/java/com/acme/securities/{project-name}/domain/model/
└── mySampleEntity/
    ├── MySampleEntity.java
    ├── MySampleEntityChild.java
    ├── MySampleEntityId.java
    └── event/
        └── MySampleEntityCreatedEvent.java
```

## Strongly Typed IDs

### Requirements

- Create dedicated ID class for each entity/aggregate type
- Use factory methods (`of()`, `generate()`) for creation with validation
- Never use primitive types for IDs in domain layer

#### Envelope Pattern

- **No JPA annotations** in domain ID classes - envelope pattern handles persistence
- ID classes should be clean domain objects without infrastructure concerns

#### Direct JPA Pattern

- **Use `@Embeddable` annotation** on ID classes
- **Entities use `@EmbeddedId`** to reference the ID class
- Use `@Convert` with custom converters for JPA persistence

### Implementation Pattern

#### Envelope Pattern

```java
@Getter
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class MySampleEntityId {
    private UUID value;

    public static MySampleEntityId generate() {
        return new MySampleEntityId(UuidGenerator.generateUuidV7());
    }

    public static MySampleEntityId of(UUID value) {
        if (value == null) {
            throw new InvalidParameterException("MySampleEntity Id cannot be null");
        }
        return new MySampleEntityId(value);
    }
}
```

#### Direct JPA Pattern

```java
@Embeddable
@Getter
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class MySampleEntityId {
    @Column(name = "id")
    private UUID value;

    public static MySampleEntityId generate() {
        return new MySampleEntityId(UuidGenerator.generateUuidV7());
    }

    public static MySampleEntityId of(UUID value) {
        if (value == null) {
            throw new InvalidParameterException("MySampleEntity Id cannot be null");
        }
        return new MySampleEntityId(value);
    }
}
```

## Entity Implementation

### Access Control and Construction

- Fields must be `protected` or `private`
- State changes only via methods with business meaning
- Factory methods (`create()`) for controlled instance creation
- Protected no-args constructor for frameworks: `@NoArgsConstructor(access = PROTECTED)`
- Constructors and methods should be package-private (default visibility) for child entities
- No public constructors except where needed for specific patterns

#### Envelope Pattern

- **Jackson constructor** for deserialization with `@JsonCreator` and `@JsonProperty`

### Factory Pattern

- New instances created using static factory `create()` method that accepts Info objects
- Factory method validates all required fields and business rules
- Used by parent entity to create child entity instances using child Info objects
- Validate all parameters in factory method, not in Info objects
- Map Info object fields to individual entity fields in constructor
- **buildInfo() method** reconstructs Info objects from individual fields for clean data transfer

### Persistence Integration

#### Envelope Pattern

- **No JPA annotations** in domain entities - use envelope pattern instead
- **Infrastructure envelope classes** handle JPA persistence with full annotations
- **Repository mappers** convert between domain entities and envelope classes  
- Domain entities focus purely on business logic without persistence concerns
- Use Jackson annotations (`@JsonCreator`, `@JsonProperty`) for serialization only
- **buildInfo() method** provides clean data transfer interface

#### Direct JPA Pattern

- **Use JPA annotations** on domain entities (`@Entity`, `@Table`, `@Column`)
- **`@EmbeddedId`** for strongly typed identifiers
- **`@Convert`** with custom converters for value objects (BIC, ClientId, etc.)
- **`@Enumerated(EnumType.STRING)`** for enum fields
- **`@OneToMany`, `@ManyToMany`, `@ManyToOne`** for relationships
- **Column definitions**: Use `columnDefinition` for specific types (e.g., `columnDefinition = "bpchar"` for CHAR columns)
- **`@Transient`** for fields that should not be persisted (e.g., state machines)
- **Note**: Regular entities do not extend `AggregateRoot` and do not register domain events

### Business Logic

- Implement business validation in entity methods
- Throw meaningful exceptions for business rule violations (e.g., `IllegalArgumentException`, `IllegalStateException`)
- Use business terminology in method names (ubiquitous language)
- Keep domain layer free of technical/infrastructure concerns

### Aggregate Relationships

- Child entities must be created through parent aggregate
- State changes to child entities go through aggregate root
- Child entities should not expose public constructors and methods
- No cross-aggregate references by object (use IDs instead)

## Validation Rules

- Validate all IDs on creation using factory methods
- Validate business rules in entity methods
- Throw meaningful `IllegalArgumentException` or `IllegalStateException` for violations
- Ensure all domain objects are properly validated before persistence
- Use descriptive error messages that reflect business terminology

## Example: Aggregate Root Entity

### Envelope Pattern

```java
@Getter
@NoArgsConstructor(access = PROTECTED)
public class MySampleEntity implements AggregateRoot<MySampleEntity> {
    // Individual fields (not a data field)
    protected MySampleEntityId id;
    protected MySampleEntityStatus state;
    protected String businessField;
    protected OffsetDateTime createdAt;

    // Jackson constructor for deserialization
    @JsonCreator
    protected MySampleEntity(
        @JsonProperty("id") MySampleEntityId id,
        @JsonProperty("state") MySampleEntityStatus state,
        @JsonProperty("businessField") String businessField,
        @JsonProperty("createdAt") OffsetDateTime createdAt) {
        this.id = id;
        this.state = state;
        this.businessField = businessField;
        this.createdAt = createdAt;
    }

    // Factory method accepts Info object
    public static MySampleEntity create(final MySampleEntityInfo info) {
        // Validation logic here
        if (info == null) {
            throw new IllegalArgumentException("MySampleEntityInfo cannot be null");
        }
        if (info.getBusinessField() == null) {
            throw new IllegalArgumentException("Business field cannot be null");
        }

        return new MySampleEntity(MySampleEntityId.generate(), info);
    }
    
    // Protected constructor maps Info to individual fields
    protected MySampleEntity(
        final MySampleEntityId id,
        final MySampleEntityInfo info) {
        this.id = id;
        this.state = MySampleEntityStatus.DRAFT;
        this.businessField = info.getBusinessField();
        this.createdAt = OffsetDateTime.now(ZoneOffset.UTC);
    }

    // Build Info object from individual fields for data transfer
    // Creates a readonly snapshot of current entity state
    public MySampleEntityInfo buildInfo() {
        return MySampleEntityInfo.builder()
            .businessField(businessField)
            .state(state)
            .createdAt(createdAt)
            .build();
    }
}
```

### Direct JPA Pattern

```java
@Entity
@Table(name = "my_sample_entity")
@Getter
@NoArgsConstructor(access = PROTECTED)
public class MySampleEntity {
    // Individual fields with JPA annotations
    @EmbeddedId
    private MySampleEntityId id;

    @Enumerated(EnumType.STRING)
    private MySampleEntityStatus state;

    @Column(name = "business_field")
    private String businessField;

    @Column(name = "created_at")
    private Instant createdAt;

    // Factory method accepts Info object
    public static MySampleEntity create(final MySampleEntityInfo info) {
        // Validation logic here
        if (info == null) {
            throw new IllegalArgumentException("MySampleEntityInfo cannot be null");
        }
        if (info.getBusinessField() == null) {
            throw new IllegalArgumentException("Business field cannot be null");
        }

        return new MySampleEntity(MySampleEntityId.generate(), info);
    }
    
    // Protected constructor maps Info to individual fields
    protected MySampleEntity(
        final MySampleEntityId id,
        final MySampleEntityInfo info) {
        this.id = id;
        this.state = MySampleEntityStatus.DRAFT;
        this.businessField = info.getBusinessField();
        this.createdAt = Instant.now();
    }

    // Build Info object from individual fields for data transfer
    public MySampleEntityInfo buildInfo() {
        return MySampleEntityInfo.builder()
            .businessField(businessField)
            .state(state)
            .createdAt(createdAt)
            .build();
    }

    // Business methods that change state
    public void updateBusinessField(String newValue) {
        if (newValue == null) {
            throw new IllegalArgumentException("Business field cannot be null");
        }
        this.businessField = newValue;
    }
}
```

## Example: Child Entity Structure

### Envelope Pattern

```java
@Getter
@NoArgsConstructor(access = PROTECTED)
public class MySampleEntityChild {
    // Child entities MUST have strongly typed IDs
    protected MySampleEntityChildId id;  // Strongly typed ID wrapping UUID
    protected String fieldName;
    protected ChildStatus status;

    // Jackson constructor for deserialization
    @JsonCreator
    MySampleEntityChild(
        @JsonProperty("id") MySampleEntityChildId id,
        @JsonProperty("fieldName") String fieldName,
        @JsonProperty("status") ChildStatus status) {
        this.id = id;
        this.fieldName = fieldName;
        this.status = status;
    }

    // Package-private factory method accepts Info object
    static MySampleEntityChild create(final MySampleEntityChildInfo info) {
        // Validation logic
        if (info == null) {
            throw new IllegalArgumentException("MySampleEntityChildInfo cannot be null");
        }
        if (info.getFieldName() == null) {
            throw new IllegalArgumentException("Field name cannot be null");
        }
        
        return new MySampleEntityChild(MySampleEntityChildId.generate(), info);
    }
    
    // Package-private constructor maps Info to individual fields
    MySampleEntityChild(
        final MySampleEntityChildId id,
        final MySampleEntityChildInfo info) {
        this.id = id;  // Strongly typed ID
        this.fieldName = info.getFieldName();
        this.status = info.getStatus();
    }

    // Build Info object from individual fields for data transfer
    // Creates readonly snapshot of current child entity state
    MySampleEntityChildInfo buildInfo() {
        return MySampleEntityChildInfo.builder()
            .id(id)
            .fieldName(fieldName)
            .status(status)
            .build();
    }

    // Business methods with validation
    void businessMethod(Parameter param) {
        // Business logic and validation
    }

    // Getters only - no setters provided by @Getter
    // Additional custom getters if needed
}
```

### Direct JPA Pattern

```java
@Embeddable
@Getter
@NoArgsConstructor(access = PROTECTED)
public class MySampleEntityChild {
    // JPA mapping for embedded objects
    @Column(name = "field_name")
    protected String fieldName;

    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    protected ChildStatus status;

    @Column(name = "identifier")
    protected String identifier; // Simple field for identification within aggregate

    // Package-private factory method accepts Info object
    static MySampleEntityChild create(final MySampleEntityChildInfo info) {
        // Validation logic
        if (info == null) {
            throw new IllegalArgumentException("MySampleEntityChildInfo cannot be null");
        }
        if (info.getFieldName() == null) {
            throw new IllegalArgumentException("Field name cannot be null");
        }
        
        return new MySampleEntityChild(info);
    }
    
    // Package-private constructor maps Info to individual fields
    MySampleEntityChild(final MySampleEntityChildInfo info) {
        this.identifier = UUID.randomUUID().toString(); // Generate simple identifier
        this.fieldName = info.getFieldName();
        this.status = info.getStatus();
    }

    // Build Info object from individual fields for data transfer
    MySampleEntityChildInfo buildInfo() {
        return MySampleEntityChildInfo.builder()
            .fieldName(fieldName)
            .status(status)
            .identifier(identifier)
            .build();
    }

    // Business methods with validation
    void businessMethod(Parameter param) {
        // Business logic and validation
    }
}
```
