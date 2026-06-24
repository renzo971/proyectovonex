---
applyTo: "domain/**/*.java"
---

> **Note:** Java package examples below use `com.acme.securities` as a fictional placeholder. Replace with your organization's package root before generating production code.

# Value Object Implementation Guidelines

## Overview

Value objects represent immutable concepts with no identity. They provide type safety and encapsulate business rules and
validations.

## Project Context

- Package: `com.acme.securities.{project-name}.domain.valueobject`
- Framework: Quarkus with JPA/Hibernate

## Core Principles

- Immutability: Value objects must be completely immutable
- No identity: Equality based on value, not identity (no ID field)
- Self-validation: Validate all constraints in constructor or factory methods
- Type safety: Replace primitive obsession with meaningful value objects
- Domain behavior: Include domain-specific methods and business rules

## Implementation Patterns

### Simple Value Objects (Records)

Use Java records for simple value objects without JPA persistence requirements:

```java
public record MySampleValueObject(BigDecimal amount, String currency) {
    public MySampleValueObject {
        if (amount == null) {
            throw new IllegalArgumentException("Amount cannot be null");
        }
        if (amount.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("Amount must be non-negative");
        }
        if (currency == null || currency.isBlank()) {
            throw new IllegalArgumentException("Currency must not be null or blank");
        }
        if (currency.length() != 3) {
            throw new IllegalArgumentException("Currency must be 3 characters (ISO 4217)");
        }
    }

    public MySampleValueObject add(MySampleValueObject other) {
        if (!this.currency.equals(other.currency)) {
            throw new IllegalArgumentException("Cannot add different currencies");
        }
        return new MySampleValueObject(this.amount.add(other.amount), this.currency);
    }

    public boolean isZero() {
        return amount.compareTo(BigDecimal.ZERO) == 0;
    }
}
```

### JPA-Compatible Value Objects (Classes)

Use classes with `@Embeddable` for value objects that need JPA persistence:

```java

@Getter
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Embeddable
public class MySampleCode {
    private String value;

    public static MySampleCode of(String value) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Code cannot be null or blank");
        }
        // Add format validation as needed
        return new MySampleCode(value);
    }

    @Override
    public String toString() {
        return value;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        MySampleCode that = (MySampleCode) o;
        return Objects.equals(value, that.value);
    }

    @Override
    public int hashCode() {
        return Objects.hash(value);
    }
}
```

## Requirements

### Factory Methods

- Always use static factory methods (`of()`, `create()`, `from()`)
- Never expose public constructors
- Validate all inputs in factory methods
- Use meaningful method names that reflect business intent

### Validation Rules

- Validate all constraints immediately upon construction
- Throw `IllegalArgumentException` for invalid values
- Provide clear, business-oriented error messages
- Validate format, range, and business rules

### Business Behavior

- Include relevant business methods
- Avoid getters that expose internal structure
- Provide conversion methods when needed
- Implement toString() for debugging

### Enum-Based Value Objects

```java
public enum MySampleTypeCode {
    TYPE_A("A"),
    TYPE_B("B");

    private final String code;

    MySampleTypeCode(String code) {
        this.code = code;
    }

    public String getCode() {
        return code;
    }

    public boolean isTypeA() {
        return this == TYPE_A;
    }

    public boolean isTypeB() {
        return this == TYPE_B;
    }
}
```
