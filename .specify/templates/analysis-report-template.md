# Consistency Analysis: [FEATURE_NAME]

**Feature ID:** [NNN]-[feature-slug]
**Analysis Date:** [DATE]
**Analyst:** Analysis Agent
**Status:** Pass | Pass with Warnings | Fail

---

## 1. Executive Summary

**Overall Verdict:** ✅ PASS | ⚠️ PASS WITH WARNINGS | ❌ FAIL

| Category | Status | Issues |
|----------|--------|--------|
| Requirement Coverage | ✅ | 0 |
| Design Alignment | ✅ | 0 |
| Test Coverage | ⚠️ | 1 |
| Orphan Detection | ✅ | 0 |
| Constitution Compliance | ✅ | 0 |

---

## 2. Traceability Matrix

### 2.1 User Story → Design → Task → Test

| User Story | Plan Coverage | Task Coverage | Test Coverage | Status |
|------------|---------------|---------------|---------------|--------|
| US-001 | ✅ Section 2.1 | ✅ T001, T004 | ✅ TC-001, TC-002 | ✅ OK |
| US-002 | ✅ Section 2.2 | ✅ T005, T006 | ✅ TC-003, TC-004 | ✅ OK |
| US-003 | ✅ Section 2.3 | ⚠️ T007 only | ⚠️ TC-005 only | ⚠️ WARN |

### 2.2 Non-Functional Requirements Coverage

| NFR | Plan Coverage | Implementation | Test Coverage | Status |
|-----|---------------|----------------|---------------|--------|
| NFR-001 (Performance) | ✅ Section 6 | ✅ Caching configured | ✅ TC-007 | ✅ OK |
| NFR-002 (Security) | ✅ Section 5 | ✅ Guards implemented | ✅ TC-008 | ✅ OK |
| NFR-003 (Accessibility) | ✅ Section 2 | ⏳ Not yet | ⏳ Not yet | ⏳ PENDING |

### 2.3 Edge Cases Coverage

| Edge Case | Task Coverage | Test Coverage | Status |
|-----------|---------------|---------------|--------|
| EC-001 | ✅ T004 | ✅ TC-005 | ✅ OK |
| EC-002 | ✅ T005 | ❌ MISSING | ❌ FAIL |

### 2.4 Error Scenarios Coverage

| Error | Task Coverage | Test Coverage | Status |
|-------|---------------|---------------|--------|
| ERR-001 | ✅ T004 | ✅ TC-006 | ✅ OK |
| ERR-002 | ✅ T005 | ✅ TC-006 | ✅ OK |

---

## 3. Issues Found

### 3.1 Critical Issues

> Issues that must be resolved before implementation

| ID | Category | Description | Resolution | Owner |
|----|----------|-------------|------------|-------|
| - | - | No critical issues found | - | - |

### 3.2 Warnings

> Issues that should be addressed but don't block

| ID | Category | Description | Recommendation | Owner |
|----|----------|-------------|----------------|-------|
| W-001 | Test Gap | EC-002 missing test coverage | Add TC for empty list handling | QA |
| W-002 | Spec Gap | US-003 has only 1 AC | Consider adding edge case AC | FA |

### 3.3 Suggestions

> Improvements that would enhance quality

| ID | Category | Suggestion | Priority |
|----|----------|------------|----------|
| S-001 | Testing | Add performance test for pagination | Low |
| S-002 | Documentation | Add sequence diagram for auth flow | Low |

---

## 4. Orphan Detection

### 4.1 Orphan Tasks

> Tasks not linked to any requirement

| Task | Description | Recommendation |
|------|-------------|----------------|
| - | No orphan tasks found | - |

### 4.2 Orphan Tests

> Tests not linked to any acceptance criteria

| Test | Description | Recommendation |
|------|-------------|----------------|
| - | No orphan tests found | - |

### 4.3 Orphan Requirements

> Requirements not covered by design

| Requirement | Description | Recommendation |
|-------------|-------------|----------------|
| - | No orphan requirements found | - |

---

## 5. Goal-Backward Verification

> Forward traceability asks: "Is every requirement covered?"
> Backward verification asks: "Does the implementation actually achieve the feature goal?"

### 5.1 Feature Goal (from business-context.md)

| # | Goal / Success Metric | Source |
|---|----------------------|--------|
| G-001 | [Goal statement from business-context.md] | business-context.md §1.1 |
| G-002 | [Success metric from business-context.md] | business-context.md §1.4 |

### 5.2 Goal → Requirement → Outcome Mapping

