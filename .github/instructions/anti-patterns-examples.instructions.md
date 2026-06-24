---
applyTo: "**/*"
description: Core before/after examples for anti-sycophancy, scope control, hallucination avoidance, and anti-anchoring
---

## Anti-Pattern Examples — Core Catalog

This catalog keeps the first four rules close to the always-on anti-pattern contract. Advanced examples for Rules 5-7 live in [anti-patterns-advanced-examples.instructions.md](anti-patterns-advanced-examples.instructions.md).

## Rule 1 — Anti-Sycophancy

- **Skipping security:** when asked to remove auth from an internal endpoint, cite the constitution conflict and offer service-to-service auth or an explicit override path.
- **Contradicting the spec:** when asked to make a required field optional, point to the affected AC and tests before proposing options.

## Rule 2 — Anti-Eager-Beaver

- **Scope creep:** do not replace a small utility request with a generalized framework.
- **Drive-by refactoring:** apply the bug fix only; leave adjacent validation changes for a separate task.

## Rule 3 — Anti-Hallucination

- **Invented APIs:** read the real service before calling methods or describing signatures.
- **Assumed dependencies:** check `package.json` or the equivalent dependency source before naming a library.

## Rule 4 — Anti-Anchoring

- **Copied NFR values:** derive targets from current business context, not a previous feature.
- **Copied test structure:** build test cases from current requirements, not a CRUD template.

## Application

Use this file for quick pattern matching during active work. Use the advanced companion when you need the full confidence, cleanup, or anti-agreement examples.

✅ **Correct — Start from this feature's requirements:**
```markdown
### TC-001: Notification dispatched on order completion (traces: US-005, AC-012)
### TC-002: Notification retried on delivery failure (traces: US-005, AC-013)
### TC-003: Duplicate notification suppressed within 5-minute window (traces: US-005, EC-003)
```

---

### Rule 5: Confidence Calibration — Examples

#### Example 5A: Unverified Assertions

❌ **Wrong — Stating facts without evidence:**
```
The payment service uses Stripe for processing.
Rate limiting is set to 1000 requests per minute.
The retry policy follows exponential backoff.
```

✅ **Correct — Confidence-rated findings:**
```
- Payment service uses Stripe SDK v3 [High — verified in package.json]
- Rate limit is 1000 req/min [Low — not specified in constitution or spec; industry default assumed]
- Retry policy follows exponential backoff [Medium — inferred from error-handling pattern in plan.md §3.2]

**Confidence Summary:** 1 High · 1 Medium · 1 Low — the Low finding needs human verification.
```

---

### Rule 6: Orphan Cleanup Precision — Examples

#### Example 6A: Import Cleanup After Refactoring

**User Request:** "Replace the `formatDate` helper with `dayjs`."

❌ **Wrong — Cleaning up pre-existing dead code:**
```diff
- import { formatDate } from './utils/date';
- import { legacyHelper } from './utils/legacy';  // Was already unused before this change!
- import { deprecatedLogger } from './logging';    // Also pre-existing dead code!
+ import dayjs from 'dayjs';
```

✅ **Correct — Only remove what YOUR change made unused:**
```diff
- import { formatDate } from './utils/date';     // YOUR change made this unused → remove
+ import dayjs from 'dayjs';
  import { legacyHelper } from './utils/legacy';  // Pre-existing → leave it
  import { deprecatedLogger } from './logging';    // Pre-existing → leave it
```
Note at end: "I noticed `legacyHelper` and `deprecatedLogger` appear unused — shall I remove them as a separate cleanup task?"

#### Example 6B: Function Cleanup

**User Request:** "Refactor `calculateTotal` to use the new pricing engine."

❌ **Wrong — Removing a helper that wasn't part of the change:**
```diff
  // YOUR refactoring target — correct to change
- function calculateTotal(items: Item[]): number {
-   return items.reduce((sum, item) => sum + item.price * item.qty, 0);
- }
+ function calculateTotal(items: Item[]): number {
+   return pricingEngine.computeTotal(items);
+ }

  // Pre-existing utility — NOT part of the request
- function formatItemLabel(item: Item): string {
-   return `${item.name} (x${item.qty})`;
- }
```

✅ **Correct:**
```diff
- function calculateTotal(items: Item[]): number {
-   return items.reduce((sum, item) => sum + item.price * item.qty, 0);
- }
+ function calculateTotal(items: Item[]): number {
+   return pricingEngine.computeTotal(items);
+ }

  // formatItemLabel stays — it wasn't part of the request
  function formatItemLabel(item: Item): string {
    return `${item.name} (x${item.qty})`;
  }
```

---

### Rule 7: Sycophantic Agreement — Examples

#### Example 7A: Agreeing to Add Cache Without Analysis

**User Request:** "Let's add Redis caching to fix the slow dashboard load."

❌ **Wrong — Agreeing without investigating the root cause:**
```
Great idea! I'll set up a Redis cache layer for the dashboard queries.
Here's the implementation plan:
1. Install ioredis
2. Add a cache wrapper around the dashboard query
3. Set TTL to 5 minutes
4. Invalidate on data changes
```

✅ **Correct — Challenge the assumption, investigate first:**
```
Before adding caching, have you identified what's causing the slow load?
Let me check the current query performance.

[reads the dashboard query and data model]

I found three potential causes:
1. The dashboard runs 12 separate queries (N+1 pattern) — consolidating
   into 2 queries could reduce load time by ~80%
2. The `transactions` table lacks an index on `created_at` — the filter
   scans 2M rows
3. The response payload is 4.2 MB — no pagination or field selection

Caching would mask these issues and add operational complexity (Redis
infra, invalidation bugs, stale data). I recommend fixing #1 and #2
first, then measuring again.

Shall I:
a) Fix the N+1 queries and add the missing index (likely sufficient)
b) Add Redis caching anyway (faster short-term, but masks root cause)
c) Profile the full request to get exact timing breakdown first
```

#### Example 7B: Agreeing to a Technology Choice Without Trade-Offs

**User Request:** "We should use GraphQL for the new API."

❌ **Wrong — Rubber-stamping the choice:**
```
GraphQL is a great choice! I'll set up Apollo Server with the schema.
```

✅ **Correct — Validate the choice with evidence:**
```
GraphQL can work well here, but let me evaluate it against the
requirements before committing:

The spec (US-012) describes 3 endpoints, all with fixed response
shapes and no client-driven field selection. The consumers are 2
internal services with stable contracts.

Trade-off analysis:
| Factor | GraphQL | REST |
|--------|---------|------|
| Client field selection | ✅ Flexible | ❌ Fixed |
| Schema complexity for 3 endpoints | ❌ Overhead | ✅ Minimal |
| Team familiarity (constitution §II) | ❌ New stack | ✅ Established |
| Caching | ❌ Complex (POST-based) | ✅ HTTP native |

Given fixed response shapes and 2 internal consumers, REST appears
simpler and better-aligned with team conventions. GraphQL adds value
when clients need flexible queries across many entities.

Do you have a specific requirement driving the GraphQL choice (e.g.,
future client flexibility, mobile app with bandwidth constraints)?
```

These examples accompany the rules in `anti-patterns.instructions.md`. When in doubt about whether your behavior matches a rule, find the most similar example here and follow the ✅ pattern.
