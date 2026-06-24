# Ship Checklist: [FEATURE_NAME]

**Feature ID:** [NNN]-[feature-slug]
**Ship Date:** [DATE]
**Release Version:** [Version]
**Status:** In Progress | Ready to Ship | Shipped

---

## 1. Pass 1 — Spec Compliance

> Pass 1 must pass before Pass 2 (Code Quality) is evaluated. If any AC fails verification,
> the review stops here with `CHANGES REQUIRED`.

### 1.1 User Stories

| Story | Acceptance Criteria | Pass/Fail | Evidence (test name, file, line) | Verifier |
|-------|---------------------|-----------|----------------------------------|----------|
| US-001 | All ACs implemented | [ ] | | |
| US-002 | All ACs implemented | [ ] | | |
| US-003 | All ACs implemented | [ ] | | |

### 1.2 Non-Functional Requirements

| NFR | Requirement | Verified | Evidence |
|-----|-------------|----------|----------|
| NFR-001 | Performance: p95 < 200ms | [ ] | [Link to metrics] |
| NFR-002 | Security: Auth on all endpoints | [ ] | [Link to tests] |
| NFR-003 | Accessibility: WCAG 2.1 AA | [ ] | [Link to audit] |

### 1.3 Edge Cases

| Edge Case | Handled | Test |
|-----------|---------|------|
| EC-001 | [ ] | TC-005 |
| EC-002 | [ ] | TC-006 |

### 1.4 Test Coverage (spec-driven)

- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] All E2E tests passing
- [ ] Test coverage ≥ 80%

**Coverage Report:**
- Overall: __%
- New code: __%
- Critical paths: 100%

**Pass 1 Verdict:** ✅ PASS | ❌ FAIL (list failing ACs)

---

## 2. Pass 2 — Code Quality

> Evaluated only after Pass 1 passes. For trivial-complexity features (≤ 1 US, ≤ 3 files,
> no new domain entities), Pass 1 and Pass 2 are evaluated together in a single pass.

### 2.1 Code Standards

- [ ] No TypeScript errors
- [ ] No ESLint errors/warnings
- [ ] No Prettier violations
- [ ] No `console.log` in production code
- [ ] No `any` types without justification

### 2.2 Code Review

- [ ] Code review completed
- [ ] All review comments addressed
- [ ] At least 2 approvals (for auth/security changes)

**Reviewers:**
- [ ] [Reviewer 1]
- [ ] [Reviewer 2]

---

## 3. Security

### 3.1 Security Checks

- [ ] Authentication implemented correctly
- [ ] Authorization guards on all endpoints
- [ ] Input validation on all user inputs
- [ ] No SQL injection vulnerabilities
- [ ] No XSS vulnerabilities
- [ ] Sensitive data encrypted
- [ ] No secrets in code

### 3.2 Security Scan

- [ ] SAST scan passed (static analysis)
- [ ] DAST scan passed (dynamic analysis)
- [ ] Dependency vulnerability scan passed

### 3.3 Security Reviewer Agent Report

- [ ] Security Reviewer agent has been invoked (`security-report.md` exists)
- [ ] **Critical findings: 0** (blocks ship if >0)
- [ ] **High findings: 0** (blocks ship if >0)
- [ ] Medium findings reviewed and accepted by Security Lead
- [ ] Remediation evidence attached for any resolved findings

**Security Report:** `.specify/specs/[NNN]/security-report.md`

**Scan Results:**
- Critical: 0
- High: 0
- Medium: [count] (accepted/mitigated)

---

## 4. Documentation

### 4.1 Technical Documentation

- [ ] API documentation updated (OpenAPI)
- [ ] README updated
- [ ] Architecture diagrams updated
- [ ] Runbook updated (if applicable)

### 4.2 Specification Artifacts

- [ ] business-context.md finalized
- [ ] spec.md finalized
- [ ] clarifications.md complete
- [ ] plan.md matches implementation
- [ ] test-cases.md matches tests
- [ ] tasks.md all complete

