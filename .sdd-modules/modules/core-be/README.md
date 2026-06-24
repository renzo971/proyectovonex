# Core-BE Module

> Domain-driven microservice patterns for Acme Securities Convergence platform.

## What This Module Provides

The `core-be` module extracts all domain-specific technical knowledge from the AI Framework into a portable, installable package for Enterprise SDD projects targeting the Convergence platform.

### Contents Summary

| Category | Count | Description |
|----------|:-----:|-------------|
| **Instructions** | 24 | Domain-specific coding patterns (aggregates, entities, envelopes, Kafka, mapping, testing, etc.) |
| **Guidances** | 1 | Kafka idempotency Quarkus implementation |
| **Setup Templates** | 2 | Project scaffolding + integration test setup |
| **Prompts** | 1 | Fix mapping issues troubleshooter |
| **Constitution Articles** | 3 | Tech stack, patterns, coding conventions |
| **Agent Patches** | 4 | Domain additions for Architect, API Champion, Messaging Champion, Test Explorer |
| **Copilot Supplement** | 1 | Java coding guidelines + checkstyle rules |

### Technology Stack

- **Language**: Java 21
- **Framework**: Quarkus 3.x
- **Messaging**: Kafka + Confluent Schema Registry
- **Database**: PostgreSQL 15+ (Envelope Pattern / Direct JPA)
- **Build**: Maven (multi-module)
- **Testing**: JUnit 5, Cucumber 7, REST Assured, Testcontainers

## Installation

```bash
sdd module install core-be
```

Or on PowerShell:
```powershell
.\sdd.ps1 module install core-be
```

This will:
1. Copy 24 instruction files to `.github/instructions/`
2. Copy 1 guidance file to `.github/guidances/`
3. Copy 2 setup templates to `.specify/templates/setup/`
4. Copy 1 prompt to `.github/prompts/`
5. Append Java coding guidelines to `.github/copilot-instructions.md`
6. Update `registry.json` with module metadata

### Post-Install Steps

1. **Run placeholder replacement**:
   ```powershell
   .\.sdd-modules\modules\core-be\setup-module.ps1
   ```
   This replaces `{project-name}`, `{gitlab-project-id}`, and `{tenant-domain}` in all module files.

2. **Review constitution articles** in `constitution-articles/` and merge relevant content into your project's `.specify/memory/constitution.md`.

3. **Review agent patches** in `agent-patches/` and merge domain-specific sections into your project's agent files.

## Removal

```bash
sdd module remove core-be
```

Removes all module-contributed files, cleans copilot-instructions markers, and updates the registry.

## Placeholders

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `{project-name}` | Your project name | `order-api` |
| `{gitlab-project-id}` | Numeric GitLab project ID | `12345` |
| `{tenant-domain}` | Multi-tenancy domain prefix | `cph` |

## Architecture Overview

```
Domain Layer (Pure Business)
├── Aggregates (AggregateRoot<T>)
├── Entities (identity + lifecycle)
├── Value Objects (immutable)
├── Info Objects (data snapshots)
├── State Machines (lifecycle enforcement)
└── Domain Events (immutable records)

Application Layer (Orchestration)
├── Use Cases (Input → Validate → Execute → Save)
├── Repository Interfaces
├── Gateway Interfaces
└── Event Handlers (same-transaction side effects)

Infrastructure Layer (Technical)
├── Envelopes (JSONB persistence wrappers)
├── Repository Implementations (Panache + Hibernate)
├── Controllers (OpenAPI generated interfaces)
├── Query Handlers (CQRS read side)
├── Kafka Consumers
└── Mappers (State, Command, Domain, Operation, Workflow)
```

## Module Contents

### Instructions (24 files)

The module currently includes 24 instruction files, including:
- domain modeling and DDD patterns (aggregate, entity, value object, domain event, state machine)
- persistence and repository patterns (envelope, repository interface/implementation)
- integration concerns (Kafka consumer patterns, idempotency, schema/POJO)
- implementation guidance (controller, mapper, testing, test data flow)

## Source

Extracted from the AI Framework corpus as part of Enterprise SDD Evolution §11.
