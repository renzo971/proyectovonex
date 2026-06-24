---
applyTo: "infrastructure/**/*DomainRepository.java"
---

> **Note:** Java package examples below use `com.acme.securities` as a fictional placeholder. Replace with your organization's package root before generating production code.

# Domain Repository Implementation Guidelines

## Rules

- Implements application layer repository interface
- Annotate with `@RequestScoped` and `@Named("{aggregateName}Repository")`
- Package: `com.acme.securities.{project-name}.infrastructure.persistence.repository.{aggregate}`
- Use `@RequiredArgsConstructor` for dependency injection
- Inject envelope repository
- Works with domain aggregates (not envelopes)

## Naming

- Pattern: `{Aggregate}DomainRepository`
- Examples: `InstructionRequestDomainRepository`, `AmendmentRequestDomainRepository`

## Structure

```java
@RequestScoped
@Named("{aggregateName}Repository")
@RequiredArgsConstructor
public class MyAggregateDomainRepository implements MyAggregateRepository {

    private final MyAggregateEnvelopeRepository envelopeRepository;

    @Override
    public Optional<MyAggregate> findById(final MyAggregateId id) {
        return envelopeRepository.findByIdOptional(id)
            .map(MyAggregateEnvelope::getAggregate);
    }

    @Override
    public MyAggregate save(final MyAggregate aggregate) {
        final var id = aggregate.getId();
        final var existing = envelopeRepository.findByIdOptional(id);

        MyAggregateEnvelope envelope;
        if (existing.isPresent()) {
            envelope = existing.get();
            envelope.updateData(aggregate);
            // Managed entity - changes auto-saved
        } else {
            envelope = new MyAggregateEnvelope(id, aggregate);
            envelopeRepository.persist(envelope);
        }

        return envelope.getAggregate();
    }

    @Override
    public void delete(final MyAggregate aggregate) {
        envelopeRepository.deleteById(aggregate.getId());
    }
}
```

## Key Patterns

### Find (Read)

```java
@Override
public Optional<MyAggregate> findById(final MyAggregateId id) {
    return envelopeRepository.findByIdOptional(id)
        .map(MyAggregateEnvelope::getAggregate);
}
```

### Find Multiple

```java
@Override
public List<MyAggregate> findByForeignKey(final ForeignKeyId foreignKeyId) {
    return envelopeRepository.findByForeignKey(foreignKeyId)
        .stream()
        .map(MyAggregateEnvelope::getAggregate)
        .toList();
}
```

### Save (Write)

```java
@Override
public MyAggregate save(final MyAggregate aggregate) {
    final var id = aggregate.getId();
    final var existing = envelopeRepository.findByIdOptional(id);

    MyAggregateEnvelope envelope;
    if (existing.isPresent()) {
        // Update - entity is managed, changes auto-saved
        envelope = existing.get();
        envelope.updateData(aggregate);
    } else {
        // Create - must explicitly persist
        envelope = new MyAggregateEnvelope(id, aggregate);
        envelopeRepository.persist(envelope);
    }

    return envelope.getAggregate();
}
```

### Delete

```java
@Override
public void delete(final MyAggregate aggregate) {
    envelopeRepository.deleteById(aggregate.getId());
}
```

## Implementation Example

```java
package com.acme.securities.settlement.api.infrastructure.persistence.repository.amendmentrequest;

import com.acme.securities.settlement.api.application.repository.InstructionAmendmentRequestRepository;
import com.acme.securities.settlement.api.domain.model.instructionamendmentrequest.AmendmentRequest;
import com.acme.securities.settlement.api.domain.model.instructionamendmentrequest.AmendmentRequestId;
import com.acme.securities.settlement.api.domain.model.instruction.InstructionId;

import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Named;
import lombok.RequiredArgsConstructor;

import java.util.List;
import java.util.Optional;

@RequestScoped
@Named("amendmentRequestRepository")
@RequiredArgsConstructor
public class AmendmentRequestDomainRepository 
    implements InstructionAmendmentRequestRepository {

    private final AmendmentRequestEnvelopeRepository envelopeRepository;

    @Override
    public Optional<AmendmentRequest> findById(final AmendmentRequestId id) {
        return envelopeRepository.findByIdOptional(id)
            .map(AmendmentRequestEnvelope::getAggregate);
    }

    @Override
    public List<AmendmentRequest> findByInstructionId(final InstructionId instructionId) {
        return envelopeRepository.findByInstructionId(instructionId)
            .stream()
            .map(AmendmentRequestEnvelope::getAggregate)
            .toList();
    }

    @Override
    public AmendmentRequest save(final AmendmentRequest aggregate) {
        final var id = aggregate.getId();
        final var existing = envelopeRepository.findByIdOptional(id);

        AmendmentRequestEnvelope envelope;
        if (existing.isPresent()) {
            envelope = existing.get();
            envelope.updateData(aggregate);
        } else {
            envelope = new AmendmentRequestEnvelope(id, aggregate);
            envelopeRepository.persist(envelope);
        }

        return envelope.getAggregate();
    }

    @Override
    public void delete(final AmendmentRequest amendmentRequest) {
        envelopeRepository.deleteById(amendmentRequest.getId());
    }
}
```

## Package Structure

```
infrastructure/src/main/java/com/acme/securities/{project-name}/infrastructure/persistence/repository/
└── {aggregate}/
    ├── {Aggregate}Envelope.java
    ├── {Aggregate}EnvelopeRepository.java
    └── {Aggregate}DomainRepository.java
```

## Anti-Patterns to Avoid

### Don't Expose Envelopes

```java
// ❌ WRONG
public MyAggregateEnvelope findEnvelopeById(MyAggregateId id) {
    return envelopeRepository.findById(id);
}

// ✅ CORRECT
public Optional<MyAggregate> findById(MyAggregateId id) {
    return envelopeRepository.findByIdOptional(id)
        .map(MyAggregateEnvelope::getAggregate);
}
```

### Don't Add Business Logic

```java
// ❌ WRONG
public void approveAggregate(MyAggregateId id) {
    var aggregate = findById(id).orElseThrow();
    aggregate.approve();
    save(aggregate);
}

// ✅ CORRECT - business logic belongs in use cases
```

### Don't Manually Manage Versions

```java
// ❌ WRONG
envelope.setVersion(envelope.getVersion() + 1);

// ✅ CORRECT
envelope.updateData(aggregate);
```

### Don't Call persist() on Managed Entities

```java
// ❌ WRONG
public MyAggregate save(MyAggregate aggregate) {
    var envelope = envelopeRepository.findById(id);
    envelope.updateData(aggregate);
    envelopeRepository.persist(envelope);  // Unnecessary
}

// ✅ CORRECT
public MyAggregate save(MyAggregate aggregate) {
    var envelope = envelopeRepository.findById(id);
    envelope.updateData(aggregate);
    // Changes auto-saved
}
```

## References

- [#file:repositoryinterface.instructions.md](repositoryinterface.instructions.md)
- [#file:enveloperepository.instructions.md](enveloperepository.instructions.md)
- [#file:envelope.instructions.md](envelope.instructions.md)
- [#file:aggregate.instructions.md](aggregate.instructions.md)

## Dependencies

```java
import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Named;
import lombok.RequiredArgsConstructor;
import java.util.Optional;
import java.util.List;
```
