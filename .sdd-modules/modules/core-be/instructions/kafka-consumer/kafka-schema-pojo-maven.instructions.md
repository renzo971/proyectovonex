---
applyTo: "infrastructure/src/main/resources/schemas/**/*.json"
description: Maven-based POJO generation from JSON schemas using jsonschema2pojo plugin for Kafka contracts
---

# Kafka Schema POJO Contract — Maven Plugin & Java Types

## Overview

Standardizes automated POJO generation from JSON schemas using the jsonschema2pojo Maven plugin. Ensures consistent type-safe Kafka message contracts in the infrastructure layer.

## Project Context

- **Framework**: Quarkus
- **Module**: Multi-module Maven project (infrastructure module)
- **Schema Location**: `infrastructure/src/main/resources/schemas/`
- **Generated Sources**: `target/generated-sources/jsonschema2pojo/`
- **Package Structure**: `com.company.project.infrastructure.messaging.schemas`
- **Code Generation**: jsonschema2pojo-maven-plugin v1.2.2

## Maven Plugin Configuration

Add to infrastructure module's `pom.xml`:

```xml
<plugin>
    <groupId>org.jsonschema2pojo</groupId>
    <artifactId>jsonschema2pojo-maven-plugin</artifactId>
    <version>1.2.2</version>
    <executions>
        <execution>
            <goals><goal>generate</goal></goals>
        </execution>
    </executions>
    <configuration>
        <sourceDirectory>${project.basedir}/src/main/resources/schemas/</sourceDirectory>
        <generateBuilders>true</generateBuilders>
        <usePrimitives>false</usePrimitives>
        <sourceType>jsonschema</sourceType>
        <includeGetters>true</includeGetters>
        <includeSetters>false</includeSetters>
        <useInnerClassBuilders>true</useInnerClassBuilders>
        <includeTypeInfo>false</includeTypeInfo>
        <includeConstructors>true</includeConstructors>
    </configuration>
</plugin>
```

**Configuration**:
- `generateBuilders: true` — Creates builder pattern for object construction
- `usePrimitives: false` — Uses wrapper types (Integer, Boolean) instead of primitives
- `includeSetters: false` — Ensures immutability
- `useInnerClassBuilders: true` — Builder as inner class of POJO

## Java Type Mapping

| Java Type | JSON Schema Type | Schema Format |
|-----------|------------------|---------------|
| String | `"type": "string"` | — |
| UUID | `"type": "string"` | `"format": "uuid"` |
| Integer | `"type": "integer"` | — |
| Long | `"type": "integer"` | `"format": "int64"` |
| BigDecimal | `"type": "number"` | — |
| Boolean | `"type": "boolean"` | — |
| ZonedDateTime | `"type": "string"` | `"format": "date-time"` |
| LocalDate | `"type": "string"` | `"format": "date"` |
| Array/List | `"type": "array"` | `"items": {...}` |
| Nested Object | `"type": "object"` | `"properties": {...}` |
| Enum | `"type": "string"` | `"enum": [...]` |

## Generated POJO Structure

```
target/generated-sources/jsonschema2pojo/
└── com/company/project/infrastructure/messaging/schemas/
    ├── OrderEvent.java
    ├── PaymentEvent.java
    └── customer/
        ├── CustomerCreatedEvent.java
        └── CustomerUpdatedEvent.java
```

Generated classes include:
- `@JsonInclude(JsonInclude.Include.NON_NULL)`
- `@JsonPropertyOrder` for consistent serialization
- Builder pattern (inner class)
- Getters only (no setters for immutability)
- Constructors

## Naming Conventions

- **Schema Files**: kebab-case with `.json` extension (e.g., `order-created-event.json`)
- **Schema Title**: PascalCase matching generated class name (e.g., `"OrderCreatedEvent"`)
- **Property Names**: camelCase (e.g., `"orderId"`, `"customerName"`)
- **Nested Directories**: Organize by domain/bounded context

## Interactive Schema Creation

When creating schemas, ask the user for field definitions:

```json
{
   "fieldName1": "type",
   "fieldName2": "type"
}
```

Valid types: string, int, long, BigDecimal, boolean, UUID, ZonedDateTime, LocalDate, array, object

Then:
1. Verify response is valid JSON
2. Map each field to proper JSON Schema type
3. Ask which fields are required
4. Ask about validation rules (min/max, pattern, enum)

## Infrastructure Isolation

- Schema POJOs remain in infrastructure layer
- Map to domain models in application layer
- Generated POJOs must never be manually modified
- JSON schema is the single source of truth
