---
applyTo: "infrastructure/**/*Consumer.java"
---

> **Note:** Java package examples below use `com.acme.securities` as a fictional placeholder. Replace with your organization's package root before generating production code.

## ❓ Consumer Type Question

**Is this consumer for an Event or Command topic?**

- **YES**: Continue following this instruction file for Event/Command topic consumers
- **NO**: Please refer to [kafka-consumer-state-topic.instructions.md](kafka-consumer-state-topic.instructions.md) instead

---

# Kafka Consumer Implementation Guidelines

## Overview

Kafka consumers handle incoming messages from Kafka topics and delegate to appropriate message handlers. They implement
the event-driven integration layer.

## Project Context

- Package: `com.acme.securities.{project-name}.infrastructure.kafka`
- Framework: Quarkus with MicroProfile Reactive Messaging
- Pattern: Event-Driven Architecture with Message Dispatching
- Architecture: Clean Architecture with Infrastructure Layer Consumers

## Core Principles

- Single consumer per topic/channel pattern
- Messages are always processed by a Message Handler class

## Structure

```
infrastructure/src/main/java/com/acme/securities/{project-name}/infrastructure/kafka/
├── {TopicName}Consumer.java           # Main consumer class
├── MessageDispatcher.java             # Message routing interface
├── MessageHandler.java                # Generic handler interface
├── handler/
│   ├── {MessageType}MessageHandler.java   # Specific message handlers
│   └── ...
├── serializer/
│   ├── GenericJsonSchemaSerializer.java
│   └── GenericJsonSchemaSerializerImpl.java
└── message/                           # Message DTOs (if needed)
```

## Requirements

### Consumer Class

- Must be annotated with `@ApplicationScoped` for CDI lifecycle management
- Use `@Incoming` annotation with channel name for message consumption
- Use `@ActivateRequestContext` for CDI request scope activation
- Use `@SneakyThrows` for checked exception handling
- Implement comprehensive error handling with general Exception catching
- Use constructor injection with `@RequiredArgsConstructor`

### Message Processing

- Process `ConsumerRecord<Object, byte[]>` for raw Kafka records
- Delegate to `MessageDispatcher` for handler routing
- Each message type should has its own message handler implementation, the handler class must implement `MessageHandler`
  interface

### When using Schema Registry Integration

- Extract schema information from message payload
- Message classes are generated at compile time from the message schema versioned in the resource folders of the
  infrastructure module
- Deserialize messages using `KafkaJsonSchemaDeserializer`
- Use `SchemaRegistryClient` for schema retrieval
- Extract `javaType` from JSON schema for class determination
- Handle magic byte validation for message format verification
- Support dynamic class loading based on schema metadata

### Error Handling

- Catch all exceptions with general Exception handling and log them as ERROR level

### Configuration

- Inject channel configuration using `@ConfigProperty` with map binding
- Use configuration for deserializer setup
- Follow naming convention: `{topic-name}-consumer-channel`

## Implementation Patterns

### Consumer Class Template

```java
@ApplicationScoped
@Slf4j
public class CommandsConsumer {

    private final MessageDispatcher messageDispatcher;
    private final SchemaRegistryClient schemaRegistryClient;
    private final Map<String, String> configs;

    public CommandsConsumer(
        MessageDispatcher messageDispatcher,
        SchemaRegistryClient schemaRegistryClient,
        @ConfigProperty(name = "mp.messaging.incoming.{channel-name}") Map<String, String> configs) {
        this.messageDispatcher = messageDispatcher;
        this.schemaRegistryClient = schemaRegistryClient;
        this.configs = configs;
    }

    @Incoming("{channel-name}")
    @ActivateRequestContext
    @SneakyThrows
    public void consume(final ConsumerRecord<Object, byte[]> record) {
        try {
            var className = getClassName(record);
            var commandClass = Class.forName(className);

            var deserializer = new KafkaJsonSchemaDeserializer<>(
                schemaRegistryClient,
                configs,
                commandClass);

            var command = deserializer.deserialize(record.topic(), record.headers(), record.value());

            messageDispatcher.dispatch(record.key(), command, record.headers());

        } catch (Exception error) {
            log.error("Error processing message: {}", error.getMessage(), error);
        }
    }

    @SneakyThrows
    private String getClassName(ConsumerRecord<Object, byte[]> record) {
        var buffer = ByteBuffer.wrap(record.value());

        if (buffer.get() != 0) {
            throw new SerializationException("Unknown magic byte!");
        }

        var schema = (JsonSchema) schemaRegistryClient.getSchemaById(buffer.getInt());

        return schema.getString("javaType");
    }
}
```

### Message Handler Implementation

```java
@MessageHandlerComponent
@ApplicationScoped
@RequiredArgsConstructor
public class {MessageType}MessageHandler implements MessageHandler<Object, {MessageType}Command> {

    // message handler dependencies

    @Override
    public void handle(Object key, {MessageType}Command message, Headers headers) {
        // Implement message handling logic
    }
}
```

## Required Dependencies

- `org.apache.kafka:kafka-clients` - Kafka client library
- `io.confluent:kafka-json-schema-serializer` - Schema Registry JSON serialization
- `io.quarkus:quarkus-smallrye-reactive-messaging-kafka` - Quarkus Kafka integration
- `jakarta.enterprise:jakarta.enterprise.cdi-api` - CDI support
- `lombok` - Code generation annotations

## Configuration Properties

```properties
# Kafka Consumer Configuration
mp.messaging.incoming.{channel-name}.connector=smallrye-kafka
mp.messaging.incoming.{channel-name}.topic={topic-name}
mp.messaging.incoming.{channel-name}.bootstrap.servers=${kafka.bootstrap.servers}
mp.messaging.incoming.{channel-name}.group.id={consumer-group-id}
mp.messaging.incoming.{channel-name}.key.deserializer=org.apache.kafka.common.serialization.ByteArrayDeserializer
mp.messaging.incoming.{channel-name}.value.deserializer=org.apache.kafka.common.serialization.ByteArrayDeserializer
mp.messaging.incoming.{channel-name}.schema.registry.url=${schema.registry.url}
```

## Best Practices

- Use meaningful consumer class names ending with "Consumer"
- Implement proper logging for message processing lifecycle
- Use type-safe message handlers for each message type
- Implement idempotent message processing
