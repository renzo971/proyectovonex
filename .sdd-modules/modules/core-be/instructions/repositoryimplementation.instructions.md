---
applyTo: "infrastructure/**/*RepositoryImpl.java"
---

> **Note:** Java package examples below use `com.acme.securities` as a fictional placeholder. Replace with your organization's package root before generating production code.

# Repository Implementation Guidelines

## Overview

Repository implementations provide the concrete persistence layer for domain aggregates. They bridge the domain and
infrastructure layers while maintaining clean architecture principles.

## Project Context

- Pattern: Repository Pattern using Panache

## Key Rules

### Design Principles

- Repository implementations belong in infrastructure layer
- Only aggregates have repository implementation
- Must implement application layer repository interfaces
- Must not leak infrastructure concerns to application layer
- Use CDI for dependency injection

### Package Organization

```
infrastructure/src/main/java/com/acme/securities/{project-name}/infrastructure/persistence/repository/
└── MySampleEntityRepositoryImpl.java                # Aggregate repository implementation
```

## Implementation Sample

```java
@RequiredArgsConstructor
public class MySampleEntityRepositoryImpl implements MySampleEntityRepository {
    private final EntityManager entityManager;

    @Override
    public Optional<MySampleEntity> findBySomeBusinessKey(MySampleEntityBusinessKey key) {
        return entityManager.createQuery(
            "SELECT e FROM MySampleEntity e WHERE e.businessKey = :key", MySampleEntity.class)
            .setParameter("key", key)
            .getResultStream().findFirst();
    }

    @Override
    public MySampleEntity save(MySampleEntity entity) {
        entityManager.persist(entity);
        return entity;
    }
}
```
