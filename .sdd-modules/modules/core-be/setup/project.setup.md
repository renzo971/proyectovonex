---
mode: agent
description: Create a new standardized project setup file for GitHub repositories.
model: Claude Sonnet 4.5
tools: ['search', 'think', 'edit']
---

# Overview
The API Base Template is a production-ready for building microservices. It implements Domain-Driven Design (DDD) architecture with clean separation of concerns, multi-tenant support, and comprehensive DevOps tooling. This template eliminates the need to set up infrastructure, architecture patterns, and development workflows from scratch, allowing teams to focus immediately on implementing business logic. 

# Prerequisites
- Java Development Kit 21 or higher
- Maven 3.9 or higher
- Docker and Docker Compose
- Git
- Access to GitLab for repository hosting
- quarkus CLI (optional, for Quarkus-specific commands)

# Mandatory Inputs to Run the Setup

> 📋 **Please provide the following configuration values to set up your project**

---

### 🏷️ Project Information

**Project Name**
```
@input(projectName)
Example: order-api, user-core, payment-service
Description: The name of the new project
```

**Context**
```
@input(context)
Example: issuance, settlement, trading
Description: The business context or domain for the project
```

---

### ⚙️ Feature Configuration

**Include REST API**
```
@select(includeAPIRest)
Options: 
  ✓ true  - Include maven dependencies and code structure for REST API controllers
  ✗ false - Exclude REST API support
```

**Include Kafka Consumer**
```
@select(includeKafkaConsumer)
Options:
  ✓ true  - Include maven dependencies and code structure for Kafka consumers
  ✗ false - Exclude Kafka consumer support
```

**Include Kafka Producer**
```
@select(includeKafkaProducer)
Options:
  ✓ true  - Include maven dependencies and code structure for Kafka producers with transactional outbox pattern
            (includes outbox table, liquibase files, outbox publisher, and outbox job using quartz)
  ✗ false - Exclude Kafka producer support
```

**Include Database**
```
@select(includeDatabase)
Options:
  ✓ true  - Include maven dependencies and code structure for PostgreSQL database persistence with Liquibase
  ✗ false - Exclude database support
```

---


# Modules to Create
The template follows a layered DDD architecture with strict separation of concerns:

- Domain Layer: Contains pure business logic, entities, value objects, and domain events with no external dependencies
- Application Layer: Orchestrates domain objects through use cases and application services
- Infrastructure Layer: Implements technical concerns including REST controllers, database persistence, Kafka messaging, and external integrations
- Test Layer: Contains end-to-end tests for all layers with cucumber and JUnit

# Module Diagrams Dependency

