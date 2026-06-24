---
applyTo: "**/*Test.java"
description: Java-specific testing patterns — JUnit 5, AssertJ, Mockito, Instancio, Cucumber, REST Assured, Testcontainers
---

# Java Testing Implementation Guidelines

## Project-Specific Testing Tools

### Testing Dependencies

- **JUnit 5** for test framework
- **AssertJ** for fluent assertions (`assertThat()` syntax)
- **Mockito** for mocking dependencies (via `quarkus-junit5-mockito`)
- **Instancio** for test data generation (`instancio-junit`)
- **Quarkus Test Framework** for integration testing
- **Maven Surefire Plugin** for test execution

### Dependencies by Module

- Domain: JUnit 5, AssertJ, Mockito, Instancio
- Application: JUnit 5, AssertJ, Mockito
- Infrastructure: JUnit 5, AssertJ, Mockito, Quarkus Test
- Integration Tests: All above plus Cucumber, REST Assured, Testcontainers

## Test Data Generation

Use **Instancio** and **InstancioTestSupport** for consistent test data generation:

```java
// Using InstancioTestSupport for domain data
var testData = InstancioTestSupport.createDataWithAuthor(testUserId);
var testInstructionRequest = InstructionRequest.createDraft(testUserId, testData);

// For complex scenarios with specific fields
var data = InstancioTestSupport.createDataWithAllFields(
    InstructionRequestStatus.DRAFT,
    createdBy, null, "REF123",
    InstructionType.DVP, MovementType.DELIVERY,
    PaymentType.APMT, "COMMON123"
);

// For multiple instances
var requests = Instancio.stream(InstructionRequestInfo.class)
    .limit(5)
    .map(data -> InstructionRequest.createDraft(testUserId, data))
    .toArray(InstructionRequest[]::new);
```

## Mocking Patterns

Use Mockito annotations for clean dependency mocking:

```java
@ExtendWith(MockitoExtension.class)
@DisplayName("CreateInstructionRequestUseCaseImpl Unit Tests")
class CreateInstructionRequestUseCaseImplTest {

    @Mock
    private InstructionRequestRepository repository;

    @Mock
    private ObjectMapper objectMapper;

    @Mock
    private ExecutionContext context;

    @InjectMocks
    private CreateInstructionRequestUseCaseImpl useCase;

    @BeforeEach
    void setUp() {
        testUserId = UserId.of(UUID.randomUUID());
        validInput = InstancioTestSupport.createMinimalInput();
        testData = InstancioTestSupport.createDraftData();
    }
}
```

## Layer-Specific Testing

### Domain Layer Testing (`domain/`)

- All domain entities, value objects, and aggregates must have comprehensive unit tests
- Test creation, validation, and business logic
- Use InstancioTestSupport for consistent data generation
- Focus on domain behavior and invariants

### Application Layer Testing (`application/`)

- Use cases tested with mocked dependencies
- Test orchestration logic and business workflows
- Mock repository and external dependencies using `@Mock`
- Verify interactions using Mockito's `verify()` methods
- Use `@ExtendWith(MockitoExtension.class)` for proper setup

### Infrastructure Layer Testing (`infrastructure/`)

- Repository implementations test persistence logic
- Query handlers test data retrieval and transformation
- Use mocked EntityManager for repository tests
- Test both new entity persistence and existing entity merging

### Integration Testing (`test/`)

- Integration tests in separate `test` module
- Use Cucumber BDD with step definitions
- REST Assured for API testing
- Testcontainers for database/Kafka containers
- Quarkus test annotations for dependency injection

## Running Tests

```bash
# Run all tests
mvn test

# Run tests for specific module
mvn test -pl domain

# Run specific test class
mvn test -Dtest=InstructionRequestTest
```
