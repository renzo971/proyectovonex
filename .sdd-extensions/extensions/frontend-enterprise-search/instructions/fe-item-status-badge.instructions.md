---
applyTo: "src/pages/**/*"
---
# Item Status Badge Pattern

## Purpose

Standard pattern for rendering status values as color-coded badges using the Stratos `Badge` component.

## When to Use

Apply when:
- A status enum value must be displayed visually with a colored badge
- The status belongs to a specific feature domain
- The badge will be reused within the same feature (table cells, detail views)

## Naming Convention

Name the component after the **feature** it belongs to:

| Feature | Status Enum | Component | File |
|---------|-------------|-----------|------|
| InstructionsSearch | `InstructionSearchStatus` | `InstructionsSearchStatus` | `pages/instructions-search/InstructionsSearchStatus/` |
| SecuritiesSearch | `SecuritiesSearchStatus` | `SecuritiesSearchStatus` | `pages/securities-search/SecuritiesSearchStatus/` |

**Never** name it `CommonStatus` or `SharedBadge` — it is feature-scoped, not shared.

## Implementation

```tsx
import { Badge, BadgeColor } from '@dap-ui/stratos';
import type { FC } from 'react';

interface FeatureStatusProps {
  status: FeatureStatus;
}

const FeatureStatusBadge: FC<FeatureStatusProps> = ({ status }) => {
  const colorMap: Record<FeatureStatus, BadgeColor> = {
    [FeatureStatus.DRAFT]: BadgeColor.BLACK,
    [FeatureStatus.PENDING]: BadgeColor.ORANGE,
    [FeatureStatus.IN_REVIEW]: BadgeColor.BLUE,
    [FeatureStatus.APPROVED]: BadgeColor.GREEN,
    [FeatureStatus.REJECTED]: BadgeColor.RED,
  };

  return (
    <Badge
      label={t(`feature.statuses.${status}`)}
      color={colorMap[status]}
    />
  );
};
```

## Color Mapping Guidelines

| Status Meaning | Badge Color | Stratos Enum |
|---------------|-------------|--------------|
| Draft / Inactive | Gray/Black | `BadgeColor.BLACK` |
| Pending / Warning | Orange | `BadgeColor.ORANGE` |
| In Progress / Info | Blue | `BadgeColor.BLUE` |
| Success / Approved | Green | `BadgeColor.GREEN` |
| Error / Rejected | Red | `BadgeColor.RED` |

## File Structure

```
pages/<feature>/
  └── <Feature>StatusBadge/
      ├── <Feature>StatusBadge.tsx
      └── <Feature>StatusBadge.test.tsx
```

## Testing

```tsx
describe('FeatureStatusBadge', () => {
  it.each(Object.values(FeatureStatus))('renders badge for status %s', (status) => {
    render(<FeatureStatusBadge status={status} />);
    expect(screen.getByText(/* translated label */)).toBeInTheDocument();
  });
});
```
