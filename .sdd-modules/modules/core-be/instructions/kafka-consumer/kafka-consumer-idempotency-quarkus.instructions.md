---
applyTo: "infrastructure/**/*Consumer.java"
description: Quarkus CDI interceptor-based idempotency implementation for Kafka consumers
---

# Kafka Consumer Idempotency — Quarkus CDI Implementation

## Overview

This instruction provides the complete CDI interceptor-based idempotency implementation for Kafka consumers running on Quarkus. It uses a database-backed approach with a custom `@CheckIdempotency` annotation.

## Requirements

- Implement all files in module `infrastructure`
- Implement only 1 strategy (1 or 2) based on the user's answer about MessageHandler classes
- Create a CDI interceptor to handle idempotency checks
- Create the respective entity, repository, and processor classes
- Create the database migration script

## Pre-Implementation Check

Ask the user: **"Does your application have MessageHandler classes? (YES/NO)"**

- **YES** → Strategy 1 (apply annotation to `*Handler` classes)
- **NO** → Strategy 2 (apply annotation to `*AbstractConsumer` classes)

## Implementation Steps

### Step 1: Create `@CheckIdempotency` Annotation

**File**: `infrastructure/src/main/java/com/acme/{group}/{project-name}/infrastructure/interceptor/CheckIdempotency.java`

```java
@InterceptorBinding
@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
public @interface CheckIdempotency { }
```

### Step 2: Create `CheckIdempotencyInterceptor`

**File**: `infrastructure/src/main/java/com/acme/{group}/{project-name}/infrastructure/interceptor/CheckIdempotencyInterceptor.java`

```java
@Slf4j
@Interceptor
@CheckIdempotency
@RequiredArgsConstructor
public class CheckIdempotencyInterceptor {

    private final CheckIdempotencyProcessor checkIdempotencyProcessor;
    private final ObjectMapper objectMapper;

    @AroundInvoke
    public Object checkIdempotencyEvent(InvocationContext context) throws Exception {
        final var uuid = extractUuidFromParameters(context.getParameters());

        if (uuid == null) {
            log.warn("No UUID found in method parameters for duplicate check, proceeding");
            return context.proceed();
        }

        if (checkIdempotencyProcessor.isDuplicatedEvent(ProcessedEventId.of(uuid.toString()))) {
            log.warn("Duplicated event detected for UUID: {}, skipping", uuid);
            return null;
        }

        final var payload = objectMapper.writeValueAsString(context.getParameters());
        final var returningPoint = context.proceed();
        checkIdempotencyProcessor.updateProcessedEvent(ProcessedEvent.create(uuid, payload));
        
        return returningPoint;
    }

    private UUID extractUuidFromParameters(Object[] parameters) {
        // Extracts UUID from metadata.idempotenceKey via reflection
        for (final var parameter : parameters) {
            try {
                final var metadataMethod = parameter.getClass().getMethod("getMetadata");
                final var metadata = metadataMethod.invoke(parameter);
                if (Objects.nonNull(metadata)) {
                    final var idempotenceKeyMethod = metadata.getClass().getMethod("getIdempotenceKey");
                    final var idempotenceKey = idempotenceKeyMethod.invoke(metadata);
                    if (idempotenceKey instanceof UUID uuid) { return uuid; }
                }
            } catch (Exception e) {
                throw new IllegalArgumentException("Error extracting UUID from parameters", e);
            }
        }
        throw new IllegalArgumentException("No UUID or metadata.idempotenceKey found");
    }
}
```

### Step 3: Create ProcessedEvent Entity and Value Objects

- `ProcessedEventEntity` — JPA entity with Panache (`@Entity`, `@Table("processed_events")`)
- `ProcessedEvent` — Domain representation with factory method `create(UUID, String)`
- `ProcessedEventId` — Strongly typed ID wrapping String

### Step 4: Create `CheckIdempotencyProcessor`

Interface + implementation using `@ApplicationScoped` and `@Transactional`:
- `isDuplicatedEvent(ProcessedEventId)` — checks existence
- `updateProcessedEvent(ProcessedEvent)` — persists after processing

### Step 5: Create Repository

`ProcessedEventRepository` interface + `ProcessedEventRepositoryImpl` using Panache.

### Step 6: Database Migration

```sql
CREATE TABLE processed_events (
    idempotence_key VARCHAR(36) PRIMARY KEY,
    payload TEXT NOT NULL,
    processed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_processed_events_processed_at ON processed_events(processed_at);
```

## Strategy 1: Apply to MessageHandler Classes

```java
@ApplicationScoped
public class OrderEventHandler {
    @CheckIdempotency
    public void handle(OrderEvent event) {
        // Business logic — interceptor checks idempotency before execution
    }
}
```

## Strategy 2: Apply to AbstractConsumer Classes

```java
@ApplicationScoped
public abstract class AbstractKafkaConsumer<T> {
    @CheckIdempotency
    protected void consume(T event) {
        processEvent(event);
    }
    protected abstract void processEvent(T event);
}
```

## Important Considerations

- Event parameter **must** have `getMetadata()` → `getIdempotenceKey()` → `UUID`
- Implement a cleanup job to delete old idempotency keys (7–30 days retention)
- The `idempotence_key` column uses PRIMARY KEY constraint for duplicate prevention