```
┌───────────────────────────────────────────────────────────────┐
│  Infrastructure Layer                                         │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ REST Controllers │ DB Repositories │ Kafka Consumers    │  │
│  │ Mappers          │ External APIs   │ Configuration      │  │
│  └─────────────────────────────────────────────────────────┘  │
└───────────────────────────────┬───────────────────────────────┘
                                │ depends on
                                ↓
┌───────────────────────────────────────────────────────────────┐
│  Application Layer                                            │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ Use Cases        │ Command Handlers │ Query Handlers    │  │
│  │ Event Handlers   │ Application Services                 │  │
│  └─────────────────────────────────────────────────────────┘  │
└───────────────────────────────┬───────────────────────────────┘
                                │ depends on
                                ↓
┌────────────────────────────────────────────────────────────────┐
│  Domain Layer (No External Dependencies)                       │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Entities         │ Value Objects         │ Domain Events │  │
│  │ Aggregates       │ Repository Interfaces |               │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

**Dependency Flow:**
- **Infrastructure Layer** → depends on → **Application Layer** → depends on → **Domain Layer**
- **Domain Layer** has no external dependencies (pure business logic)

# Project Structure

The template follows a standard Maven-based Java project structure with clear separation between business logic, application orchestration, and technical infrastructure. The package naming convention is: `com.acme.securities.${context}.${projectName}.${module}`

## Pre Steps:
  - Replace the folder ${.mvn/} with the Maven Wrapper files present on path: /setup/.mvn/

```
${projectName}/
|── .mvn/                                 
|   └── wrapper/...                       # ${.mvn/}
├── .github/                              # Development & CI/CD Configuration
│   ├── instructions/                     # Pattern-specific development guidelines
│   │   ├── aggregate.instructions.md
│   │   ├── controller.instructions.md
│   │   ├── entity.instructions.md
│   │   ├── usecase.instructions.md
│   │   └── ... (other pattern guides)
│   │
│   ├── application/                      # Application Layer (Orchestration)
│   │   ├── src/main/java/com/acme/securities/${context}/${projectName}/application/
│   │   │   ├── ExecutionContext.java         # Execution context for use cases
│   │   │   ├── UseCase.java                  # Base use case interface
│   │   │   ├── UseCaseInput.java             # Input contract for use cases
│   │   │   └── UseCaseOutput.java            # Output contract for use cases
│   │   └── pom.xml
│   │
│   ├── domain/                           # Domain Layer (Business Logic)
│   │   ├── src/main/java/com/acme/securities/${context}/${projectName}/domain/
│   │   │   ├── OperationResult.java          # Result wrapper for operations
│   │   │   ├── OperationError.java           # Error handling for domain operations
│   │   │   ├── exception/                    # Domain exceptions
│   │   │   ├── model/                        # Aggregates and entities
│   │   │   └── valueobject/                  # Value objects (immutable)
│   │   └── pom.xml
│   │
│   ├── infrastructure/                   # Infrastructure Layer (Technical)
│   │   ├── src/main/
│   │   │   ├── java/com/acme/securities/${context}/${projectName}/infrastructure/
│   │   │   │   ├── config/                   # Application configuration
│   │   │   │   ├── kafka/                    # Kafka consumers/producers
│   │   │   │   ├── persistence/              # JPA repositories
│   │   │   │   └── web/                      # REST controllers
│   │   │   └── resources/
│   │   │       ├── application.yaml          # Application properties
│   │   │       ├── application-local.yaml    # Local environment config
│   │   │       └── db.changelog/             # Database migrations (Liquibase)
|   │   └───────── db.changelog-master.yaml    # Liquibase master changelog (ONLY if includeDatabase is true)
│   │   └── pom.xml
│   │
│   ├── test/                             # Test Layer (Integration Tests)
│   │   ├── src/test/
│   │   │   ├── java/com/acme/securities/${context}/${projectName}/test/
│   │   │   │   └── ...                   # Step definitions (Cucumber)
│   │   │   └── resources/features/       # Gherkin scenarios (BDD)
│   │   └── pom.xml
│   │
│   ├── annotation/                       # Custom annotations
│   │   ├── src/main/java/com/acme/securities/${context}/${projectName}/annotation/
│   │   │   └── ...                       # JSON Schema annotations
│   │   └── pom.xml
│   │
│   └── utils/                            # Utility scripts
│       └── sql/                          # Database initialization scripts
|        └── db_and_user.sql              # SQL script to create DB and user
│
├── gitlab-ci.yml                         # CI/CD pipeline configuration
├── docker-compose.yml                    # Local development stack (PostgreSQL, Kafka)
├── Dockerfile                            # Production container image
├── Makefile                              # Development commands
├── pom.xml                               # Root Maven configuration
└── README.md                             # Service documentation
```

## Key Directories

### `.github/`
Contains development guidelines and CI/CD configuration:
- **instructions/**: Pattern-specific coding guidelines for controllers, entities, use cases, etc.

### `application/`
Application layer implementing use case orchestration:
- Base interfaces for use cases with input/output contracts
- Execution context for cross-cutting concerns
- No business logic - only orchestration

### `domain/`
Core business logic with zero external dependencies:
- **model/**: Aggregates and entities containing business rules
- **valueobject/**: Immutable value objects
- **exception/**: Domain-specific exceptions
- **OperationResult/OperationError**: Standardized result handling

### `infrastructure/`
Technical implementations and external integrations:
- **config/**: Quarkus configuration classes
- **kafka/**: Message consumers and producers
- **persistence/**: JPA entities and repository implementations
- **web/**: REST API controllers with OpenAPI documentation
- **resources/**: Configuration files and database migrations

### `test/`
End-to-end integration tests using Cucumber BDD:
- **java/**: Step definitions implementing Gherkin scenarios
- **resources/features/**: Business-readable test scenarios

### `utils/`
Utility scripts for database setup:

#### Pre Steps:
  - Consider the input variable values provided to include this file only if includeDatabase is true.

- **sql/db_and_user.sql**: SQL script to create the necessary database and user for local development
- sql file:
```sql
-- Create the user  and password
CREATE USER ${projectName}_user WITH PASSWORD '${projectName}_pass';

