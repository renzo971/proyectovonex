---
applyTo: "infrastructure/**/*Consumer.java"
---

> **Note:** Java package examples below use `com.acme.securities` as a fictional placeholder. Replace with your organization's package root before generating production code.

## ❓ Consumer Type Question

**Is this consumer for a State topic?**

- **YES**: Continue following this instruction file for State topic consumers
- **NO**: Please refer to [kafka-consumer-command-event-topic.instructions.md](kafka-consumer-command-event-topic.instructions.md) instead

---

# Kafka Consumer Implementation Guidelines

## Overview

Kafka consumers handle incoming messages from Kafka topics using Quarkus native Kafka integration with custom 
deserializers. They implement the event-driven integration layer following Clean Architecture principles.

## Project Context

- Package: `com.acme.securities.issuance.ca4u.adapter.infrastructure.consumer.kafka`
- Framework: Quarkus with MicroProfile Reactive Messaging
- Pattern: Event-Driven Architecture with Template Method Pattern
- Architecture: Clean Architecture with Infrastructure Layer Consumers
- Deserialization: Custom deserializers extending `ObjectMapperDeserializer`

## Core Principles

- Single consumer per topic/channel pattern
- Use `AbstractConsumer<Schema, Domain>` as base class for all consumers
- Messages are deserialized using custom deserializers
- Domain mapping is delegated to dedicated mapper classes
- Use case execution is abstracted in template method pattern

## Structure

```
infrastructure/src/main/java/com/acme/securities/issuance/ca4u/adapter/infrastructure/consumer/kafka/
├── AbstractConsumer.java              # Base consumer with template method
├── {MessageType}Consumer.java         # Concrete consumer implementations
├── deserializer/
│   └── {MessageType}Deserializer.java # Custom deserializers
└── mapper/
    ├── SchemaMapper.java              # Mapper interface
    └── {MessageType}Mapper.java       # Concrete mappers
```

## Requirements

### Consumer Class

- Must extend `AbstractConsumer<Schema, Domain>` where:
  - `Schema`: The Kafka message schema type (e.g., `SecurityState`, `SecurityCodingState`)
  - `Domain`: The domain object type (e.g., `Security`, `Instrument`)
- Must be annotated with `@ApplicationScoped` for CDI lifecycle management
- Use `@Incoming` annotation with channel name for message consumption
- Use `@Retry` with appropriate configuration for retry logic
- Use `@Transactional` for transaction management
- Use constructor injection with `@RequiredArgsConstructor`
- Override `consume(Schema message)` method to process incoming messages
- Always call `super.consume(message)` to trigger template method processing
- Implement `getMapper()` to return the appropriate `SchemaMapper` instance
- Implement `executeUseCase(Domain domain)` to call the appropriate use case

### Deserializer Class

- Must extend `ObjectMapperDeserializer<MessageType>`
- Located in `infrastructure.consumer.kafka.deserializer` package
- Constructor must call `super(MessageType.class)`
- Naming convention: `{MessageType}Deserializer`

### Mapper Class

- Must implement `SchemaMapper<Schema, Domain>` interface
- Located in `infrastructure.consumer.kafka.mapper` package
- Implement `toDomain(Schema schema)` method for schema-to-domain conversion
- Use `@Component` or `@ApplicationScoped` for CDI management

### Message Processing Flow

1. Kafka delivers message to consumer
2. Message is deserialized using custom deserializer
3. Consumer calls `super.consume(message)` which triggers `handleMessage()`
4. `handleMessage()` is intercepted by `@CheckDuplicatedEvent` for deduplication
5. Mapper converts schema to domain object
6. Use case is executed with domain object

### Error Handling

- Use `@Retry` annotation with configurable max retries and delay
- Configure Dead Letter Queue (DLQ) for failed messages in application.yml
- Log processing steps at appropriate levels (INFO for start, ERROR for failures)
- Transaction rollback is automatic on exceptions due to `@Transactional`

## Implementation Patterns

### Abstract Consumer Base Class

```java
@Slf4j
public abstract class AbstractConsumer<Schema, Domain> {

    /**
     * This method should be overridden by subclasses to consume messages from Kafka topics and
     * annotated with @Incoming to define the channel and @Retry to handle retries.
     * <p>
     * Always call it super.consume(message) when overriding to ensure proper processing.
     */
    public void consume(Schema message) {
        handleMessage(message);
    }

    @CheckDuplicatedEvent
    protected void handleMessage(Schema message) {
        var domainObject = getMapper().toDomain(message);
        executeUseCase(domainObject);
    }

    protected abstract SchemaMapper<Schema, Domain> getMapper();

    protected abstract void executeUseCase(Domain domain);
}
```

### Concrete Consumer Implementation

```java
@ApplicationScoped
@RequiredArgsConstructor
@Slf4j
public class SecurityStateConsumer extends AbstractConsumer<SecurityState, Security> {

    private final ProcessSecurityUpdateUseCase processSecurityUpdateUseCase;
    private final SecurityStateMapper securityStateMapper;

    @Incoming("securities-state-consumer-channel")
    @Retry(
            maxRetries = 5,
            delay = 10,
            delayUnit = ChronoUnit.SECONDS
    )
    @Transactional
    public void consume(final SecurityState securityState) {
        log.info("Processing SecurityState message with ID: {}", securityState.getId());
        super.consume(securityState);
    }

    @Override
    protected SchemaMapper<SecurityState, Security> getMapper() {
        return securityStateMapper;
    }

    @Override
    protected void executeUseCase(Security security) {
        var input = new ProcessSecurityUpdateInput(security);
        processSecurityUpdateUseCase.execute(input, new ExecutionContext());
    }
}
```

