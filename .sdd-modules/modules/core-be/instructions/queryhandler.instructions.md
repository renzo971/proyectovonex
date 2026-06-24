---
applyTo: "infrastructure/**/*QueryHandler.java"
---

> **Note:** Java package examples below use `com.acme.securities` as a fictional placeholder. Replace with your organization's package root before generating production code.

# Query Handler Implementation Guidelines

## Overview

Query handlers implement the API exposed read operations. They handle queries that retrieve data without modifying state.

## Project Context

- Architecture: Query handlers and interfaces exist only in infrastructure layer
- Project Package: `com.acme.securities.{project-name}.infrastructure.persistence.queryhandler`
- Validation: Jakarta Bean Validation with `@Valid` annotation on requests

## Core Principles

- **No side effects**: Query handlers must not modify any state or data
- **Separate interface and implementation**: Each Query Handler has an interface and a separate implementation class
- **One Query Handler per Endpoint**: Each read endpoint should have its own dedicated Query Handler
- **No Reuse**: Query Handlers should never be reused across different endpoints
- **Infrastructure Layer Only**: Query handlers, interfaces, and all related classes exist only in the infrastructure layer
- **Direct HTTP Mapping**: Request and Response objects should match HTTP DTOs to avoid unnecessary mapping
- **ExecutionContext Access**: Query handlers have direct access to ExecutionContext (no mapper needed)
- **Domain Exception Handling**: Use domain-specific exceptions and OperationResult for validations
- **Pagination Support**: Always include total count for list queries that support pagination
- **Parameter Binding**: Always use parameter binding to prevent SQL injection

### Instantiation and Proxies

Query handlers are instantiated through the `QueryHandlerFactory` which provides:

- Authorization validation via `QueryHandlerAuthorizationProxy`
- Request validation via `QueryHandlerValidationProxy`
- CDI injection and dependency management


## Structure

```
infrastructure/src/main/java/com/acme/securities/{project-name}/infrastructure/persistence/queryhandler/
├── example/
│   ├── getall/
│   │   ├── GetAllExamplesQueryHandler.java           # Interface
│   │   ├── GetAllExamplesQueryHandlerImpl.java       # Manual implementation
│   │   ├── GetAllExamplesRequest.java                # Request DTO (record)
│   │   └── GetAllExamplesResponse.java               # Response DTO (record)
│   ├── getbyid/
│   │   ├── GetSingleExampleQueryHandler.java         # Interface
│   │   ├── GetSingleExampleQueryHandlerImpl.java     # Manual implementation
│   │   ├── GetExampleRequest.java                    # Request DTO (record)
│   │   └── GetExampleResponse.java                   # Response DTO (record)
│   └── search/
│       ├── SearchExamplesQueryHandler.java           # Interface
│       ├── SearchExamplesQueryHandlerImpl.java       # Dynamic implementation
│       ├── SearchExamplesRequest.java                # Request DTO (record)
│       └── SearchExamplesResponse.java               # Response DTO (record)
├── SingleResultQueryHandler.java                     # Base interface for single result queries
├── ListResultQueryHandler.java                       # Base interface for list result queries
├── QueryHandler.java                                 # Base interface
├── QueryHandlerFactory.java                          # Factory interface
├── QueryHandlerFactoryImpl.java                      # CDI factory implementation
```

## Types of Query Handlers

### Decision Criteria (Envelope Pattern)

**When to use SingleResultQueryHandler:**
- Returning a single, **flat object** that can be easily mapped to Java class
- Simple object structure without deep nesting
- Example: Get single entity by ID with basic fields

**When to use ListResultQueryHandler:**
- Returning collections of **flat objects** mapped to Java classes
- Need pagination support with total count
- Each item in list is simple and maps cleanly to Java object
- Example: List of entities with filtering and pagination

**When to use Raw Response:**
- Database constructs **complex JSON graphs** with nesting
- **Non-flat objects** where SQL builds complete JSON structure
- Avoid object mapping overhead for pre-formatted JSON
- Complex aggregations better handled in database
- Example: Entity with nested children, complex relationships built in SQL

### 1. SingleResultQueryHandler

Use this for queries that return exactly one object.

