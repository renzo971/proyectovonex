---
applyTo: ".specify/**,.github/agents/**"
description: TDD enforcement rules — activated only when constitution.md sets tdd_mode to true
---

## TDD Enforcement Rules

These rules are **conditionally active**. Read `.specify/memory/constitution.md` and locate `tdd_mode` (Article V §5.5). If `tdd_mode: false` (default), rules are **informational only**. If `tdd_mode: true`, rules are **binding**.

---

### Rule TDD-1: Test-First Gate (Software Engineer — Never Do)

**Applies when:** `tdd_mode: true` AND the current task is an implementation task (T-prefix in `tasks.md`).

**Never Do:**
- Write or modify implementation source files before at least one failing test for the target
  behaviour exists in the test suite.
- Mark an implementation task as `[done]` if no corresponding test exists or if all existing
  tests pass trivially (without exercising the new code path).

**Required behavior:**
- Check for the existence of a test file or test case that maps to the task.
- If absent, pause and prompt the Test Engineer (or swap to test-writing mode) before coding.
- Record the test file path in the task note when implementation begins.

---

### Rule TDD-2: Stub-First Obligation (Test Engineer — Always Do)

**Applies when:** `tdd_mode: true` AND Gate 2 has just passed (design approved).

**Always Do:**
- For every task in `tasks.md`, generate a runnable (but initially failing) test stub with correct imports, framework syntax, and minimal failing assertion.
- Commit stubs to test directory before any implementation begins.
- Record stub locations in `test-cases.md` using the `[stub]` tag.

---

### Rule TDD-3: Gate 2 TDD Check (gate command)

**Applies when:** `tdd_mode: true`.

At Gate 2 (`sdd gate 2`), the gate runner must verify:
- At least one test stub exists for every implementation task listed in `tasks.md`.
- Missing stubs are reported as **blocking issues** (gate does not pass until resolved).

Run `sdd gate 2 --tdd` to enforce this check regardless of the constitution `tdd_mode` setting.