---

## 5. Deployment

### 5.1 Database

- [ ] Migrations tested locally
- [ ] Migrations tested in staging
- [ ] Rollback migration verified
- [ ] Data migration verified (if applicable)

### 5.2 Configuration

- [ ] Environment variables documented
- [ ] Secrets stored securely
- [ ] Feature flags configured

### 5.3 Infrastructure

- [ ] Resource requirements validated
- [ ] Scaling configuration set
- [ ] Health checks configured

---

## 6. Monitoring & Observability

### 6.1 Logging

- [ ] Structured logging implemented
- [ ] Log levels appropriate
- [ ] Trace IDs propagated
- [ ] No PII in logs

### 6.2 Metrics

- [ ] Key metrics exposed
- [ ] Dashboards created/updated
- [ ] Baseline metrics recorded

### 6.3 Alerts

- [ ] Error rate alerts configured
- [ ] Latency alerts configured
- [ ] Alert runbook documented

---

## 7. Rollback Plan

### 7.1 Rollback Triggers

| Condition | Action |
|-----------|--------|
| Error rate > 5% | Immediate rollback |
| p95 latency > 500ms | Investigate, rollback if persists |
| Critical security issue | Immediate rollback |

### 7.2 Rollback Procedure

1. [ ] Disable feature flag (if applicable)
2. [ ] Revert deployment
3. [ ] Rollback database migration
4. [ ] Verify system stability
5. [ ] Notify stakeholders

### 7.3 Rollback Tested

- [ ] Rollback procedure tested in staging

---

## 8. Stakeholder Sign-offs

### 8.1 Technical

- [ ] **Tech Lead:** _________________ 
  - Code quality acceptable
  - Architecture aligned
  - Date: _______

- [ ] **Security Lead:** _________________
  - Security review passed
  - Date: _______

### 8.2 Quality

- [ ] **QA Lead:** _________________
  - Test coverage sufficient
  - All tests passing
  - Date: _______

### 8.3 Business

- [ ] **Product Owner:** _________________
  - Business intent verified
  - Acceptance criteria met
  - Date: _______

---

## 9. Final Checks

### Pre-Deploy

- [ ] All CI/CD pipelines green
- [ ] Staging environment tested
- [ ] Load test completed (if required)
- [ ] Runbook reviewed

### Post-Deploy

- [ ] Smoke tests passed
- [ ] Metrics within expected range
- [ ] No new errors in logs
- [ ] Feature verified in production

---

## 10. Reviewer Focus

These areas need human attention — they are AI-flagged items that require human judgment, low-confidence findings, or unresolved clarification markers.

### 10.1 Items Requiring Human Judgment

| # | Location | Finding | Confidence | Why Human Needed |
|---|----------|---------|------------|------------------|
| 1 | [file:line] | [description] | Low/Medium | [reason AI cannot decide] |
| 2 | [file:line] | [description] | Low/Medium | [reason AI cannot decide] |

### 10.2 Unresolved Clarification Markers

| Marker | Artifact | Line | Reason |
|--------|----------|------|--------|
| `[NEEDS CLARIFICATION: ...]` | [file] | [line] | [reason] |

### 10.3 Low-Confidence Findings

| Finding | Source | Confidence | Recommended Action |
|---------|--------|------------|--------------------|
| [finding] | [artifact] | Low | [verify/confirm/override] |

**Total Reviewer Focus Items:** [N] items across [M] categories

---

## 11. Ship Decision

**Verdict:** ✅ READY TO SHIP | ⚠️ CONDITIONAL | ❌ NOT READY

**Conditions (if applicable):**
- [Condition 1]
- [Condition 2]

**Ship Date:** [DATE]
**Shipped By:** [Name]

---

## 12. Post-Ship Notes

### Lessons Learned

- [Lesson 1]
- [Lesson 2]

### Follow-up Items

| Item | Owner | Due Date |
|------|-------|----------|
| [Item 1] | [Name] | [Date] |
| [Item 2] | [Name] | [Date] |
