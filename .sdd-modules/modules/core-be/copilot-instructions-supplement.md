# Core-BE — Copilot Instructions Supplement

## Organization

- Organization: Acme Securities
- Organization Short Name: acme.sec
- Project Name: {project-name}
- GitLab Project ID: {gitlab-project-id}
- PowerShell as Terminal

## Java Coding Guidelines

- Use Java 21 features and syntax.
- Don't use `@Inject` to inject classes dependencies, use constructor injection instead.
- Use Lombok annotations to reduce boilerplate code.
- Use `var` and `const var` for variable declarations.
- Don't create try/catch blocks for Exception handling, unless it's explicitly mentioned in the implementation plan or instructions.
- Use `@SneakyThrows` only when it's necessary to avoid checked exceptions.
- For field validations and entity existence checks, use `ValidationException` and its subclasses with `OperationError` objects with appropriate error messages with values placeholders.
- Don't create comments related to the current prompt or the implementation plan. Only create comments that explain the code logic related to the whole context.
- Use private and package private visibility whenever possible. Only use public and protected when is really necessary.
- Don't create any logging in the code, unless it's explicitly mentioned in the implementation plan or instructions.
- Avoid using full package names in the code, use imports instead.
- Always keep a blank line before and after methods, if statements, loops, and try/catch blocks.

## Checkstyle Rules

The project enforces checkstyle rules defined in `checkstyle.xml` at the repository root:

- Java files must not exceed **1000 lines**.
- Lines must not exceed **125 characters** (excluding `package`, `import` statements and URLs).
- Do not leave **unused imports** in the code.
- Do not leave **unused local variables** in the code.
- Do not use **fully qualified class names** inline in the code. Always use import statements instead.
- No whitespace **after** unary operators: `~`, `--`, `.`, `++`, `!`, unary `-`, unary `+`.
- No whitespace **before**: `,`, `--` (postfix), `++` (postfix), `;`.