-- Create the database
CREATE DATABASE ${projectName}_db;

-- Grant all privileges (read and write) on the database
GRANT ALL PRIVILEGES ON DATABASE ${projectName}_db TO ${projectName}_user;

-- Connect to the database
\c ${projectName}_db

-- Grant all privileges on the schema to the user
GRANT ALL PRIVILEGES ON SCHEMA public TO ${projectName}_user;

-- Ensure the user has access to new tables, sequences, and functions created in the schema in the future
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO ${projectName}_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO ${projectName}_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON FUNCTIONS TO ${projectName}_user;

-- Ensure ${projectName}_user has access to new tables, sequences, and functions created in the future
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO ${projectName}_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO ${projectName}_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON FUNCTIONS TO ${projectName}_user;

```

## Configuration Files

- **pom.xml**: Maven parent configuration with dependency management
- **docker-compose.yml**: Local development environment (PostgreSQL, Kafka, schema registry)
- **Dockerfile**: Multi-stage build for production deployment
- **Makefile**: Common development tasks (build, run, test, clean)
- **gitlab-ci.yml**: Automated pipeline for build, test, and deployment

### Docker Compose Services

#### Pre Steps:
  - Consider the input variable values provided to include respective services based on the flags for database and Kafka.

```yml
services:
  # (ONLY if includeDatabase is true)
  postgres:
    image: postgres
    container_name: postgres-ca4u-adapter
    restart: unless-stopped
    cap_drop:
      - NET_RAW
    security_opt:
      - no-new-privileges:true
    ports:
      - "5434:5432"
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
    volumes:
      - ./utils/sql/db_and_user.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - app-network

  # (ONLY if includeKafkaConsumer or includeKafkaProducer is true)
  kafka:
    image: confluentinc/cp-kafka:latest
    container_name: kafka
    hostname: kafka
    restart: unless-stopped
    ports:
      - "9092:9092"
      - "19092:19092"
    environment:
      # Modalità KRaft
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_NODE_ID: 1
      KAFKA_CONTROLLER_QUORUM_VOTERS: 1@kafka:9093

      # Listener (broker e controller)
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093,PLAINTEXT_HOST://0.0.0.0:19092
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092,PLAINTEXT_HOST://localhost:19092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      CLUSTER_ID: MkU3OEVBNTcwNTJENDM2Qk
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
    volumes:
      - kafka_data:/var/lib/kafka/data
    networks:
      - app-network

  # (ONLY if includeKafkaConsumer or includeKafkaProducer is true)
  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    ports:
      - "8090:8080"
    environment:
      KAFKA_CLUSTERS_0_NAME: local
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka:9092
      KAFKA_CLUSTERS_0_ZOOKEEPER: zookeeper:2181
    depends_on:
      - kafka
    networks:
      - app-network

  # (ONLY if includeKafkaConsumer or includeKafkaProducer is true)
  schema-registry:
    image: confluentinc/cp-schema-registry:latest
    #  image: 585254352285.dkr.ecr.eu-west-1.amazonaws.com/es/local-development/schema-registry:v7.8.0.confluentinc
    container_name: schema-registry
    hostname: schema-registry
    restart: unless-stopped
    ports:
      - "8081:8081"
    depends_on:
      - kafka
    environment:
      SCHEMA_REGISTRY_HOST_NAME: schema-registry
      SCHEMA_REGISTRY_LISTENERS: http://0.0.0.0:8081
      SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS: PLAINTEXT://kafka:9092
      SCHEMA_REGISTRY_DEBUG: 'true'
    networks:
      - app-network
      
