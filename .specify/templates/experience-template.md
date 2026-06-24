# Experience Template
<!-- sdd:section:experience -->

> **Wave 27 §26 #6** — FE design-contract EXPERIENCE spine.
> Scope: `std-fe` / `aws-fe` modules only (Constraint #8 tech-agnostic core unchanged).
> This file captures flows, states, IA, and a11y.
> Visual-identity values MUST be referenced as `{design-tokens.TOKEN_NAME}` — e.g., `{design-tokens.color.primary.default}`.
> Unresolved `{...}` references produce a WARN from `sdd extension doctor`.

---

## Meta

| Field | Value |
|-------|-------|
| Feature ID | `<!-- e.g. 001-payment-gateway -->` |
| Design tokens file | `<!-- path to design-tokens-template.md -->` |
| Author | `<!-- name -->` |
| Last updated | `<!-- YYYY-MM-DD -->` |
| Status | `draft` \| `approved` \| `shipped` |

---

## 1. Information Architecture

```
<!-- Outline the component/page hierarchy here -->
Page/Feature
├── Header
│   └── ...
├── Main content
│   ├── Section A
│   └── Section B
└── Footer / Actions
```

---

## 2. User Flows

### 2.1 Happy Path

```
Actor → [Trigger] → [Screen A] → [Action] → [Screen B] → [Outcome]
```

| Step | Actor | Action | System response |
|------|-------|--------|----------------|
| 1 | User | `<!-- describe trigger -->` | `<!-- describe response -->` |
| 2 | User | | |

### 2.2 Error Paths

| Trigger | Error state | Recovery |
|---------|------------|---------|
| `<!-- e.g. invalid input -->` | `<!-- error message / state -->` | `<!-- CTA / next step -->` |

### 2.3 Edge Cases

| Scenario | Expected behavior |
|----------|------------------|
| Empty state | `<!-- describe -->` |
| Loading state | `<!-- describe -->` |
| Timeout | `<!-- describe -->` |

---

## 3. Component States

| Component | State | Token reference | Notes |
|-----------|-------|----------------|-------|
| Primary button | default | `color: {design-tokens.color.primary.default}` | |
| Primary button | hover | `color: {design-tokens.color.primary.hover}` | |
| Primary button | disabled | `color: {design-tokens.color.text.disabled}` | |
| Form field | default | `border: {design-tokens.border.width.default} {design-tokens.color.neutral.border}` | |
| Form field | focus | `border: {design-tokens.border.width.focus} {design-tokens.color.primary.default}` | |
| Form field | error | `border: {design-tokens.border.width.focus} {design-tokens.color.feedback.error}` | |
| Card | default | `background: {design-tokens.color.neutral.surface}`, `shadow: {design-tokens.elevation.card}` | |

> Add additional components as needed. Every `{design-tokens.TOKEN}` reference MUST match an entry in the companion `design-tokens-template.md`.

---

## 4. Spacing & Layout

| Zone | Token reference | Notes |
|------|----------------|-------|
| Page outer padding | `{design-tokens.spacing.xl}` | |
| Card inner padding | `{design-tokens.spacing.lg}` | |
| Between form fields | `{design-tokens.spacing.md}` | |
| Inline icon + label gap | `{design-tokens.spacing.sm}` | |

---

## 5. Typography Mapping

| Element | Token reference | Notes |
|---------|----------------|-------|
| Page title | `{design-tokens.type.heading.h1}` | |
| Section heading | `{design-tokens.type.heading.h2}` | |
| Body text | `{design-tokens.type.body.default}` | |
| Form label | `{design-tokens.type.label.form}` | |
| Helper / caption | `{design-tokens.type.body.small}` | |

---

## 6. Accessibility (a11y)

| Requirement | Status | Notes |
|-------------|--------|-------|
| All interactive elements keyboard-reachable | `<!-- ✅ / ❌ / TBD -->` | |
| Focus order matches visual order | `<!-- -->` | |
| Color contrast ≥ 4.5:1 (body text) | `<!-- -->` | Uses `{design-tokens.color.text.primary}` on `{design-tokens.color.neutral.background}` |
| Color contrast ≥ 3:1 (large text / UI) | `<!-- -->` | |
| All icons have accessible label or `aria-hidden` | `<!-- -->` | |
| Error messages associated with inputs via `aria-describedby` | `<!-- -->` | |
| Loading states announced via `aria-live` or `role="status"` | `<!-- -->` | |
| No use of color alone to convey information | `<!-- -->` | |

---

## 7. Motion & Transitions

| Transition | Duration token | Easing token | Notes |
|------------|---------------|-------------|-------|
| Modal open/close | `{design-tokens.motion.duration.default}` | `{design-tokens.motion.easing.standard}` | |
| Button hover | `{design-tokens.motion.duration.fast}` | `{design-tokens.motion.easing.standard}` | |

---

## 8. Handoff Checklist (Gate 2 prerequisite)

- [ ] All §§ 1–7 sections filled (no `<!-- TBD -->` in a11y column)
- [ ] Every `{design-tokens.*}` reference resolves in the companion design-tokens file
- [ ] `sdd extension doctor` reports no unresolved-token WARNs
- [ ] A11y status column has no `TBD` entries
- [ ] Error paths cover all known input validation and network-failure cases
