# Article IV — Coding Conventions

> **Module:** core-be
> **Purpose:** Merge this into your project's constitution Article IV.

## Dependency Injection

- **Constructor injection only** — never use `@Inject` field injection
- Use `@RequiredArgsConstructor` (Lombok) for automatic constructor generation
- Use `@ApplicationScoped` for CDI beans

## Lombok Annotations

| Annotation | Usage |
|-----------|-------|
| `@Getter` | On all domain entities and value objects |
| `@RequiredArgsConstructor` | On CDI beans for constructor injection |
| `@NoArgsConstructor(access = PROTECTED)` | On JPA entities and domain objects |
| `@Builder` | On Info objects and DTOs |
| `@SneakyThrows` | Only when necessary to avoid checked exceptions |

## Variable Declarations

- Use `var` for local variable declarations whenever the type is obvious
- Use `const var` where applicable

## Exception Handling

- **No try/catch blocks** unless explicitly specified in the implementation plan
- Use `ValidationException` with `OperationError` objects for field validations
- Use `OperationResult.failure()` for business rule violations
- Let framework handle exception mapping via global exception mappers

## Visibility Rules

- **private** or **package-private** by default
- **public** only when truly necessary (API surface)
- **protected** only for inheritance/framework requirements

## Logging

- **No logging** unless explicitly required
- When needed, use SLF4J with `@Slf4j` (Lombok)

## Code Formatting

- Blank line before and after: methods, if statements, loops, try/catch blocks
- No comments except those explaining complex logic
- No fully qualified class names — always use imports

## Checkstyle Constraints

- Max **1000 lines** per Java file
- Max **125 characters** per line (excluding package/import/URLs)
- No unused imports or local variables
- Strict whitespace rules around operators and punctuation

## Domain Object Conventions

- Aggregate factory methods accept **Info objects**, not individual parameters
- Validation logic belongs in aggregate factory methods, not in Info objects
- Use **strongly typed identifiers** (e.g., `OrderId`, `CustomerId`)
- Implement `buildInfo()` for data transfer from aggregate to other layers
- Register domain events for all state changes
