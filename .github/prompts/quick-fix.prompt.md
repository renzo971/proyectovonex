---
description: Quick fix or hotfix — minimal-scope change with targeted testing
mode: agent
---

Apply a **quick fix** or **hotfix** with minimal scope.

## Steps

1. **Scope the fix**: Identify the exact issue, affected user stories (US-XXX),
   and acceptance criteria (AC-XXX) involved.

2. **Impact check**: Invoke `@analysis` to verify what artifacts are affected.
   - Which tests cover this area?
   - Which specs reference this behavior?

3. **Fix implementation**: Invoke `@software-engineer` in **IMPL mode**.
   - Fix the specific issue
   - Run existing tests to verify no regression

4. **Add missing tests**: If the bug reveals a test gap,
   invoke `@test-engineer` to add targeted tests.

5. **Quick review**: Invoke `@review` for a focused ship-readiness check.

> **Tip:** For a quick fix, you don't need to run the full pipeline.
> Focus on the affected code path and its tests.
