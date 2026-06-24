---
applyTo: "**/*"
---
# Project general coding standards
- Use PascalCase for component names, interfaces, classes, and type aliases
- Use camelCase for variables, functions, and methods
- Use a maximum of 4 words when naming things
- Use try/catch blocks for async operations

## Code Formatting
- All formatting issues should be validated by running `npm run lint`
- ESLint configuration (.eslintrc.cjs) is the source of truth for code formatting rules
- Do NOT report formatting issues that ESLint does not flag

## File Size Management
- Files under 150 lines: No issues
- Files between 150-300 lines (Low Priority): Evaluate for possible refactoring or splitting
- Files over 300 lines (High Priority): Refactoring required to improve maintainability

## Code Formatting (Low Priority)
- Insert an empty line to separate multiline code blocks from the next statement
