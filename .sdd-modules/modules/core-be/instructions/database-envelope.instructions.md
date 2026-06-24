---
applyTo: "infrastructure/**/*.sql"
description: Envelope Pattern JSONB storage and CQRS database patterns for PostgreSQL
---

# Envelope Pattern Database Guidelines

## Overview

The Envelope Pattern stores complex business objects as JSONB documents while maintaining relational structure for essential metadata. This approach supports CQRS with rich domain models.

## Project Context

- Database: PostgreSQL 15+
- Migration Tool: Liquibase with formatted SQL changesets
- Location: `infrastructure/src/main/resources/db.changelog/`

## Envelope Pattern Table Structure

```sql
CREATE TABLE {table_name}
(
    id             UUID                     NOT NULL,
    data           JSONB                    NOT NULL,
    version        BIGINT                   NOT NULL DEFAULT 1,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP WITH TIME ZONE,
    CONSTRAINT pk_{table_name} PRIMARY KEY (id)
);
```

### Required Columns

- **id**: UUID primary key, never nullable
- **data**: JSONB column for complete business object, never nullable
- **version**: BIGINT with DEFAULT 1 for optimistic locking
- **created_at**: TIMESTAMP WITH TIME ZONE, NOT NULL with DEFAULT CURRENT_TIMESTAMP
- **updated_at**: TIMESTAMP WITH TIME ZONE, nullable (updated on modifications)

## JSONB Indexing Strategy

### Foreign Key Indexes (JSONB Fields)

Foreign keys in envelope pattern are stored within JSONB columns. Create indexes for all foreign key fields:

```sql
CREATE INDEX idx_{table_name}_instruction_id ON {table_name} ((data->>'instructionId'));
CREATE INDEX idx_{table_name}_original_instruction_id ON {table_name} ((data->>'originalInstructionId'));
CREATE INDEX idx_{table_name}_parent_id ON {table_name} ((data->>'parentId'));

-- Nested foreign key indexes for complex relationships
CREATE INDEX idx_{table_name}_linked_instruction_id ON {table_name} ((data -> 'linkage'->>'instructionId'));
```

### Query-Specific Indexes (JSONB Functional)

```sql
-- Status field indexes
CREATE INDEX idx_{table_name}_status ON {table_name} ((data->>'status'));

-- ID reference indexes
CREATE INDEX idx_{table_name}_transaction_id ON {table_name} ((data->>'transactionId'));

-- Nested object indexes
CREATE INDEX idx_{table_name}_party_bic ON {table_name} ((data -> 'partyDetails' -> 'party'->>'bic'));

-- Date/timestamp indexes
CREATE INDEX idx_{table_name}_trade_date ON {table_name} ((data -> 'tradeDetails'->>'tradeDate'));

-- Financial indexes
CREATE INDEX idx_{table_name}_amount ON {table_name} ((data -> 'amount'->>'value'));
CREATE INDEX idx_{table_name}_currency ON {table_name} ((data -> 'amount'->>'currency'));
```

### Composite Indexes (Envelope)

```sql
CREATE INDEX idx_{table_name}_status_date ON {table_name} ((data->>'status'), created_at);
CREATE INDEX idx_{table_name}_instruction_status ON {table_name} (instruction_id, (data->>'status'));
```

### GIN Indexes

```sql
CREATE INDEX idx_{table_name}_data_gin ON {table_name} USING GIN (data);
```

## Liquibase Changeset Pattern (Envelope)

```sql
--liquibase formatted sql

--changeset {project-name}:create-{table-name}-table
CREATE TABLE {table_name}
(
    id             UUID                     NOT NULL,
    data           JSONB                    NOT NULL,
    version        BIGINT                   NOT NULL DEFAULT 1,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP WITH TIME ZONE,
    CONSTRAINT pk_{table_name} PRIMARY KEY (id)
);

--changeset {project-name}:create-{table-name}-indexes
CREATE INDEX idx_{table_name}_version ON {table_name} (version);
CREATE INDEX idx_{table_name}_created_at ON {table_name} (created_at);
CREATE INDEX idx_{table_name}_updated_at ON {table_name} (updated_at);

--changeset {project-name}:create-{table-name}-gin-index
CREATE INDEX idx_{table_name}_data_gin ON {table_name} USING GIN (data);

--changeset {project-name}:create-{table-name}-functional-indexes
CREATE INDEX idx_{table_name}_status ON {table_name} ((data->>'status'));
```

## Query Patterns

### Foreign Key Relationship Queries

```sql
-- Finding records by JSONB foreign key
SELECT * FROM {table_name} WHERE data->>'instructionId' = 'uuid-value';

-- Joining envelope tables
SELECT t1.*, t2.data 
FROM {table_name} t1 
JOIN instruction t2 ON t1.data->>'instructionId' = t2.id::text;
```

### Amendment/Cancellation Relationships

```sql
CREATE INDEX idx_{table_name}_original_instruction_id ON {table_name} ((data->>'originalInstructionId'));
SELECT * FROM amendment_request WHERE data->>'originalInstructionId' = 'instruction-uuid';
```

### Nested Foreign Key Relationships

```sql
CREATE INDEX idx_{table_name}_linkage_instruction_id ON {table_name} ((data -> 'linkage'->>'instructionId'));
SELECT * FROM {table_name} WHERE data -> 'linkage'->>'instructionId' = 'uuid-value';
```

## JSONB Query Operators

- Use `->` to get JSONB object: `data -> 'nested'`
- Use `->>` to get text value: `data->>'field'`
- Use `@>` for containment: `data @> '{"status":"ACTIVE"}'`
- Use `?` for key existence: `data ? 'optionalField'`