Generic Parameters: SingleResultQueryHandler<TRequest, TResponse>

- TRequest: The request object (HTTP request DTO)
- TResponse: The response object (HTTP response DTO)

Example:

```java
// GetExampleQueryHandler.java
public interface GetExampleQueryHandler
        extends SingleResultQueryHandler<GetExampleRequest, GetExampleResponse> {
}

// GetExampleRequest.java
public record GetExampleRequest(
        UUID id
) {
}

// GetExampleResponse.java
public record GetExampleResponse(
        UUID id,
        OffsetDateTime createdAt,
        String requestNumber,
        String transactionId,
        UUID createdBy,
        String status,
        MovementTypeEnum movementType,
        String tradeDetails,
        String financialInstrumentDetails
) {
}

// GetExampleQueryHandlerImpl.java
@ApplicationScoped
@RequiredArgsConstructor
public class GetExampleQueryHandlerImpl implements GetExampleQueryHandler {

    private final EntityManager entityManager;

    @Override
    public GetExampleResponse execute(GetExampleRequest request, ExecutionContext context) {
        var sql = """
            SELECT
                ex.id,
                ex.created_at,
                ex.data->>'requestNumber',
                ex.data->>'transactionId',
                CAST(ex.data->>'createdBy' AS UUID),
                ex.data->>'status',
                ex.data->>'movementType',
                ex.data->>'tradeDetails',
                ex.data->>'financialInstrumentDetails'
            FROM example_envelope ex
            WHERE ex.id = :id
            """;

        var query = entityManager.createNativeQuery(sql);
        query.setParameter("id", request.id());

        try {
            var result = (Object[]) query.getSingleResult();

            return new GetExampleResponse(
                (UUID) result[0],           // id
                convertToOffsetDateTime(result[1]), // created_at
                (String) result[2],         // request_number
                (String) result[3],         // transaction_id
                (UUID) result[4],           // author_user_id
                (String) result[5],         // status
                convertToMovementType((String) result[6]), // movement_type
                (String) result[7],         // trade_details
                (String) result[8]          // financial_instrument_details
            );
        } catch (NoResultException e) {
            throw new ExampleNotFoundException(request.id());
        }
    }

    /**
     * Converts a timestamp object to OffsetDateTime, handling multiple possible types from the database.
     */
    private OffsetDateTime convertToOffsetDateTime(Object timestampValue) {
        if (timestampValue == null) {
            return null;
        }

        if (timestampValue instanceof java.sql.Timestamp timestamp) {
            return timestamp.toInstant().atOffset(ZoneOffset.UTC);
        } else if (timestampValue instanceof Instant instant) {
            return instant.atOffset(ZoneOffset.UTC);
        } else if (timestampValue instanceof OffsetDateTime offsetDateTime) {
            return offsetDateTime;
        } else if (timestampValue instanceof LocalDateTime localDateTime) {
            return localDateTime.atOffset(ZoneOffset.UTC);
        } else {
            throw new IllegalArgumentException(
                "Unsupported timestamp type: " + timestampValue.getClass().getName() +
                    " with value: " + timestampValue
            );
        }
    }

    /**
     * Converts a string value to MovementType enum, handling null values safely.
     */
    private MovementTypeEnum convertToMovementType(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        try {
            return MovementTypeEnum.fromValue(value);
        } catch (IllegalArgumentException e) {
            // Log warning and return null for unknown values
            return null;
        }
    }
}
```

### 2. ListResultQueryHandler

Use this for queries that return collections of data, typically with pagination support.

Generic Parameters: ListResultQueryHandler<TRequest, TResponse, TList>

- TRequest: The request object (HTTP request DTO)
- TResponse: The response object (HTTP response DTO)
- TList: The list item type (individual item within the response collection)

Key Features:

- Returns a collection wrapper
- Includes COUNT(*) OVER() AS total for pagination
- Response contains a list of items
- Support pagination through total count and offset/limit parameters

Example:

