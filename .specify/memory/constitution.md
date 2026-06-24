---
# Wave 23 §23.A.9/§23.A.10 — memory frontmatter for time-decay ranking
last_referenced_at: "2026-04-14T21:22:22.712336+00:00"
reference_count: 0
decay_floor: true
---

# Project Constitution: [PROJECT_NAME]

**Version:** 1.0
**Established:** [DATE]
**Last Amended:** [DATE]

---

## Article I: Project Identity

### 1.1 Purpose

<!-- ONE sentence describing what this project does and why it exists -->

[PROJECT_NAME] is a [type of system] that [primary function] for [target users] to [key benefit].

### 1.2 Vision

<!-- 2-3 sentences describing the long-term vision -->

[Describe where this project is heading and what success looks like]

### 1.3 Users

| Persona     | Description    | Primary Needs    |
| ----------- | -------------- | ---------------- |
| [Persona 1] | [Who they are] | [What they need] |
| [Persona 2] | [Who they are] | [What they need] |

### 1.4 Success Metrics

| Metric     | Target         | Measurement    |
| ---------- | -------------- | -------------- |
| [Metric 1] | [Target value] | [How measured] |
| [Metric 2] | [Target value] | [How measured] |

---

## Article II: Technology Stack

### 2.1 Runtime & Platform

| Component              | Technology                    | Version   | Notes     |
| ---------------------- | ----------------------------- | --------- | --------- |
| Production Environment | [Cloud/On-prem]               | -         | [Details] |
| Container Platform     | [Docker/K8s/OpenShift/None]   | [Version] | [Details] |
| CI/CD                  | [GitHub Actions/Jenkins/etc.] | -         | [Details] |
| Package Manager        | [npm/yarn/pnpm]               | [Version] | [Details] |

### 2.2 Backend

| Component         | Technology             | Version   | Notes                          |
| ----------------- | ---------------------- | --------- | ------------------------------ |
| Language          | [Language]             | [Version] | [e.g., "Strict mode required"] |
| Framework         | [Framework]            | [Version] |                                |
| Database          | [Database]             | [Version] |                                |
| ORM/Query Builder | [Tool]                 | [Version] |                                |
| Caching           | [Redis/Memcached/None] | [Version] |                                |
| Messaging         | [Kafka/RabbitMQ/None]  | [Version] |                                |

### 2.3 Frontend

| Component        | Technology                               | Version   | Notes |
| ---------------- | ---------------------------------------- | --------- | ----- |
| Framework        | [React/Vue/Angular/etc.]                 | [Version] |       |
| Language         | [TypeScript/JavaScript]                  | [Version] |       |
| State Management | [Redux/Zustand/React Query/etc.]         | [Version] |       |
| Styling          | [Tailwind/CSS Modules/Styled Components] | [Version] |       |
| Build Tool       | [Vite/Webpack/etc.]                      | [Version] |       |

### 2.4 Testing

| Type                | Framework                 | Version   | Notes |
| ------------------- | ------------------------- | --------- | ----- |
| Unit Testing        | [Jest/Vitest/etc.]        | [Version] |       |
| Integration Testing | [Supertest/etc.]          | [Version] |       |
| E2E Testing         | [Playwright/Cypress/etc.] | [Version] |       |
| Contract Testing    | [Pact/Dredd/None]         | [Version] |       |
| Load Testing        | [k6/Artillery/None]       | [Version] |       |

---

## Article III: Quality Standards

### 3.1 Code Quality

#### Type Safety

- TypeScript strict mode: **Required** / Optional
- No `any` types except: [exceptions, if any]
- Explicit return types: Required for public APIs / All functions / Not required

#### Linting

- Tool: [ESLint/Biome/etc.]
- Config: [Standard/Airbnb/Custom]
- Pre-commit enforcement: Yes / No

#### Formatting

- Tool: [Prettier/Biome/etc.]
- Config: [Link or inline]
- Auto-format on save: Recommended / Required

### 3.2 Test Coverage

| Scope       | Minimum   | Recommended | Critical Paths |
| ----------- | --------- | ----------- | -------------- |
| Overall     | [X]%      | [Y]%        | 100%           |
| New Code    | [X]%      | [Y]%        | 100%           |
| Unit Tests  | [X]%      | [Y]%        | -              |
| Integration | Key paths | All paths   | -              |

### 3.3 Performance

| Metric             | Target | Alert Threshold |
| ------------------ | ------ | --------------- |
| API Response (p50) | [X]ms  | [Y]ms           |
| API Response (p95) | [X]ms  | [Y]ms           |
| API Response (p99) | [X]ms  | [Y]ms           |
| Page Load (LCP)    | [X]s   | [Y]s            |
| Database Query     | [X]ms  | [Y]ms           |

### 3.4 Security

#### Authentication

- Method: [JWT/Session/OAuth2/etc.]
- Token storage: [httpOnly cookies/localStorage/etc.]
- Session duration: [Duration]
- Refresh strategy: [Strategy]

#### Authorization

- Model: [RBAC/ABAC/ACL]
- Enforcement: [Middleware/Decorator/etc.]
- Default: Deny all / Allow authenticated

#### Data Protection

- Encryption at rest: Required / Not required
- Encryption in transit: TLS [version]+ required
- PII handling: [Policy]
- Secrets management: [Tool/Method]

#### Compliance

- [ ] OWASP Top 10 addressed
- [ ] [GDPR/CCPA/HIPAA/SOC2/etc.] compliant
- [ ] Security scanning in CI

### 3.5 Accessibility