| Goal | Mapped User Stories | Traceability Status | Goal Achieved? | Confidence |
|------|--------------------|--------------------|----------------|------------|
| G-001 | US-001, US-002 | ✅ All PASS | ✅ Yes | High |
| G-002 | US-003 | ⚠️ PASS WITH WARNINGS | ⚠️ Partial — [gap description] | Medium |

### 5.3 Unmapped Goals

| Goal | Issue | Recommendation |
|------|-------|----------------|
| - | No unmapped goals | - |

### 5.4 Backward Verification Verdict

**Verdict:** ✅ ALL GOALS ACHIEVED | ⚠️ PARTIAL (N gaps) | ❌ GOAL DRIFT DETECTED

[Summary of findings]

---

## 6. Constitution Compliance Check

### 6.1 Technology Stack (Article II)

| Requirement | Compliance | Notes |
|-------------|------------|-------|
| TypeScript strict mode | ✅ | Verified in tsconfig |
| NestJS framework | ✅ | Module structure correct |
| Prisma ORM | ✅ | Schema defined |
| Vitest for testing | ✅ | Test files use vitest |

### 6.2 Quality Standards (Article III)

| Standard | Compliance | Notes |
|----------|------------|-------|
| Test coverage ≥80% | ⏳ | To be verified after implementation |
| API response <200ms | ⏳ | To be verified after implementation |
| OWASP compliance | ✅ | Auth guards, input validation in plan |

### 6.3 Architecture Principles (Article IV)

| Principle | Compliance | Notes |
|-----------|------------|-------|
| Layer separation | ✅ | Controller → Service → Repository |
| No circular dependencies | ✅ | Module structure correct |
| Error handling | ✅ | ProblemDetails format used |

### 6.4 Boundaries (Article VI)

| Boundary | Compliance | Notes |
|----------|------------|-------|
| No secrets in code | ✅ | Environment variables used |
| Parameterized queries | ✅ | Prisma handles |
| Input validation | ✅ | DTOs with class-validator |

---

## 7. Cross-Reference Verification

### 7.1 Spec → Plan Alignment

| Spec Element | Plan Reference | Match |
|--------------|----------------|-------|
| User personas | Section 1.3 | ✅ |
| Functional requirements | Section 2 | ✅ |
| Non-functional requirements | Section 5, 6 | ✅ |
| API endpoints | Section 4 | ✅ |

### 7.2 Plan → Tasks Alignment

| Plan Component | Task Reference | Match |
|----------------|----------------|-------|
| Component 1 | T001, T003 | ✅ |
| Component 2 | T004, T005 | ✅ |
| Security | T008 | ✅ |

### 7.3 Test → Spec Alignment

| Test Category | Spec Coverage | Match |
|---------------|---------------|-------|
| Unit tests | AC-001 to AC-005 | ✅ |
| Integration tests | US-001, US-002 | ✅ |
| Edge case tests | EC-001 | ✅ (EC-002 missing) |
| Error tests | ERR-001, ERR-002 | ✅ |

---

## 8. Metrics Summary

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Requirement coverage | 95% | 100% | ⚠️ |
| Design coverage | 100% | 100% | ✅ |
| Test coverage (planned) | 90% | 80% | ✅ |
| Orphan items | 0 | 0 | ✅ |
| Constitution violations | 0 | 0 | ✅ |

---

## 8.1 Quality Metrics

| Metric | Value | Prompt Field |
|--------|-------|--------------|
| Generate-to-Review Ratio (G2R) | [e.g. 3.2:1] | [generated units] / [review interventions] |
| Intervention Rate | [e.g. 0.28] | [human interventions] / [execution cycles] |

Interpretation:
- G2R < 2:1 -> stabilization needed
- G2R 2:1 to < 4:1 -> acceptable
- G2R >= 4:1 -> strong flow (verify with gate quality)

---

## 9. Recommendations

### 9.1 Before Implementation

1. [ ] Add test case for EC-002 (empty list handling)
2. [ ] Consider adding AC for US-003 edge cases

### 9.2 During Implementation

1. [ ] Ensure test coverage ≥80%
2. [ ] Verify performance targets in staging

### 9.3 Before Ship

1. [ ] Complete accessibility testing
2. [ ] Verify all NFRs in production-like environment

---

## 10. Sign-off

**Analysis Status:** Ready for Gate 3 | Requires Attention

- [ ] All critical issues resolved: ✅
- [ ] Warnings acknowledged: ⏳
- [ ] Coverage acceptable: ✅

**Analyst:** [Name]
**Date:** [DATE]
