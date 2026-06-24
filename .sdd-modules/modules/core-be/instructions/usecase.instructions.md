---
applyTo: "application/**/*UseCase*.java"
---

> **Note:** Java package examples below use `com.acme.securities` as a fictional placeholder. Replace with your organization's package root before generating production code.

# Use Case Implementation Guidelines

## Overview

Use cases represent business operations and coordinate between domain model and infrastructure. They maintain separation of concerns.

## Project Context

## Core Principles

- One use case = one business operation
- Single responsibility
- Explicit input/output contracts
- Business naming
- Input classes must be immutable with no business rules
- Output classes must extend `UseCaseOutput` with `OperationResult` for consistent error handling
- **ALWAYS throw exceptions** - never return `OperationResult.failure()`
- **NO try/catch blocks** - let exceptions propagate to error handling layer
- **NO logging** - logging handled by infrastructure layer
- Error handling layer captures all exceptions to keep use cases clean
- Separate interface and implementation for each use case

## Structure

```
application/src/main/java/com/acme/securities/{project-name}/application/usecase/
└── mySampleEntity/
    └── create/
        ├── CreateMySampleEntityUseCase.java       # Interface
        ├── CreateMySampleEntityUseCaseImpl.java   # Implementation
        ├── CreateMySampleEntityInput.java
        └── CreateMySampleEntityOutput.java
```

## Implementation Patterns

### Use Case Interface

```java
public interface CreateMySampleEntityUseCase extends UseCase<CreateMySampleEntityInput, CreateMySampleEntityOutput> {
}
```

### Use Case Implementation

```java

@ApplicationScoped
@RequiredArgsConstructor
public class CreateMySampleEntityUseCaseImpl implements CreateMySampleEntityUseCase {
    private final MySampleEntityRepository repository;

    @Override
    @Transactional
    public CreateMySampleEntityOutput execute(CreateMySampleEntityInput input, ExecutionContext context) {
        // Get required context data (e.g., user ID)
        var userId = context.getUserId().getValue();
        if (userId == null) {
            throw new IllegalArgumentException("User ID not found in context");
        }

        // Load or create aggregate root
        var aggregate = repository.findById(input.getId())
                .orElseThrow(() -> new IllegalArgumentException("Aggregate not found"));

        // Persist changes
        repository.persist(aggregate);

        // Return success result
        return new CreateMySampleEntityOutput(OperationResult.success());
    }
}
```

### Input Class

```java
public record CreateMySampleEntityInput(
        // input parameters
) implements UseCaseInput {
}
```

### Output Class

```java

@Value
public class CreateMySampleEntityOutput extends UseCaseOutput {
    // output data
}
```

## Requirements

### Use Case Interface

- Must extend `UseCase<Input, Output>`
- Simple interface defining the contract

### Use Case Implementation

- Must implement the use case interface
- Must have `@ApplicationScoped` annotation for CDI
- Must have `@RequiredArgsConstructor` for dependency injection
- Must have `@Transactional` annotation on execute method
- Must implement exactly one business operation
- Must follow business naming conventions
- **Must ALWAYS throw exceptions** - never return `OperationResult.failure()`
- **Must NOT use try/catch blocks** - let exceptions propagate to error handling layer
- Must validate input parameters and context data
- Exceptions automatically handled by infrastructure error handling layer (API Exception mappers)

### Input Class

- Must be implemented as a record
- Must implement `UseCaseInput` interface
- Must be immutable with `@Builder` for convenient creation
- Must contain no business logic or validation rules

### Output Class

- Must extend `UseCaseOutput`
- Must be immutable
- Must contain no business logic

### Structure

- Must be organized by aggregate in separate folders
- Each use case must have its own folder containing interface, implementation, input, and output classes
- Must follow the specified package structure

### Execution Pattern

- Validate input parameters
- Load/fetch aggregate root from repository
- Perform business operation on aggregate
- Persist changes via repository
- Return appropriate output