# (ONLY if includeKafkaConsumer or includeKafkaProducer is true)
volumes:
  kafka_data:

networks:
  app-network:
    driver: bridge
```


## Modules POM Files

### If a version was not provided, use the latest stable version available at the time of writing.

### Pre Steps:
  - Consider the input variable values provided to include/exclude specific dependencies and code structure for REST API, Kafka, and Database.

### Main `pom.xml`
- Parent POM defining modules and dependency management
- groupId: com.acme.securities
- artifactId: ${projectName} 
- version: 1.0.0-SNAPSHOT
- Packaging: pom
- Create properties for versions of key dependencies
- Must include the following modules:
  - annotation
  - application
  - domain
  - infrastructure
  - test
- Must include the following dependency management sections
  - Quarkus Platform, version: 3.19.1
  - Quarkus BOM
  - openfga-sdk, version: 0.8.1
- Must include plugins: 
  - jandex-maven-plugin, version: 3.2.3
  - maven-surefire-plugin
  - jacoco-maven-plugin
  - quarkus-maven-plugin
  - sonar-maven-plugin, version: 3.11.0.3922

### Domain `pom.xml`
- Must to be created as Domain Module
- groupId: com.acme.securities
- artifactId: domain
- version: 1.0.0-SNAPSHOT
- Packaging: jar
- Must include dependencies:
  - jackson-databind, version: 2.15.2
  - lombok, version: 1.18.36
  - junit-jupiter
  - assertj-core, version: 3.22.0
  - com.github.f4b6a3:uuid-creator


### Application `pom.xml`
- Must to be created as Application Module
- groupId: com.acme.securities
- artifactId: application
- version: 1.0.0-SNAPSHOT
- Packaging: jar
- Must include dependencies:
  - domain module
  - lombok, version: 1.18.36
  - junit-jupiter
  - assertj-core, version: 3.22.0
  - mockito-core

### Infrastructure `pom.xml`
- Must to be created as Infrastructure Module
- groupId: com.acme.securities
- artifactId: infrastructure
- version: 1.0.0-SNAPSHOT
- Packaging: jar
- Must include dependencies:
    - quarkus-config-yaml
    - quarkus-arc
    - quarkus-smallrye-health
    - liquibase-core (ONLY if includeDatabase is true)
    - quarkus-liquibase (ONLY if includeDatabase is true)
    - org.postgresql:postgresql (ONLY if includeDatabase is true)
    - quarkus-jdbc-postgresql (ONLY if includeDatabase is true)
    - quarkus-hibernate-orm-panache (ONLY if includeDatabase is true)
    - quarkus-hibernate-validator (ONLY if includeDatabase is true)
    - quarkus-messaging-kafka (ONLY if includeKafkaConsumer or includeKafkaProducer is true)
    - quarkus-smallrye-fault-tolerance (ONLY if includeKafkaConsumer or includeKafkaProducer is true)
    - kafka-json-schema-serializer, version: 8.1.0 (ONLY if includeKafkaConsumer or includeKafkaProducer is true)
    - quarkus-resteasy-reactive-jackson (ONLY if includeAPIRest is true)

### Test `pom.xml`
- Must to be created as Test Module
- Must include dependencies:
  - kafka-json-schema-serializer, version: 8.1.0 (ONLY if includeKafkaConsumer or includeKafkaProducer is true)
  - cucumber-java, 7.18.1
  - cucumber-picocontainer, 7.18.1
  - cucumber-junit-platform-engine, 7.18.1
  - org:postgresql:postgresql, version: 42.6.0 (ONLY if includeDatabase is true)
  - junit-jupiter-engine, version: 5.10.0
  - assertj-core, version: 3.22.0
  - org.apache.kafka:kafka-clients




