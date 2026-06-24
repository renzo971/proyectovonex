# Quality Tools Setup Template

> This template is consumed by the `/scaffold-project` prompt or quality-related agents
> to scaffold code quality tooling. All values are derived from the constitution.

## Inputs (from Constitution)

| Input | Constitution Source | Example |
|-------|-------------------|---------|
| `{linter}` | Article III / V — Quality Tools | Checkstyle, ESLint, Ruff |
| `{formatter}` | Article III / V — Quality Tools | Spotless, Prettier, Black |
| `{coverage-tool}` | Article III / V — Quality Tools | JaCoCo, c8, coverage.py |
| `{static-analysis}` | Article III / V — Quality Tools | SonarQube, none |

## Output

The agent should create:

1. **Linter configuration file** (e.g., `.eslintrc`, `checkstyle.xml`, `ruff.toml`)
2. **Formatter configuration** (e.g., `.prettierrc`, `spotless` in build file)
3. **Coverage configuration** in build tool
4. **Quality gate thresholds** (from constitution)
5. **CI/CD integration** (if applicable)

## Configuration Examples

### Linter
```
# ESLint → .eslintrc.json
# Checkstyle → checkstyle.xml
# Ruff → ruff.toml / pyproject.toml [tool.ruff]
```

### Formatter
```
# Prettier → .prettierrc
# Spotless → build.gradle / pom.xml plugin
# Black → pyproject.toml [tool.black]
```

### Coverage
```
# JaCoCo → Maven/Gradle plugin config
# c8 → .c8rc.json or package.json
# coverage.py → .coveragerc or pyproject.toml
```

## Agent Instructions

When asked to set up quality tools:
1. Read the constitution for Article III / V quality tool values
2. Create configuration files for each tool
3. Add tool dependencies to the build configuration
4. Configure quality gate thresholds matching constitution requirements
5. Add CI/CD pipeline steps if a CI/CD system is specified
6. Document how to run quality checks locally
