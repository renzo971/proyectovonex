---
applyTo: "domain/**/*Info.java"
---

> **Note:** Java package examples below use `com.acme.securities` as a fictional placeholder. Replace with your organization's package root before generating production code.

# Info Object Implementation Guidelines

## Overview

Info objects are immutable data containers that encapsulate all necessary fields for creating domain entities and
aggregates. They serve as a bridge between the infrastructure layer and domain layer, facilitating clean aggregate
creation while keeping use case code simple and maintainable.

## Project Context

- Package: `com.acme.securities.{project-name}.domain.model.mySampleEntity`
- Framework: Quarkus with JPA/Hibernate (for persistence layer only)
- Usage: Transfer data from infrastructure to aggregate and entities factory methods

## Key Principles

### Design Philosophy

- Info objects are **pure, passive data containers** with absolutely **NO business logic whatsoever**
- Used exclusively for **object creation and updates** - not for persistence or serialization
- Should contain **all fields** necessary to create or update the corresponding entity/aggregate
- **Builder pattern only** - no factory methods or validation logic
- **Domain-pure** - no JSON annotations or persistence concerns
- **1:1 relationship** with corresponding domain entity/aggregate
- **NO validation** - all validation happens in aggregate factory/update methods
- **Value Objects allowed** - can nest Value Objects for complex field types requiring validation

### Naming Convention

- Always suffix with `Info` (e.g., `HoldReleaseRequestInfo`, `InstructionRequestInfo`)
- Use the same name as the corresponding entity/aggregate with `Info` suffix
- Place in the same package as the corresponding entity

## Implementation Requirements

### Class Structure

- Must be **immutable** using `@Value` annotation
- Must implement **builder pattern** using `@Builder(toBuilder = true)`
- **No JSON annotations** (`@JsonDeserialize`, `@JsonPOJOBuilder`, etc.)
- **No factory methods** (createNew(), empty(), etc.)
- **No validation methods** (validate(), etc.)
- **No business logic** whatsoever

### Field Guidelines

- All fields should be **immutable types** or value objects
- Use **strongly typed identifiers** (e.g., `HoldReleaseRequestId` instead of `UUID`)
- Use **Value Objects** for complex data types requiring validation (e.g., `EmailAddress`, `PartyName`)
- Use **enums** for status and type fields
- Fields should represent the **complete state** needed for entity creation or updates
- **NO validation methods** - validation belongs in aggregate factory/update methods

### Builder Pattern

- Use `@Builder(toBuilder = true)` for immutability and copying
- Builder should have **no prefix** (default Lombok behavior)
- No custom builder methods or validation in builder

## Implementation Example

```java
/**
 * Immutable Info object containing all data necessary for creating HoldReleaseRequest aggregate.
 * Used to transfer data from web layer to domain layer through use case inputs.
 * This is a passive data container with NO validation or business logic.
 */
@Value
@Builder(toBuilder = true)
public class HoldReleaseRequestInfo {
    
    // Required fields for aggregate creation
    InstructionId instructionId;
    String requestNumber;
    OffsetDateTime createdAt;
    String senderReference;
    String transactionId;
    UUID createdBy;
    UUID approverUserId;
    HoldReleaseRequestStatus status;
    
    // Value objects for complex data with validation
    // Validation happens INSIDE the Value Object, not in this Info object
    SecuritiesAccount securitiesAccount;  // Value Object
    EmailAddress contactEmail;             // Value Object with email format validation
    PartyName partyName;                   // Value Object with name validation
    
    // Nested Info objects for child entities
    RequestDetailsInfo requestDetails;
}
```

### Example with Value Objects

```java
/**
 * Info object demonstrating use of Value Objects for complex validation.
 * The Info object itself has NO validation - validation is encapsulated in Value Objects.
 */
@Value
@Builder(toBuilder = true)
public class PartyInfo {
    PartyId id;                    // Strongly typed ID
    PartyName name;                // Value Object with name validation rules
    EmailAddress email;            // Value Object with email format validation
    PhoneNumber phone;             // Value Object with phone format validation
    PartyStatus status;            // Enum
    OffsetDateTime createdAt;      // Standard immutable type
}
```

## Usage Pattern

### In Web Layer (DTOs to Info)

```java
public class CreateHoldReleaseRequestRequest {
    // DTO fields...
    
    public CreateHoldReleaseRequestInput toInput(InstructionId instructionId, UUID userId) {
        final var info = HoldReleaseRequestInfo.builder()
            .instructionId(instructionId)
            .createdBy(userId)
            .securitiesAccount(this.securitiesAccount.toValueObject())
            .requestDetails(
                RequestDetailsInfo.builder()
                    // Map fields from requestDetails to RequestDetailsInfo
                    .build()
            )
            .build();
            
        return new CreateHoldReleaseRequestInput(info);
    }
}
```

### In Use Case Input

```java
public record CreateHoldReleaseRequestInput(
    HoldReleaseRequestInfo holdReleaseRequestInfo
) implements UseCaseInput {
}
```
