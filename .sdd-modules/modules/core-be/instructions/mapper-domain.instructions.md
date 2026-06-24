---
applyTo: "infrastructure/**/*Mapper.java"
description: Domain-specific mapper patterns — State projection, Command transformation, Domain orchestration, and Workflow transitions
---

# Domain Mapper Implementation Guidelines

## Overview

This document covers domain-specific mapper categories used in the Envelope Pattern architecture with Kafka, Elasticsearch, and ISO 20022 integration.

## Mapper Categories

### 1. State Mappers (Kafka State → Domain for Elasticsearch)

**Purpose**: Project Kafka state events into domain objects stored in Elasticsearch for read model queries.

**Examples**: `InstructionStateMapper`, `AllegementStateMapper`, `RestrictionStateMapper`

**Characteristics**:
- Implement Camel `Processor` interface for integration with Apache Camel routes
- Use `@ApplicationScoped` for CDI dependency injection
- Unidirectional: Kafka State Objects → Domain Objects (for Elasticsearch storage)
- Process `SettlementTransactionState` or `RestrictionState` contracts
- Handle state-specific logic (modification requests, parked allegements, etc.)

**Method Naming**: `fromStateToInstruction()`, `fromStateToAllegement()`, `fromStateToRestriction()`

**Key Guidelines**:
- Use explicit builder pattern for all domain object construction
- Apply enum conversions from ISO codes to domain enums (via `StateEnumConverter`)
- Handle null safety for all optional fields
- Map nested structures with dedicated helper methods
- **Never** use `ObjectMapper.convertValue()` for domain objects

### 2. Command Mappers (Domain Event → External System Command)

**Purpose**: Transform domain events into ISO 20022 messages for external system integration.

**Examples**: `CreateSettlementInstructionCommandMapper`, `CreateRestrictionCommandMapper`

**Characteristics**:
- Implement `Mapper<DomainEvent, Object>` interface
- Use `@ApplicationScoped` for CDI
- Unidirectional: Domain Event → ISO 20022 Command Message
- Often very large (1000+ lines) due to ISO message complexity
- Should be split into orchestrator + sub-mappers when exceeding 1000 lines

**Large Mapper Splitting**:
- Create orchestrator mapper with main `fromEventToCommand()` method
- Create sub-mappers for ISO structures (Party, Amount, Trade, etc.)
- Place sub-mappers in same `infrastructure.mapper` package
- Use `@ApplicationScoped` and `@RequiredArgsConstructor` for all mappers
- Inject sub-mappers into orchestrator

**Null Check Strategy**:
- Sub-mapper handles null internally — orchestrator doesn't need to check before delegating
- ISO builders ignore null values (omitted from JSON serialization)

### 3. Domain Orchestrator Mappers (Elasticsearch JSON ↔ API Model)

**Purpose**: Convert between domain objects (read from Elasticsearch) and API models (REST responses).

**Examples**: `InstructionMapper`, `AllegementMapper`, `RestrictionMapper`

**Characteristics**:
- Use `@ApplicationScoped` for CDI
- Use `@RequiredArgsConstructor` for dependency injection
- Bidirectional: Domain ↔ API and JSON → Domain
- Delegate to specialized sub-mappers for nested structures
- Include search response conversion (no separate SearchResponseMapper)
- Include JSON parsing methods

**Method Naming**:
- `fromDomainToApiInstruction()` — Domain Object → API Model
- `fromJsonToDomainInstruction()` — Elasticsearch JSON String → Domain Object
- `fromPagedResultToSearchResponse()` — Domain PagedResult → API Search Response

**JSON Parsing Integration**:
- Parse Elasticsearch JSON using `ObjectMapper.readTree()` and JsonNode navigation
- Extract nested fields with null safety
- Return fully constructed domain objects
- `ObjectMapper.convertValue()` is acceptable for JSON parsing, NOT for domain creation

### 4. Operation Mappers (API Request ↔ Use Case Input/Output)

**Purpose**: Convert API requests to use case inputs and use case outputs to API responses.

**Characteristics**:
- Use `@ApplicationScoped` for CDI
- Use `@RequiredArgsConstructor` for dependency injection
- Bidirectional: API Request → Use Case Input AND Use Case Output → API Response
- **MUST use explicit builder pattern for Info object creation** (never `ObjectMapper.convertValue()`)

**Method Naming**:
- `toInput(...)` — API Request → Use Case Input
- `toResponse(...)` — Use Case Output → API Response

### 5. Workflow Transition Mappers (Transition Code → Use Case Input)

**Purpose**: Map workflow transition codes to appropriate use case inputs.

**Characteristics**:
- Accept `JsonNode rawRequest` parameter for flexible payload extraction
- Use switch statements for transition code mapping
- Throw `ValidationErrorException` for unknown transition codes

**Method Naming**: `fromTransitionCodeToUseCaseInput()`

### 6. Specialized Sub-Mappers (Nested Object Conversions)

**Purpose**: Handle conversion of specific nested structures.

**Examples**: `InstructionAmountMapper`, `InstructionPartyMapper`, `InstructionSecuritiesMapper`

**Characteristics**:
- Always bidirectional (API ↔ Domain) even if one direction currently unused
- Package-private visibility when only used within same package
- Include `fromJsonToDomain*()` methods for JSON parsing support

### 7. Enum Mappers (Complex Code Transformations)

**Purpose**: Handle complex code-to-enum transformations including ISO to API enum conversions.

**When to Create**:
- Only for complex code-to-enum transformations with business logic
- Examples: Priority codes ("0003" → HIGH), Partial settlement indicators ("PART" → ALLOWED)
- ISO code to API conversions ("DELI" → DELIVERY, "RECE" → RECEIVE)
- NOT for simple enum conversions (use `EnumMappingUtils.safeConvertEnum()` instead)

### 8. Helper Methods for Simple Value Extraction

**Naming Convention**: Use `extract*` prefix for internal helpers.
- `extractCurrency()`, `extractAmount()`, `extractSettlementQuantity()`
- Always private visibility, return simple types
