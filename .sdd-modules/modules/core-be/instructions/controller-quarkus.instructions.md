---
applyTo: "infrastructure/**/*Controller.java"
description: Quarkus/JAX-RS controller patterns with OpenAPI codegen, CDI, and CQRS delegation
---

> **Note:** Java package examples below use `com.acme.securities` as a fictional placeholder. Replace with your organization's package root before generating production code.

# Quarkus Controller Implementation Guidelines

## Overview

Controllers implement generated OpenAPI interfaces and delegate to use cases or query handlers. The project uses the openapi-generator-maven-plugin to generate JAX-RS interfaces from OpenAPI specifications, making controllers simple implementation classes.

## Project Context

- Framework: Quarkus with JAX-RS
- Code Generation: openapi-generator-maven-plugin with jaxrs-spec generator
- Generated interfaces are available in target/generated-sources/src/gen/java/

## Structure

```
infrastructure/src/main/java/com/acme/securities/{project-name}/infrastructure/web/controller/
└── {controllerName}/
    ├── {ControllerName}Controller.java
    └── mappers/
        ├── Create{EntityName}Mapper.java
        ├── Update{EntityName}Mapper.java
        ├── Execute{EntityName}WorkflowTransitionMapper.java
        └── Search{EntityName}Mapper.java
```

## Requirements

### Controller Class

- Must extend `BaseController`
- Must implement the generated API interface
- Use `@RequestScoped` for CDI
- Use `@Path` annotation at class level (can be inherited from interface)
- Use `@Tag` for OpenAPI documentation grouping
- All JAX-RS and OpenAPI annotations are provided by the generated interface

### Generated Interface Integration

- Generated interfaces provide complete JAX-RS annotations (`@Path`, `@GET`, `@POST`, `@PUT`, `@DELETE`)
- Generated interfaces include OpenAPI annotations (`@ApiOperation`, `@ApiResponse`, `@ApiParam`)
- Generated interfaces include validation annotations (`@Valid`, `@NotNull`)
- Controllers simply implement interface methods without additional annotations

### CQRS Pattern

- GET operations: Use `QueryHandlerFactory` to invoke Query Handlers
- POST/PUT/PATCH/DELETE operations: Use `UseCaseFactory` to invoke Use Cases
- POST is used in Search endpoints
- Use `getCurrentContext()` from `BaseController` to get `WebExecutionContext`
- Keep controllers thin — delegate business logic

### Data Mapping

- Use dedicated mapper classes for converting between API models and domain objects
- Generated request/response models are in the `model` package
- Mappers are located in the `mappers` package within each controller package
- Each operation has its own mapper following the pattern `{OperationId}Mapper`
- Mappers handle conversion from API models to use case inputs and vice versa
- Path parameters are automatically bound by JAX-RS annotations in generated interface

### Response Building

- Use `Response.created()` for successful creation with location header
- Use `Response.ok()` for successful operations
- Use `Response.noContent()` for successful updates/deletions without content
- Generated interface defines return type as `Response` for all operations
- **NEVER** build responses using dynamic structures like `Map()` or generic objects
- **ALWAYS** use the generated response classes from OpenAPI specification components
- Use the operation mapper class to convert domain objects to the appropriate generated response classes

### Error Handling

- Generated interfaces include comprehensive `@ApiResponse` annotations for error cases
- Use appropriate HTTP status codes defined in the generated interface
- Business exceptions are handled by global exception mappers

### Controller Example

```java
@Path("/api/v1/my-sample-entities")
@RequiredArgsConstructor
@RequestScoped
@Tag(name = "MySampleEntity Management", description = "Operations for managing MySampleEntity")
public class MySampleEntityController extends BaseController implements MySampleEntitiesApi {

    private final UseCaseFactory useCaseFactory;
    private final QueryHandlerFactory queryHandlerFactory;
    private final CreateMySampleEntityMapper createMapper;
    private final UpdateMySampleEntityMapper updateMapper;
    private final ExecuteMySampleEntityWorkflowTransitionMapper workflowMapper;

    @Override
    public Response createMySampleEntity(@Valid @NotNull MySampleEntityRequest request) {
        var useCase = useCaseFactory.create(CreateMySampleEntityUseCase.class);
        var context = getCurrentContext();
        var input = createMapper.toInput(request, context);
        var output = useCase.execute(input, context);

        var result = createMapper.toResponse(output);
        var location = UriBuilder.fromPath("/my-sample-entities/{id}")
            .build(output.getMySampleEntity().getId().getValue());

        return Response.created(location)
            .entity(result)
            .build();
    }

    @Override
    public Response getMySampleEntity(UUID id) {
        var handler = queryHandlerFactory.create(GetMySampleEntityByIdQueryHandler.class);
        var query = GetMySampleEntityByIdQuery.of(id);
        var context = getCurrentContext();
        var result = handler.execute(query, context);

        return Response.ok(result).build();
    }

    @Override
    public Response updateMySampleEntity(UUID id, @Valid @NotNull MySampleEntityRequest request) {
        var useCase = useCaseFactory.create(UpdateMySampleEntityUseCase.class);
        var context = getCurrentContext();
        var input = updateMapper.toInput(id, request, context);
        var output = useCase.execute(input, context);

        var result = updateMapper.toResponse(output);
        return Response.ok(result).build();
    }

    @Override
    public Response deleteMySampleEntity(UUID id) {
        var useCase = useCaseFactory.create(DeleteMySampleEntityUseCase.class);
        var input = DeleteMySampleEntityInput.of(id);
        var context = getCurrentContext();
        useCase.execute(input, context);

        return Response.noContent().build();
    }
}
```

### Request/Response DTOs

Generated request/response models are automatically created by openapi-generator and include all necessary annotations. Controllers consume generated `*Request` classes and produce generated `*Response` classes without manual DTO creation.
