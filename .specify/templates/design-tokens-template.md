# Design Tokens Template
<!-- sdd:section:design-tokens -->

> **Wave 27 §26 #6** — FE design-contract DESIGN spine.
> Scope: `std-fe` / `aws-fe` modules only (Constraint #8 tech-agnostic core unchanged).
> This file is the authoritative source for all visual-identity tokens.
> `experience-template.md` references tokens via `{path.to.token}` syntax.

---

## Meta

| Field | Value |
|-------|-------|
| Feature ID | `<!-- e.g. 001-payment-gateway -->` |
| Designer | `<!-- name -->` |
| Last updated | `<!-- YYYY-MM-DD -->` |
| Status | `draft` \| `approved` \| `shipped` |

---

## 1. Color Tokens

| Token name | Value / Reference | Usage |
|------------|------------------|-------|
| `color.primary.default` | `<!-- #hex or var(--...) -->` | Primary action, CTA |
| `color.primary.hover` | `<!-- -->` | Hover state on primary |
| `color.secondary.default` | `<!-- -->` | Secondary action |
| `color.neutral.background` | `<!-- -->` | Page / panel background |
| `color.neutral.surface` | `<!-- -->` | Card / modal surface |
| `color.neutral.border` | `<!-- -->` | Default border |
| `color.feedback.error` | `<!-- -->` | Error state |
| `color.feedback.warning` | `<!-- -->` | Warning state |
| `color.feedback.success` | `<!-- -->` | Success state |
| `color.feedback.info` | `<!-- -->` | Informational state |
| `color.text.primary` | `<!-- -->` | Primary text |
| `color.text.secondary` | `<!-- -->` | Secondary / helper text |
| `color.text.disabled` | `<!-- -->` | Disabled text |

## 2. Spacing Tokens

| Token name | Value | Usage |
|------------|-------|-------|
| `spacing.xs` | `<!-- 4px -->` | Inline tight spacing |
| `spacing.sm` | `<!-- 8px -->` | Component inner padding |
| `spacing.md` | `<!-- 16px -->` | Standard section gap |
| `spacing.lg` | `<!-- 24px -->` | Card / panel padding |
| `spacing.xl` | `<!-- 32px -->` | Section separation |

## 3. Typography Tokens

| Token name | Value | Usage |
|------------|-------|-------|
| `type.heading.h1` | `<!-- 28px / bold -->` | Page title |
| `type.heading.h2` | `<!-- 22px / semibold -->` | Section heading |
| `type.body.default` | `<!-- 14px / regular -->` | Body copy |
| `type.body.small` | `<!-- 12px / regular -->` | Caption, helper text |
| `type.label.form` | `<!-- 13px / medium -->` | Form field label |

## 4. Border & Radius Tokens

| Token name | Value | Usage |
|------------|-------|-------|
| `border.radius.sm` | `<!-- 4px -->` | Input, small button |
| `border.radius.md` | `<!-- 8px -->` | Card, modal |
| `border.radius.full` | `<!-- 9999px -->` | Pill badge, tag |
| `border.width.default` | `<!-- 1px -->` | Standard border |
| `border.width.focus` | `<!-- 2px -->` | Focus ring |

## 5. Motion Tokens

| Token name | Value | Usage |
|------------|-------|-------|
| `motion.duration.fast` | `<!-- 100ms -->` | Micro-interactions |
| `motion.duration.default` | `<!-- 200ms -->` | Standard transitions |
| `motion.easing.standard` | `<!-- ease-in-out -->` | Default easing |

## 6. Elevation / Shadow Tokens

| Token name | Value | Usage |
|------------|-------|-------|
| `elevation.card` | `<!-- 0 1px 4px rgba(0,0,0,.12) -->` | Card shadow |
| `elevation.modal` | `<!-- 0 4px 24px rgba(0,0,0,.18) -->` | Modal shadow |
| `elevation.dropdown` | `<!-- 0 2px 8px rgba(0,0,0,.14) -->` | Dropdown shadow |

---

## Token Governance

- All tokens in §§ 1–6 MUST have a `Token name` entry before engineering begins.
- `experience-template.md` MUST reference tokens using the exact names above.
- Unresolved `{...}` references in experience files produce a WARN from `sdd extension doctor`.
- Token values MAY be left as `<!-- TBD -->` during design; they MUST be filled before Gate 2.
