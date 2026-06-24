# Integration Tests Setup Template

> This template is consumed by the `/scaffold-project` prompt or test-related agents
> to scaffold integration test infrastructure. All values are derived from the constitution.

## Inputs (from Constitution)

| Input | Constitution Source | Example |
|-------|-------------------|---------|
| `{testing-framework}` | Article II — Testing | JUnit 5, Jest, pytest |
| `{bdd-framework}` | Article II — BDD | Cucumber, behave, none |
| `{api-testing}` | Article II — API Testing | REST Assured, supertest, httpx |
| `{container-testing}` | Article II — Container Testing | Testcontainers, docker-compose, none |

## Output

The agent should create:

1. **Test module/directory structure** appropriate for the project layout
2. **Test framework configuration** (dependencies, plugins, build tool integration)
3. **Test infrastructure** (containers, fixtures, factories)
4. **Sample smoke test** verifying the setup works
5. **Documentation** for running tests locally

## Directory Structure Example

```
tests/
├── integration/
│   ├── fixtures/          # Shared test data and setup
│   ├── containers/        # Container configurations (if using Testcontainers)
│   └── smoke/             # Smoke tests verifying infrastructure
└── config/
    └── test-config.*      # Test framework configuration
```

## Agent Instructions

When asked to set up integration tests:
1. Read the constitution for Article II testing values
2. Create the test directory structure
3. Add test framework dependencies to the build configuration
4. Configure container-based testing if specified (database, messaging)
5. Create a smoke test that validates the infrastructure starts correctly
6. Document how to run tests locally and in CI