```java
@ApplicationScoped
@RequiredArgsConstructor
public class GetAllExamplesQueryHandlerImpl implements GetAllExamplesQueryHandler {

    private final EntityManager entityManager;

    @Override
    public GetAllExamplesResponse execute(GetAllExamplesRequest request, ExecutionContext context) {
        var sql = """
            SELECT
                ex.id,
                ex.created_at,
                ex.data->>'requestNumber',
                ex.data->>'status',
                ex.data->>'movementType',
                COUNT(*) OVER() AS total
            FROM example_envelope ex
            WHERE 1=1
            LIMIT :limit OFFSET :offset
            """;

        var query = entityManager.createNativeQuery(sql);
        query.setParameter("limit", request.limit());
        query.setParameter("offset", request.offset());

        var results = query.getResultList();
        var items = mapResults(results);

        return new GetAllExamplesResponse(items);
    }

    private List<GetAllExamplesResponse.Item> mapResults(List<Object[]> results) {
        return results.stream()
                .map(row -> new GetAllExamplesResponse.Item(
                        (UUID) row[0],           // id
                        convertToOffsetDateTime(row[1]), // created_at
                        (String) row[2],         // request_number
                        (String) row[3],         // status
                        convertToMovementType((String) row[4]), // movement_type
                        (Long) row[5]            // total
                ))
                .toList();
    }

    // Include same helper methods as SingleResultQueryHandler
}

// Request object
@Valid
public record GetAllExamplesRequest(
        @Min(1) @Max(100) int limit,
        @Min(0) int offset
) {
}

// Response contains a list of items
public record GetAllExamplesResponse(List<Item> items) {
    public record Item(
            UUID id,
            OffsetDateTime createdAt,
            String requestNumber,
            String status,
            MovementTypeEnum movementType,
            @JsonIgnore long total  // Used for pagination
    ) {
    }
}
```

### 3. Raw Response Query Handler

Use this for queries that return raw JSON data directly from the database without object mapping or serialization. This pattern is ideal when the database query constructs JSON data that should be returned directly to the client.

Key Features:

- Returns raw JSON string from database
- No object mapping or serialization overhead
- Ideal for complex JSON aggregations or pre-formatted data
- Direct database-to-HTTP response pathway
- Instead of doing database JOINS and grouping in Java, leverage database functions to build the response JSON structure

When to use Raw Response Query Handler:

- Database stores JSON data that should be returned as-is
- Performance-critical queries where object mapping overhead should be avoided

Example:

```java
// GetExampleStateTransitionsQueryHandler.java - No base interface
@ApplicationScoped
@RequiredArgsConstructor
public class GetExampleStateTransitionsQueryHandler {

    private final EntityManager entityManager;

    /**
     * Handles the query execution and returns raw JSON response.
     * Uses custom handle() method for raw response pattern.
     */
    public GetExampleStateTransitionsResponse execute(
        final GetExampleStateTransitionsRequest request) {

        var validation = OperationResult.success();

        if (request.getEntityId() == null) {
            validation.addError(
                "The field '{fieldName}' is required",
                Map.of("fieldName", "entityId")
            );
        }

        if (request.getRequestId() == null) {
            validation.addError(
                "The field '{fieldName}' is required",
                Map.of("fieldName", "requestId")
            );
        }

        validation.throwIfError();

        // Query returns JSON directly from database
        final String query = """
            SELECT data->>'stateTransitions' as state_transitions 
            FROM example_entity 
            WHERE data->'entity_id' = :entityId AND id = :id
            """;

        try {
            final var result = entityManager.createNativeQuery(query)
                .setParameter("entityId", request.getEntityId())
                .setParameter("id", request.getId())
                .getSingleResult();

            return GetHoldReleaseRequestStateTransitionsResponse.builder()
                .stateTransitions((String) result)
                .build();

        } catch (NoResultException e) {
            throw new NotFoundException(
                "No entity found with the entityId {entityId} and id {id}"
                Map.of(
                    "entityId", request.getEntityId(),
                    "id", request.getId()
                      ));
        }
    }
}

// GetExampleStateTransitionsRequest.java
import com.fasterxml.jackson.annotation.JsonRawValue;
import lombok.Builder;

@Value
@Builder
public class GetExampleStateTransitionsRequest {
    UUID entityId;
    ExampleRequestId requestId;
}

// GetExampleStateTransitionsResponse.java
import com.fasterxml.jackson.annotation.JsonRawValue;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class GetExampleStateTransitionsResponse {
    @JsonRawValue
    String stateTransitions;  // Raw JSON string from database
}
```

