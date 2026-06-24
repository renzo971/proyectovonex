# Test Cases: [FEATURE_NAME]

**Feature ID:** [NNN]-[feature-slug]
**Created:** [DATE]
**Author:** [QA Engineer Name]
**Status:** Draft | Under Review | Approved

---

## 1. Test Strategy

### 1.1 Test Scope

| Test Type | Scope | Coverage Target |
|-----------|-------|-----------------|
| Unit Tests | Business logic, utilities | 80% |
| Integration Tests | API endpoints, database | Key paths |
| E2E Tests | Critical user flows | Happy paths + key errors |
| Contract Tests | API contracts | All endpoints |
| Performance Tests | Load scenarios | SLA validation |

### 1.2 Test Environment

| Environment | Purpose | Data |
|-------------|---------|------|
| Local | Development | Mocked |
| CI | Automated tests | Test fixtures |
| Staging | Integration | Anonymized prod |

### 1.3 Test Data Strategy

- **Fixtures:** `.specify/specs/[NNN]/test-data/`
- **Factories:** `tests/factories/`
- **Mocks:** External services mocked

---

## 2. Test Cases

### 2.1 User Story: US-001 - [Story Title]

#### TC-001: [Test Case Title]

| Attribute | Value |
|-----------|-------|
| **Type** | Unit / Integration / E2E / Contract |
| **Priority** | P1 (Critical) / P2 (High) / P3 (Medium) |
| **Automated** | Yes / No / Planned |
| **Traces To** | US-001, AC-001 |

**Preconditions:**
- [Precondition 1]
- [Precondition 2]

**Test Steps:**

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | [Action] | [Expected] |
| 2 | [Action] | [Expected] |
| 3 | [Action] | [Expected] |

**Test Data:**

```json
{
  "input": {
    "field1": "value1"
  },
  "expected": {
    "status": 200,
    "body": {}
  }
}
```

**Cleanup:**
- [Cleanup action if needed]

---

#### TC-002: [Test Case Title]

| Attribute | Value |
|-----------|-------|
| **Type** | Integration |
| **Priority** | P1 |
| **Traces To** | US-001, AC-002 |

**Given:** [Context/Precondition]
**When:** [Action performed]
**Then:** [Expected outcome]

**Test Data:**
- Input: [describe]
- Expected: [describe]

---

### 2.2 User Story: US-002 - [Story Title]

#### TC-003: [Test Case Title]

| Attribute | Value |
|-----------|-------|
| **Type** | E2E |
| **Priority** | P1 |
| **Traces To** | US-002, AC-004 |

**Given:** [Context]
**When:** [Action]
**Then:** [Expected]

---

#### TC-004: [Test Case Title]

| Attribute | Value |
|-----------|-------|
| **Type** | Unit |
| **Priority** | P2 |
| **Traces To** | US-002, AC-005 |

**Given:** [Context]
**When:** [Action]
**Then:** [Expected]

---

## 3. Edge Case Tests

### EC-001: [Edge Case from spec]

#### TC-005: [Edge Case Test Title]

| Attribute | Value |
|-----------|-------|
| **Type** | Unit |
| **Priority** | P2 |
| **Traces To** | EC-001 |

**Given:** [Edge condition]
**When:** [Action]
**Then:** [Expected handling]

---

## 4. Error Scenario Tests

### ERR-001: [Error from spec]

#### TC-006: [Error Scenario Test Title]

| Attribute | Value |
|-----------|-------|
| **Type** | Integration |
| **Priority** | P1 |
| **Traces To** | ERR-001 |

**Given:** [Error condition setup]
**When:** [Action that triggers error]
**Then:** 
- Error code: [expected code]
- User message: [expected message]
- System behavior: [expected logging/recovery]

---

## 5. Non-Functional Tests

### NFR-001: Performance

#### TC-007: Response Time Under Load

| Attribute | Value |
|-----------|-------|
| **Type** | Performance |
| **Priority** | P1 |
| **Traces To** | NFR-001 |

**Scenario:**
- Concurrent users: [N]
- Duration: [X minutes]
- Target: p95 < [Y]ms

**Metrics to Collect:**
- Response time (p50, p95, p99)
- Error rate
- Throughput

---

### NFR-002: Security

#### TC-008: Authentication Required

| Attribute | Value |
|-----------|-------|
| **Type** | Security |
| **Priority** | P1 |
| **Traces To** | NFR-002 |

**Given:** No authentication token
**When:** Request to protected endpoint
**Then:** 401 Unauthorized returned

---

## 6. Regression Test Suite

| Test ID | Description | Priority | Automated |
|---------|-------------|----------|-----------|
| TC-001 | [Brief description] | P1 | Yes |
| TC-002 | [Brief description] | P1 | Yes |
| TC-003 | [Brief description] | P1 | Yes |
| TC-006 | [Brief description] | P1 | Yes |

---

## 7. Test Coverage Matrix

| Requirement | Unit | Integration | E2E | Contract |
|-------------|------|-------------|-----|----------|
| US-001/AC-001 | TC-001 | TC-002 | - | - |
| US-001/AC-002 | TC-001 | TC-002 | - | - |
| US-002/AC-004 | - | - | TC-003 | - |
| US-002/AC-005 | TC-004 | - | - | - |
| EC-001 | TC-005 | - | - | - |
| ERR-001 | - | TC-006 | - | - |
| NFR-001 | - | - | - | TC-007 |
| NFR-002 | - | TC-008 | - | - |

---

## 8. Test Execution Plan

### 8.1 CI Pipeline

| Stage | Tests | Trigger |
|-------|-------|---------|
| Pre-commit | Unit tests | Local hook |
| PR | Unit + Integration | PR opened |
| Merge | Full suite | Merge to main |
| Nightly | E2E + Performance | Scheduled |

### 8.2 Manual Testing

| Test | When | Tester |
|------|------|--------|
| Accessibility | Before release | QA |
| Exploratory | Before release | QA + Dev |

---

## 9. Sign-off

- [ ] QA Lead: _________________ Date: _______
- [ ] Dev Lead: _________________ Date: _______
