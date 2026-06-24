---
applyTo: "**/*.ts,**/*.tsx"
---
# Project coding standards for TypeScript
- Use TypeScript for all new code
- Follow functional programming principles where possible
- Use interfaces for data structures and type definitions
- Prefer classes when data needs to be instantiated
- Prefer immutable data (const, readonly)
- Use optional chaining (?.) and nullish coalescing (??) operators

## Constants and Configuration
- Magic numbers used in multiple locations must be centralized
- Application-level feature configuration should be stored in `package.json` config section
- Extract repeated values to `package.json` config section for application-level settings
- Use named constants for module-level values
- Examples: Export limits, pagination defaults, timeout values used across multiple components
