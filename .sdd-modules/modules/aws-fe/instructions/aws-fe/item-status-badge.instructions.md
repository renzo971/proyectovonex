---
applyTo: "src/pages/**/*"
---
# Item Status Badge Pattern

## Overview

When a feature needs to render a status value as a colored badge (e.g., in a table column, detail panel, or list item), create a **feature-specific** status component using the Stratos `Badge` component with a `colorMap`.

---

## When to Use

Apply this pattern whenever:
- A status enum value must be displayed visually with a color-coded badge
- The status belongs to a specific feature domain (instructions, requests, settlements, etc.)
- The component will be reused within the same feature (table cells, detail views, etc.)

---

## Naming Convention

Name the component after the **feature (including Search suffix)** it belongs to, not generically:

| Feature (with Search suffix) | Status Enum | Component Name | File |
|---|---|---|---|
| InstructionsSearch | `InstructionSearchStatus` | `InstructionsSearchStatus` | `src/pages/instructions-search/InstructionsSearchStatus/InstructionsSearchStatus.tsx` |
| SecuritiesSearch | `SecuritiesSearchStatus` | `SecuritiesSearchStatus` | `src/pages/securities-search/SecuritiesSearchStatus/SecuritiesSearchStatus.tsx` |

**Never name it `CommonStatus` or `CommonRequestStatus`** — it is not a shared component. Place it inside the feature's page folder.

---

## Implementation Pattern

```typescript
import { Badge, BadgeColor } from '@dap-ui/stratos';
import { useTranslate } from 'i18n';
import { InstructionSearchStatus } from 'models';
import type { FC } from 'react';

interface InstructionsSearchStatusProps {
  status: InstructionSearchStatus;
}

const InstructionsSearchStatus: FC<InstructionsSearchStatusProps> = ({ status }) => {
  const t = useTranslate();

  const colorMap: Record<InstructionSearchStatus, BadgeColor> = {
    [InstructionSearchStatus.DRAFT]: BadgeColor.BLACK,
    [InstructionSearchStatus.TO_BE_REVIEWED]: BadgeColor.ORANGE,
    [InstructionSearchStatus.PENDING_REVIEW]: BadgeColor.BLUE,
    [InstructionSearchStatus.APPROVED]: BadgeColor.GREEN,
    [InstructionSearchStatus.DISCARDED]: BadgeColor.RED,
  };

  return (
    <Badge
      label={t(`instructionSearch.statuses.${status}`)}
      color={colorMap[status]}
    />
  );
};

export default InstructionsSearchStatus;
```

---

## Usage in a Table Cell

When rendering the status inside a results table, wrap it in `HorizontalFlex` and guard against `null` with a short-circuit expression. TypeScript narrows `InstructionSearchStatus | null` to `InstructionSearchStatus` inside the `&&` block, so **no type cast is needed**:

```tsx
[InstructionsSearchListColumn.STATUS]: (
  <HorizontalFlex $justify="flex-start">
    {item.status && (
      <InstructionsSearchStatus
        status={item.status}
      />
    )}
  </HorizontalFlex>
),
```

For this narrowing to work without a cast, the model's `status` field must be typed as `InstructionSearchStatus | null`:

```typescript
export class InstructionsSearchListItem {
  // ...
  status: InstructionSearchStatus | null = null;
}
```

Do **not** cast the value (e.g. `status={item.status as InstructionSearchStatus}`). If TypeScript reports an error, fix the model type instead.

---

## Rules

1. **Feature-scoped**: The component lives inside the feature's page folder, not in `src/components/`.
2. **One component per status enum**: Each distinct status enum gets its own dedicated component.
3. **Exhaustive colorMap**: The `colorMap` must be typed as `Record<StatusEnum, BadgeColor>` and cover **all** enum values — TypeScript will error if any value is missing.
4. **Translated labels**: Always use `t(`instructionSearch.statuses.${status}`)` for the `label` prop. Add all keys to `src/i18n/en.json` under the `instructionSearch.statuses` namespace.
5. **No fallback color**: Do not use a fallback/default color. The exhaustive `Record` type ensures every value is handled at compile time.
6. **Single prop**: The component accepts only the `status` prop typed with the specific enum. Do not accept raw strings.

---

## Color Semantics

Use `BadgeColor` values consistently with their semantic meaning:

| BadgeColor | Semantic meaning |
|---|---|
| `BadgeColor.BLACK` | Neutral, Draft, Not initiated, Canceled |
| `BadgeColor.GREY` | Edit in progress, No action required |
| `BadgeColor.ORANGE` | Awaiting action, Needs correction |
| `BadgeColor.BLUE` | Ongoing, Pending, In progress |
| `BadgeColor.TEAL` | Secondary ongoing state |
| `BadgeColor.GREEN` | Done, Approved, Submitted, Completed |
| `BadgeColor.RED` | Discarded, Rejected, Error |

---

## i18n Keys

Add translation entries under the `instructionSearch.statuses` key in `src/i18n/en.json`:

```json
{
  "instructionSearch": {
    "statuses": {
      "DRAFT": "Draft",
      "TO_BE_REVIEWED": "To be reviewed",
      "PENDING_REVIEW": "Pending review",
      "APPROVED": "Approved",
      "DISCARDED": "Discarded"
    }
  }
}
```

The translation key must match the **exact string value** of the enum member.