### Deserializer Implementation

```java
package com.acme.securities.issuance.ca4u.adapter.infrastructure.consumer.kafka.deserializer;

import com.acme.securities.issuance.security.state.SecurityState;
import io.quarkus.kafka.client.serialization.ObjectMapperDeserializer;

public class SecurityStateDeserializer extends ObjectMapperDeserializer<SecurityState> {

    public SecurityStateDeserializer() {
        super(SecurityState.class);
    }
}
```

### Mapper Implementation

```java
@Component
@RequiredArgsConstructor
public class SecurityStateMapper implements SchemaMapper<SecurityState, Security> {

    @Override
    public Security toDomain(SecurityState schema) {
        // Mapping logic from schema to domain
        return Security.builder()
            .id(schema.getId())
            // ... other fields
            .build();
    }
}
```

## Required Dependencies

- `org.apache.kafka:kafka-clients` - Kafka client library
- `io.quarkus:quarkus-smallrye-reactive-messaging-kafka` - Quarkus Kafka integration
- `io.quarkus:quarkus-kafka-client` - Quarkus Kafka client with ObjectMapperDeserializer
- `jakarta.enterprise:jakarta.enterprise.cdi-api` - CDI support
- `org.eclipse.microprofile.reactive-messaging:microprofile-reactive-messaging-api` - Reactive Messaging API
- `org.eclipse.microprofile.faulttolerance:microprofile-fault-tolerance-api` - Fault Tolerance for @Retry
- `lombok` - Code generation annotations

## Configuration Properties

### Basic Kafka Consumer Configuration

```yaml
kafka:
  bootstrap:
    servers: ${KAFKA_BOOTSTRAP_SERVERS:localhost:19092}
  schema:
    registry:
      url: ${SCHEMA_REGISTRY_URL:http://localhost:8081}

mp:
  messaging:
    incoming:
      {channel-name}:
        topic: {topic-name}
        connector: smallrye-kafka
        bootstrap:
          servers: ${KAFKA_BOOTSTRAP_SERVERS:localhost:19092}
        group:
          id: {consumer-group-id}
        auto:
          offset:
            reset: earliest
        enable:
          auto:
            commit: false
        key:
          deserializer: org.apache.kafka.common.serialization.StringDeserializer
        value:
          deserializer: com.acme.securities.issuance.ca4u.adapter.infrastructure.consumer.kafka.deserializer.{MessageType}Deserializer
        schema:
          registry:
            url: ${SCHEMA_REGISTRY_URL:http://localhost:8081}
        # Failure strategy with DLQ
        failure-strategy: dead-letter-queue
        dead-letter-queue:
          topic: {topic-name}-dlq
          key:
            serializer: org.apache.kafka.common.serialization.StringSerializer
          value:
            serializer: io.quarkus.kafka.client.serialization.ObjectMapperSerializer
```

### Example: Security State Consumer

```yaml
mp:
  messaging:
    incoming:
      securities-state-consumer-channel:
        topic: issuance-securities-state
        connector: smallrye-kafka
        bootstrap:
          servers: ${KAFKA_BOOTSTRAP_SERVERS:localhost:19092}
        group:
          id: issuance-ca4u-adapter-security-state-consumer
        auto:
          offset:
            reset: earliest
        key:
          deserializer: org.apache.kafka.common.serialization.StringDeserializer
        value:
          deserializer: com.acme.securities.issuance.ca4u.adapter.infrastructure.consumer.kafka.deserializer.SecurityStateDeserializer
        schema:
          registry:
            url: ${SCHEMA_REGISTRY_URL:http://localhost:8081}
        enable:
          auto:
            commit: false
        failure-strategy: dead-letter-queue
        dead-letter-queue:
          topic: issuance-securities-state-dlq
```

## Best Practices

- Use meaningful consumer class names ending with "Consumer"
- Implement proper logging for message processing lifecycle
- Use type-safe message handlers for each message type
- Implement idempotent message processing using `@CheckDuplicatedEvent`
- Always extend `AbstractConsumer` to ensure consistent processing pattern
- Use dedicated mapper classes for schema-to-domain conversion
- Configure Dead Letter Queue for failed message handling
- Use `@Transactional` to ensure database consistency
- Configure appropriate retry strategies based on business requirements
- Keep consumer logic thin - delegate to use cases
- One consumer per topic/channel for better maintainability
- Use constructor injection for better testability

## Naming Conventions

- Consumer class: `{MessageType}Consumer.java`
- Deserializer class: `{MessageType}Deserializer.java`
- Mapper class: `{MessageType}Mapper.java`
- Channel name: `{topic-name}-consumer-channel`
- Consumer group ID: `{application-name}-{topic-name}-consumer`
- DLQ topic: `{topic-name}-dlq`
