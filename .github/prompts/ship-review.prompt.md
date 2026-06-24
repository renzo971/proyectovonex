---
description: Ship-readiness review — final quality gate before production
mode: agent
---

Run the **ship-readiness review** for the current feature.

Invoke `@review` to verify:

1. **Spec compliance** — every US/AC implemented and tested
2. **Code quality** — static analysis clean, no smells
3. **Test coverage** — meets constitution targets
4. **Security** — dependency audit, OWASP checklist
5. **Documentation** — specs up to date, code documented
6. **Performance** — load tests passed, no regressions
7. **Deployment readiness** — migrations, rollback plan, monitoring

Produces `ship-checklist.md` with one of four verdicts:
- **APPROVED** — ship it
- **APPROVED WITH CONDITIONS** — ship with caveats
- **CHANGES REQUIRED** — fix issues first
- **DO NOT SHIP** — major problems