- Standard: WCAG [2.0/2.1/2.2] [A/AA/AAA]
- Testing: [Manual/Automated/Both]
- Tools: [axe/Lighthouse/etc.]
- Enforcement: CI checks / Manual review / Both

---

## Article IV: Architecture Principles

### 4.1 Core Principles

1. **[Principle 1 Name]**
   [Explanation of the principle and why it matters]

2. **[Principle 2 Name]**
   [Explanation]

3. **[Principle 3 Name]**
   [Explanation]

### 4.2 Code Organization

```
[PROJECT_ROOT]/
├── src/
│   ├── [layer1]/          # [Description]
│   ├── [layer2]/          # [Description]
│   └── [layer3]/          # [Description]
├── tests/
│   ├── unit/              # Unit tests mirror src/ structure
│   ├── integration/       # Integration tests
│   └── e2e/               # End-to-end tests
├── docs/                  # Documentation
└── .specify/              # Specification artifacts
```

### 4.3 Dependency Rules

```
[Allowed dependency directions - use arrows]

UI Layer
    ↓
Service Layer
    ↓
Data Layer
    ↓
External Services
```

**Rules:**

- [Rule 1, e.g., "UI may not directly access Data Layer"]
- [Rule 2, e.g., "Services may not import from UI"]

### 4.4 API Design

- Style: REST / GraphQL / gRPC / Mixed
- Versioning: URL path (`/v1/`) / Header / Query param
- Naming: kebab-case paths, camelCase JSON fields
- Pagination: Cursor-based / Offset-based
- Error format: RFC 7807 / Custom

### 4.5 Error Handling

```typescript
interface ApplicationError {
  code: string; // Machine-readable code
  message: string; // Human-readable message
  details?: object; // Additional context
  traceId?: string; // Correlation ID
}
```

### 4.6 Logging & Observability

#### Logging

- Format: JSON structured
- Levels: `debug`, `info`, `warn`, `error`
- Required fields: `timestamp`, `level`, `message`, `traceId`

---

## Article V: Development Workflow

### 5.1 Branch Strategy

- **Model:** [GitFlow / Trunk-based / GitHub Flow]
- **Main branch:** `main` (always deployable)
- **Feature branches:** `feature/[ticket-id]-[description]`

### 5.2 Commit Messages

Format: Conventional Commits

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### 5.3 Pull Request Requirements

**Before Opening:**

- [ ] Tests pass locally
- [ ] Linting passes
- [ ] Self-review completed

**Required for Merge:**

- [ ] [N] approving reviews
- [ ] CI pipeline passes
- [ ] No unresolved comments

### 5.4 Definition of Done

A feature is DONE when:

- [ ] Code complete and merged
- [ ] Tests written and passing
- [ ] Documentation updated
- [ ] Code reviewed and approved
- [ ] Deployed to staging
- [ ] Product owner accepted

### 5.5 TDD Mode

```
tdd_mode: false  # Set to true to activate TDD enforcement via tdd-enforce.instructions.md
```

When `tdd_mode: true`, agents in the Software Engineer and Test Engineer roles must write
failing tests **before** writing any implementation code. Gate 2 will verify test stubs
exist prior to implementation tasks being unlocked.

---

## Article VI: Model Configuration

### 6.1 Model Tier Mapping

| Tier     | Provider  | Model             | Fallback          |
| -------- | --------- | ----------------- | ----------------- |
| deep     | Anthropic | Claude Opus 4.6   | Claude Sonnet 4.6 |
| standard | Anthropic | Claude Sonnet 4.6 | Claude Haiku 4.6  |
| light    | Anthropic | Claude Sonnet 4.6 | Claude Haiku 4.6  |

### 6.2 Budget Controls

- Budget Ceiling: 50.00
- Warning Threshold: 80% of budget ceiling
- Hard Stop Threshold: 100% of budget ceiling unless explicitly approved

> **Note:** The `model-tier` field in agent definitions is resolved to the specific model
> at generation time by the adapter generator (`sdd adapters generate`). This allows
> switching LLM providers without modifying individual agent files.

### 6.3 Agent Tier Assignments

| Tier     | Agents                                                                                                                                                                                                                                         |
| -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| deep     | architect, test-explorer, constitution                                                                                                                                                                                                         |
| standard | requirement-analyst, clarification, api-champion, messaging-champion, gherkin-analyst, analysis, test-engineer, software-engineer, review, refactoring, agent-builder, instruction-builder, guidance-builder, prompt-builder, workflow-builder |
| light    | brainstorming, tech-context-maintainer, workflow-builder                                                                                                                                                                                       |

---

## Article VII: Boundaries

### 7.1 Always Do

1. Run tests before committing
2. Include trace ID in all log messages
3. Validate all external input
4. Use parameterized queries
5. Encrypt PII at rest and in transit

### 7.2 Ask First

1. Adding new dependencies
2. Changing database schema
3. Modifying authentication/authorization logic
4. Adding new external service integrations
5. Changing API contracts (breaking changes)

### 7.3 Never Do

1. Commit secrets, API keys, or credentials
2. Disable TypeScript strict mode
3. Use `any` without explicit justification
4. Skip tests to make CI pass
5. Log PII or credentials

---

## Article VIII: Amendments

### 8.1 Amendment Process

1. **Proposal:** Create PR modifying `.specify/memory/constitution.md`
2. **Review:** Tech Lead and at least one senior engineer review
3. **Discussion:** Team discussion for significant changes
4. **Approval:** Tech Lead approval required

### 8.2 Amendment Log

| Date   | Version | Article | Change               | Author   |
| ------ | ------- | ------- | -------------------- | -------- |
| [DATE] | 1.0     | -       | Initial constitution | [Author] |
