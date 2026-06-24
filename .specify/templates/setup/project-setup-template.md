# Project Setup Template

> This template is consumed by the Constitution agent or the `/scaffold-project` prompt
> to scaffold a new project. All values are derived from the constitution.

## Inputs (from Constitution)

| Input | Constitution Source | Example |
|-------|-------------------|---------|
| `{language}` | Article II — Language | Java 21, TypeScript 5.x, Python 3.12 |
| `{framework}` | Article II — Framework | Quarkus, Spring Boot, Next.js, FastAPI |
| `{build-tool}` | Article II — Build Tool | Maven, Gradle, npm, pip |
| `{database}` | Article II — Database | PostgreSQL, MongoDB, SQLite |
| `{messaging}` | Article II — Messaging | Kafka, RabbitMQ, none |
| `{testing-framework}` | Article II — Testing | JUnit + Cucumber, Jest + Playwright, pytest |
| `{ci-cd}` | Article II — CI/CD | GitLab CI, GitHub Actions, none |

## Output Structure

The agent should create:

1. **Project root** with build configuration file
2. **Source directory** structure matching the architectural pattern (Article III)
3. **Test directory** structure mirroring source
4. **Docker Compose** file for local development (database + messaging if applicable)
5. **CI/CD pipeline** configuration (if specified)
6. **README.md** with setup instructions
7. **`.specify/`** directory (via `sdd init`)

## Agent Instructions

When asked to scaffold a project:
1. Read the constitution for all Article II values
2. Ask for any missing values (project name, repository URL)
3. Generate the directory structure and configuration files
4. Run `sdd init` to set up the SDD workflow
5. Suggest running `@constitution` to validate the setup
