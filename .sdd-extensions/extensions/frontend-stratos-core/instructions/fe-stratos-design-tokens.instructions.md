---
applyTo: "**/*.{tsx,ts,jsx}"
---
# Stratos Design Tokens — Extension Instruction

## Purpose

Enforce consistent usage of Stratos design tokens across all frontend components. Never use raw CSS values when a Stratos token exists.

## Spacing — `Space` Enum

Always import `Space` from `@dap-ui/stratos` for gaps, padding, and margins.

| Token | Value | Use Cases |
|-------|-------|-----------|
| `Space.V2` | 2px | Tight inline spacing |
| `Space.V4` | 4px | Icon-to-text gaps |
| `Space.V8` | 8px | Default small gap |
| `Space.V12` | 12px | Form field internal padding |
| `Space.V16` | 16px | Standard card/section gap |
| `Space.V24` | 24px | Section breaks |
| `Space.V32` | 32px | Major section separation |
| `Space.V40` | 40px | Page-level padding |
| `Space.V56` | 56px | Hero/header spacing |
| `Space.V72` | 72px | Page top margins |

## Colors — `Color` Object

Use semantic color groups. Never hardcode hex values.

- **Neutrals:** `Color.Neutral.V00` (white) through `Color.Neutral.V100` (darkest)
- **Success:** `Color.SpringGreen.V10`–`V50`
- **Error:** `Color.Coral.V10`–`V50`
- **Info:** `Color.Ocean.V10`–`V50`
- **Warning:** `Color.Amber.V10`–`V50`

## Breakpoints — `Breakpoint` Enum

Use for responsive layouts in `HorizontalFlex`, `ResponsiveGrid`.

| Token | Pixels | Typical Use |
|-------|--------|-------------|
| `Breakpoint.S` | 576px | Mobile |
| `Breakpoint.M` | 768px | Tablet |
| `Breakpoint.L` | 992px | Desktop |
| `Breakpoint.XL` | 1200px | Wide desktop |
| `Breakpoint.XXL` | 1400px | Ultra-wide |

## Icon Sizes — `IconSize` Enum

| Token | Value | Use |
|-------|-------|-----|
| `IconSize.V12` | 12px | Inline indicators |
| `IconSize.V16` | 16px | Table/list icons |
| `IconSize.V18` | 18px | Button icons |
| `IconSize.V24` | 24px | Card/action icons |
| `IconSize.V32` | 32px | Feature/hero icons |

## Button Enums

- **Variant:** `ButtonVariant.PRIMARY`, `ButtonVariant.SECONDARY`, `ButtonVariant.GHOST`
- **Severity:** `ButtonSeverity.DEFAULT`, `ButtonSeverity.DANGER`
- **Size:** `ButtonSize.M` (default), `ButtonSize.S`, `ButtonSize.XS`

## Layout Primitives

Use `VerticalFlex`, `HorizontalFlex`, and `ResponsiveGrid` for all layout. Never use raw `div` with flexbox CSS when a Stratos layout component exists.

```tsx
// ✅ Correct
<VerticalFlex $gap={Space.V16}>
  <HorizontalFlex $gap={Space.V8} $breakpoint={Breakpoint.M} $wrap>
    <TextField label="Field A" value={a} onChange={setA} />
    <TextField label="Field B" value={b} onChange={setB} />
  </HorizontalFlex>
</VerticalFlex>

// ❌ Wrong — raw div with hardcoded style
<div style={{ display: 'flex', gap: '16px', flexDirection: 'column' }}>
```

## Typography

Use Stratos text components, not raw HTML headings.

| Component | Purpose |
|-----------|---------|
| `HeadingL` | Page titles |
| `HeadingM` | Section titles |
| `HeadingS` | Card/group titles |
| `BoldTextM/S` | Emphasized content |
| `MediumTextM/S` | Semi-bold labels |
| `RegularTextM/S` | Body text |

Optional `$tone` prop: `$tone={Color.Neutral.V50}` for secondary text.

## Enforcement

- Every PR/review must check: no raw CSS values where a Stratos token applies
- Agents generating code must import tokens, not guess pixel values
- When in doubt, use `Space.V16` as the default gap and `Color.Neutral.V50` as default secondary color
