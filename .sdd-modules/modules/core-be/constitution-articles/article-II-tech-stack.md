# Article II — Technology Stack

> **Module:** core-be
> **Purpose:** Merge this into your project's constitution Article II.

## Language & Runtime

- **Language**: Java 21 (LTS)
- **JDK**: Eclipse Temurin or Amazon Corretto 21
- **Syntax**: Use `var`, text blocks, pattern matching, records, sealed classes

## Framework

- **Application Framework**: Quarkus 3.x
- **CDI**: ArC (Quarkus CDI implementation)
- **REST**: RESTEasy Reactive with Jackson
- **Validation**: Hibernate Validator

## Build & Dependency Management

- **Build Tool**: Apache Maven 3.9+
- **Module Structure**: Multi-module Maven project (domain, application, infrastructure, test)
- **Code Generation**: openapi-generator-maven-plugin (JAX-RS interfaces from OpenAPI specs)

## Database

- **RDBMS**: PostgreSQL 15+
- **ORM**: Hibernate with Panache (Quarkus extension)
- **Migrations**: Liquibase (formatted SQL changesets)
- **Persistence Pattern**: Envelope Pattern (JSONB) or Direct JPA

## Messaging

- **Broker**: Apache Kafka (Confluent Platform)
- **Schema Registry**: Confluent Schema Registry (JSON Schema Draft-07)
- **POJO Generation**: jsonschema2pojo-maven-plugin v1.2.2
- **Consumer Framework**: Quarkus Messaging (SmallRye Reactive Messaging)

## Testing

- **Unit Testing**: JUnit 5 + AssertJ + Mockito
- **Test Data**: Instancio
- **BDD**: Cucumber 7.18.1 + PicoContainer
- **API Testing**: REST Assured 5.5.0
- **Container Testing**: Testcontainers 1.17.6
- **Integration**: Quarkus Test Framework

## DevOps

- **CI/CD**: GitLab CI
- **Containerization**: Docker (multi-stage build)
- **Local Dev**: Docker Compose (PostgreSQL, Kafka, Schema Registry, Kafka UI)
