# Kafka Idempotency — Quarkus CDI Interceptor Implementation

## Description

Quarkus-specific implementation of Kafka consumer idempotency using a CDI interceptor pattern with database-backed deduplication. This is the recommended approach for Quarkus microservices using the at-least-once delivery semantic.

## When to Apply

- **Kafka Consumer Classes** (`infrastructure/**/*Consumer.java`) on Quarkus
- **Event Handlers** that update system state
- **Command Processors** executing operations from Kafka messages
- Any consumer where duplicate processing would cause data inconsistency

## Quarkus Configuration

Configure consumers with:
- Disable auto-commit to control offset commits after successful processing
- Set appropriate consumer group IDs
- Configure offset reset strategy (earliest/latest)

## Database-Based Idempotency (Recommended)

### Database Schema

```sql
CREATE TABLE processed_messages (
    idempotency_key VARCHAR(255) PRIMARY KEY,
    consumer_name VARCHAR(100) NOT NULL,
    message_payload TEXT,
    processed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_processed_messages_processed_at ON processed_messages(processed_at);
```

### Consumer Implementation — Idempotency Key from Headers

Extract the idempotency key from Kafka message headers (e.g., `idempotency-key` header). Before processing, check if the key exists in the idempotency repository. If it exists, acknowledge the message and skip processing. Otherwise, execute the business logic and save the idempotency key within the same transaction.

### Consumer Implementation — Idempotency Key from Payload

Extract the idempotency key from the event payload by combining multiple fields (e.g., `eventId:paymentId:operationType`). Check the idempotency repository before processing and save the key after successful execution within the same transaction.

### Idempotency Repository

Implement a repository with:
- `exists(idempotencyKey)` — Query the database to check if the key has been processed
- `save(idempotencyKey, consumerName, payload)` — Insert with key, consumer name, payload, and timestamp

### CDI Interceptor Approach

Use the `@CheckIdempotency` CDI interceptor annotation (see `kafka-consumer-idempotency-quarkus.instructions.md`) for a declarative approach:

1. Annotate consumer/handler methods with `@CheckIdempotency`
2. The interceptor extracts the idempotency key from `metadata.idempotenceKey`
3. Checks the database for existing entries
4. Skips execution if duplicate, records entry if new

### Cleanup Job

**Required**: Implement a scheduled cleanup job to delete old idempotency records.
- Retention period: 7–30 days (match your Kafka retention policy)
- Without cleanup, the table grows indefinitely, degrading query performance
- Use Quarkus `@Scheduled` annotation for periodic cleanup

## Exactly-Once Semantics (Alternative)

For Kafka-to-Kafka workflows only:
- Enable idempotent producer: `enable.idempotence=true`
- Set `acks=all` and configure transactional ID
- Consumer `isolation.level=read_committed`

**Limitations**: Only works for Kafka-to-Kafka flows, 30–50% throughput reduction, complex operational requirements.

**Recommendation**: Use database-based idempotency for most business applications.