#### Controller Integration for Raw Response

```java
@Override
public Response getExampleStateTransitions(UUID entityId, UUID requestId, String workflowCode) {
    // Create the query handler for state transitions
    var queryHandler = queryHandlerFactory.create(GetExampleStateTransitionsQueryHandler.class);

    // Build the request object
    var request = GetExampleStateTransitionsRequest
        .builder()
        .entityId(entityId)
        .requestId(ExampleRequestId.of(requestId))
        .build();

    // Call the handler and get the raw JSON response
    var response = queryHandler.handle(request);

    // Return the raw JSON response directly - no additional serialization
    return Response.ok(response).build();
}
```

## Dynamic Queries

For complex queries with multiple optional filters and sorting options, build the SQL dynamically based on request parameters. This approach could be used with List Result Query Handlers and Raw Response Query Handlers.

Example:

```java

@RequiredArgsConstructor
public class SearchExamplesQueryHandler implements ListResultQueryHandler<SearchExamplesRequest, SearchExamplesResponse, SearchExamplesResponse.Item> {

    private final EntityManager entityManager;

    @Override
    public SearchExamplesResponse execute(SearchExamplesRequest request, ExecutionContext context) {
        var sql = new StringBuilder("""
                SELECT 
                    p.id,
                    p.client_id,
                    p.party_bic,
                    p.short_name,
                    p.long_name,
                    p.status,
                    COUNT(*) OVER() AS total
                FROM party p
                WHERE 1=1
                """);

        var query = buildDynamicQuery(sql, request);

        // Execute query and map results
        var results = query.getResultList();
        var items = mapResults(results);

        return new SearchExamplesResponse(items);
    }

    private Query buildDynamicQuery(StringBuilder sql, SearchExamplesRequest request) {
        // Build base query with all possible conditions
        var conditions = new ArrayList<String>();
        var parameters = new HashMap<String, Object>();

        // Dynamic WHERE conditions - combine query building and parameter binding
        if (request.clientId() != null) {
            conditions.add("p.client_id = :clientId");
            parameters.put("clientId", request.clientId());
        }
        if (request.status() != null) {
            conditions.add("p.status = :status");
            parameters.put("status", request.status());
        }
        if (request.searchTerm() != null) {
            conditions.add("(p.short_name ILIKE :searchTerm OR p.long_name ILIKE :searchTerm)");
            parameters.put("searchTerm", "%" + request.searchTerm() + "%");
        }

        // Append conditions to query
        if (!conditions.isEmpty()) {
            sql.append(" AND ").append(String.join(" AND ", conditions));
        }

        // Dynamic ORDER BY
        if (request.sortBy() != null) {
            sql.append(" ORDER BY ").append(request.sortBy());
            if (request.sortDirection() != null) {
                sql.append(" ").append(request.sortDirection());
            }
        }

        // Pagination
        sql.append(" LIMIT :limit OFFSET :offset");

        // Create query and bind all parameters
        var query = entityManager.createNativeQuery(sql.toString());
        parameters.forEach(query::setParameter);
        query.setParameter("limit", request.limit());
        query.setParameter("offset", request.offset());

        return query;
    }

    private List<SearchExamplesResponse.Item> mapResults(List<Object[]> results) {
        return results.stream()
                .map(row -> new SearchExamplesResponse.Item(
                        (UUID) row[0],           // id
                        (Long) row[1],           // client_id
                        (String) row[2],         // party_bic
                        (String) row[3],         // short_name
                        (String) row[4],         // long_name
                        (String) row[5],         // status
                        (Long) row[6]            // total
                ))
                .toList();
    }
}

// Request with dynamic parameters
public record SearchExamplesRequest(
        Long clientId,
        String status,
        String searchTerm,
        String sortBy,
        String sortDirection,
        int limit,
        int offset
) {
}

// Response structure
public record SearchExamplesResponse(List<Item> items) {
    public record Item(
            UUID id,
            long clientId,
            String partyBic,
            String shortName,
            String longName,
            String status,
            @JsonIgnore long total
    ) {
    }
}
```
