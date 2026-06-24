# Stratos Design System - Component Usage Instructions

## Overview

Stratos is a comprehensive React-based design system for building enterprise applications. This guide provides instructions for converting Figma designs into React components using the Stratos component library.

## Table of Contents

1. [Component Categories](#component-categories)
2. [Foundations](#foundations)
3. [Actions](#actions)
4. [Form Components](#form-components)
5. [Feedback Components](#feedback-components)
6. [Navigation Components](#navigation-components)
7. [Structure Components](#structure-components)
8. [Patterns](#patterns)
9. [Templates](#templates)
10. [Layout & Spacing](#layout--spacing)
11. [Common Patterns](#common-patterns)

---

## Component Categories

Stratos organizes components into the following categories:

- **Foundations**: Core design elements (colors, typography, icons, layout)
- **Actions**: Interactive elements (buttons, links)
- **Form**: Input and selection components
- **Feedback**: Status and notification components
- **Navigation**: Navigation and wayfinding components
- **Structure**: Page structure and data display components
- **Patterns**: Composite components for common use cases
- **Templates**: Complete page layouts

---

## Foundations

### Typography

Typography components for text rendering with consistent styling:

**Components:**
- `HeadingL` - Large heading
- `HeadingM` - Medium heading
- `HeadingS` - Small heading
- `BoldTextM` - Medium bold text
- `BoldTextS` - Small bold text
- `MediumTextM` - Medium weight text
- `MediumTextS` - Small medium weight text
- `RegularTextM` - Regular text
- `RegularTextS` - Small regular text

**Optional Props:**
- `$tone`: Color tone (e.g., `Color.Neutral.V50`)
- `$ellipsis`: Enable text truncation with ellipsis

**Example:**
```tsx
<HeadingL>Page Title</HeadingL>
<HeadingM $tone={Color.Neutral.V50}>Subtitle</HeadingM>
<RegularTextM>Body text content</RegularTextM>
```

### Label

Inline plain-text label for annotating neighbouring controls or sections.

**Required Props:**
- `content`: Label text or `ReactNode`

**Optional Props:**
- `id`, `className`, `qa`: Standard HTML attributes

**Example:**
```tsx
<Label content="Search for:" />

// With ReactNode
<Label content={<><BoldTextS>Note:</BoldTextS> required field</>} />
```

### Layout Components

**VerticalFlex** - Stack elements vertically

Props:
- `$gap`: Space between items (e.g., `Space.V8`, `Space.V16`, `Space.V24`)
- `$align`: 'flex-start' | 'center' | 'flex-end' | 'stretch'
- `$justify`: 'flex-start' | 'center' | 'flex-end' | 'space-between'
- `$pad`, `$padX`, `$padY`: Padding values
- `$grow`: Enable flex-grow
- `$shrink`: Enable flex-shrink
- `$reverse`: Reverse direction

**HorizontalFlex** - Align elements horizontally

Props:
- `$gap`, `$gapX`, `$gapY`: Space between items
- `$align`: Vertical alignment
- `$justify`: Horizontal alignment
- `$wrap`: Enable wrapping
- `$breakpoint`: Breakpoint for responsive behavior (e.g., `Breakpoint.S`, `Breakpoint.M`)
- `$pad`, `$padX`, `$padY`: Padding values

**ResponsiveGrid** - Responsive grid layout

Props:
- `$s`, `$m`, `$l`, `$xl`, `$xxl`: Grid template for each breakpoint (e.g., `"repeat(3, 1fr)"`)
- `$gap`: Gap between grid items
- `$align`: Align items

**Example:**
```tsx
<VerticalFlex $gap={Space.V16}>
  <HeadingM>Section Title</HeadingM>
  <HorizontalFlex $gap={Space.V8} $breakpoint={Breakpoint.S} $wrap>
    <Button label="Action 1" onClick={handler} />
    <Button label="Action 2" onClick={handler} />
  </HorizontalFlex>
</VerticalFlex>

<ResponsiveGrid $l="repeat(3, 1fr)" $gap={Space.V16}>
  <TextField value={value1} label="Field 1" onChange={handler} />
  <TextField value={value2} label="Field 2" onChange={handler} />
  <TextField value={value3} label="Field 3" onChange={handler} />
</ResponsiveGrid>
```

### Icons

Icons are React components that can be used throughout the application.

**Common Icons:**
- `AddIcon`, `CloseIcon`, `DeleteIcon`, `EditIcon`
- `SearchIcon`, `FilterIcon`, `SortIcon`
- `CheckIcon`, `ErrorIcon`, `WarningIcon`, `InformationFilledIcon`
- `ChevronDownIcon`, `ChevronUpIcon`, `ChevronLeftIcon`, `ChevronRightIcon`
- `ArrowDownIcon`, `ArrowUpIcon`, `ArrowLeftIcon`, `ArrowRightIcon`
- Many more available...

**Icon Sizes:**
- `IconSize.V16`, `IconSize.V20`, `IconSize.V24`, `IconSize.V32`

**Example:**
```tsx
<AddIcon size={IconSize.V24} />
```

### Colors

Access design system colors through the `Color` object:

**Color Groups:**
- `Color.Neutral.V00` to `Color.Neutral.V100`
- `Color.SpringGreen.V10` to `Color.SpringGreen.V50`
- `Color.Coral.V10` to `Color.Coral.V50`
- `Color.Ocean.V10` to `Color.Ocean.V50`
- `Color.Amber.V10` to `Color.Amber.V50`

### Spacing

Use the `Space` enum for consistent spacing:
- `Space.V4`, `Space.V8`, `Space.V12`, `Space.V16`, `Space.V24`, `Space.V32`, etc.

### Breakpoints

Responsive breakpoints:
- `Breakpoint.S`, `Breakpoint.M`, `Breakpoint.L`, `Breakpoint.XL`, `Breakpoint.XXL`

---

## Actions

### Button

Primary interactive component for user actions.

**Figma Mapping:** Look for rectangular elements with labels like "Primary action", "Secondary", "Cancel", etc.

**Required Props:**
- `label`: Button text
- `onClick`: Click handler

**Optional Props:**
- `variant`: `ButtonVariant.PRIMARY` (default) | `ButtonVariant.SECONDARY` | `ButtonVariant.GHOST`
- `severity`: `ButtonSeverity.NORMAL` (default) | `ButtonSeverity.DANGER`
- `size`: `ButtonSize.M` (default) | `ButtonSize.S` | `ButtonSize.XS`
- `leftIcon`: Icon component to display before label
- `rightIcon`: Icon component to display after label
- `disabled`: Boolean to disable the button
- `type`: 'button' (default) | 'submit'
- `title`: Tooltip text
- `autoFocus`: Boolean
- `qa`: Test identifier
- `id`, `className`: Standard HTML attributes

**Example:**
```tsx
<Button 
  label="Create New" 
  leftIcon={AddIcon}
  onClick={handleCreate} 
/>

<Button 
  label="Delete" 
  variant={ButtonVariant.SECONDARY}
  severity={ButtonSeverity.DANGER}
  onClick={handleDelete} 
/>

<Button 
  label="Cancel" 
  variant={ButtonVariant.GHOST}
  onClick={handleCancel} 
/>
```

### IconButton

Button with only an icon, no label.

**Required Props:**
- `icon`: Icon component
- `title`: Tooltip/accessibility text
- `onClick`: Click handler

**Optional Props:**
- Same as Button (variant, severity, size, disabled, etc.)

**Example:**
```tsx
<IconButton 
  icon={EditIcon} 
  title="Edit" 
  size={ButtonSize.XS}
  onClick={handleEdit} 
/>
```

### Link

Styled hyperlink component.

**Required Props:**
- `label`: Link text
- `onClick` or `href`: Navigation handler

**Optional Props:**
- `href`: URL for navigation
- `leftIcon`, `rightIcon`: Icons
- `disabled`: Boolean
- `qa`, `id`, `className`

**Example:**
```tsx
<Link 
  label="View details" 
  rightIcon={ArrowRightIcon}
  onClick={handleViewDetails} 
/>
```

### ActionMenu

A popover menu that renders a list of labelled actions. The trigger element is fully controlled via the `getTrigger` render-prop, giving complete flexibility over what opens the menu (e.g., a ghost `Button` with a chevron icon).

**Required Props:**
- `options`: `ActionMenuOption[]` — each item is `{ label: string; onClick: () => void }`
- `getTrigger`: `({ open: boolean; updateOpen: (open: boolean) => void }) => ReactNode` — renders the trigger element

**Optional Props:**
- `size`: `PopoverSize.XS` | `PopoverSize.S` | `PopoverSize.M` | `PopoverSize.L` — controls popover width
- `id`, `className`, `qa`: Standard HTML attributes

**Example:**
```tsx
const options: ActionMenuOption[] = [
  { label: 'Edit', onClick: handleEdit },
  { label: 'Duplicate', onClick: handleDuplicate },
  { label: 'Delete', onClick: handleDelete },
];

<ActionMenu
  options={options}
  size={PopoverSize.XS}
  getTrigger={({ open, updateOpen }) => (
    <Button
      label="Actions"
      rightIcon={open ? ChevronUpIcon : ChevronDownIcon}
      variant={ButtonVariant.GHOST}
      onClick={() => updateOpen(!open)}
    />
  )}
/>
```

---

## Form Components

### TextField

Single-line text input with label and validation support.

**Figma Mapping:** Text input boxes with labels, typically rectangular with border.

**Required Props:**
- `value`: Current value
- `onChange`: Handler function `(value: string) => void`

**Optional Props:**
- `label`: Label text (ReactNode for complex labels with tooltips)
- `placeholder`: Placeholder text
- `disabled`: Boolean
- `required`: Boolean (shows asterisk)
- `max`: Maximum character length
- `regExp`: Regular expression for validation
- `variant`: `FieldVariant.NORMAL` (default) | `FieldVariant.COMPACT`
- `prefix`: ReactElement to display before input
- `suffix`: ReactElement to display after input
- `action`: Action element (e.g., button)
- `caption`: Validation/help messages (see Caption section)
- `elementRef`: React ref
- `tabIndex`: Tab order
- `id`, `className`, `qa`: Standard attributes

**Example:**
```tsx
const [value, setValue] = useState('');

<TextField
  value={value}
  label={
    <>
      Email Address
      <Tooltip content="Enter your email" title="Help" />
    </>
  }
  placeholder="Enter email"
  required
  caption={singleCaption({ help: 'We will never share your email' })}
  onChange={setValue}
/>

// With error
<TextField
  value={value}
  label="Username"
  caption={singleCaption({ error: 'Username is required' })}
  onChange={setValue}
/>
```

### NumberField

Numeric input field with optional formatting.

Similar to TextField but specialized for numbers.

**Example:**
```tsx
<NumberField
  value={quantity}
  label="Quantity"
  min={0}
  max={100}
  onChange={setQuantity}
/>
```

### Textarea

Multi-line text input.

**Required Props:**
- `value`: Current value
- `onChange`: Handler function

**Optional Props:**
- Similar to TextField
- `rows`: Number of visible rows
- `maxLength`: Maximum character count

**Example:**
```tsx
<Textarea
  value={description}
  label="Description"
  placeholder="Enter description"
  rows={4}
  maxLength={500}
  onChange={setDescription}
/>
```

### Select

Dropdown selection component.

**Figma Mapping:** Dropdown menus with single selection.

**Required Props:**
- `value`: Selected value
- `options`: Array of `DropdownOption` objects
- `onChange`: Handler function `(value: string) => void`

**DropdownOption Interface:**
```tsx
{
  label: string;
  value: string;
  icon?: IconComponent;
  iconTone?: Color;
  disabled?: boolean;
}
```

**Optional Props:**
- `label`: Field label
- `placeholder`: Placeholder text
- `disabled`: Boolean
- `required`: Boolean
- `variant`: `FieldVariant.NORMAL` | `FieldVariant.COMPACT`
- `emptyLabel`: Text when no options available
- `filterPlaceholder`: Search placeholder
- `createLabel`: Label for create action
- `onCreate`: Handler for creating new option
- `caption`: Validation/help messages
- `id`, `className`, `qa`

**Example:**
```tsx
const options = [
  { label: 'Option 1', value: 'opt1' },
  { label: 'Option 2', value: 'opt2' },
  { label: 'Option 3', value: 'opt3', icon: CheckIcon }
];

<Select
  value={selectedValue}
  options={options}
  label="Choose an option"
  placeholder="Select one"
  emptyLabel="No options available"
  filterPlaceholder="Search options"
  onChange={setSelectedValue}
/>
```

### MultiSelect

Multi-value selection dropdown.

Similar to Select but allows multiple selections.

**Example:**
```tsx
<MultiSelect
  value={selectedValues} // string[]
  options={options}
  label="Select multiple"
  onChange={setSelectedValues}
/>
```

### Search

Autocomplete search component with async data loading.

**Figma Mapping:** Fields that contain a magnifying glass / lens icon (inside or adjacent), or whose label/placeholder contains words like "search", "find", or "type to search". Also applies to autocomplete fields that load options dynamically as the user types.

**Required Props:**
- `value`: Selected value (string)
- `options`: Array of `DropdownOption` or `EntryModel` objects
- `onChange`: Handler function `(value: string) => void`
- `onSearch`: Async search handler `(searchKey: string) => void | Promise<void>`

**Optional Props:**
- `display`: Display text for selected value (if different from value)
- `label`: Field label
- `placeholder`: Placeholder text
- `disabled`: Boolean
- `required`: Boolean
- `loading`: Boolean loading state during search
- `emptyLabel`: Text when no options found
- `loaderTitle`: Loading indicator text
- `clearTitle`: Clear button accessibility text
- `variant`: `FieldVariant.NORMAL` | `FieldVariant.COMPACT`
- `caption`: Validation/help messages
- `id`, `className`, `qa`

**Key Differences from Select:**
- **Async**: Options are loaded dynamically via `onSearch` callback
- **Minimum Characters**: Always guard `onSearch` to trigger only when input has ≥ 3 characters; clear options otherwise
- **Display vs Value**: Can show different text (`display`) than internal `value`
- **Loading State**: Built-in loading indicator via `loading` prop
- **Search Trigger**: Calls `onSearch` as user types

**Complete Example:**

```tsx
import { Search, ToastContext } from '@dap-ui/stratos';
import { searchSecuritiesAccountOwnerBicAPI } from 'api';
import { AxiosError } from 'axios';
import { useTranslate } from 'i18n';
import { EntryModel, FeatureSearchModel, FeatureOptionModel } from 'models';
import { FC, useContext, useState } from 'react';

export interface FeatureSearchFieldProps {
  selected: FeatureOptionModel | null;
  handleChange: (update: Partial<FeatureSearchModel>) => void;
}

const FeatureSearchField: FC<FeatureSearchFieldProps> = ({
  selected,
  handleChange,
}) => {
  const t = useTranslate();
  const [options, setOptions] = useState<EntryModel[]>([]);
  const [loading, setLoading] = useState(false);
  const { showErrorToast } = useContext(ToastContext);

  const handleSearch = async(searchKey: string) => {
    if (searchKey.length < 3) {
      setOptions([]);
      return;
    }

    try {
      setLoading(true);
      const newOptions = await searchSecuritiesAccountOwnerBicAPI(searchKey);
      setOptions(newOptions);
    } catch (error) {
      const errorResponse = (error as AxiosError)?.response;
      const errorMessage = t(`apiErrors.${errorResponse?.status}.text`, t('common.genericErrorText'));
      showErrorToast(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Search
      value={selected?.value || ''}
      display={selected?.label}
      label={t('attributes.fields.securitiesAccountOwnerBic')}
      options={options}
      placeholder={t('common.searchPlaceholder')}
      loading={loading}
      emptyLabel={t('common.noData')}
      loaderTitle={t('common.loading')}
      clearTitle={t('common.clearButton')}
      onChange={value => {
        const securitiesAccountOwnerBic = options.find(o => o.value === value)!;
        handleChange({ securitiesAccountOwnerBic });
      }}
      onSearch={handleSearch}
    />
  );
};

export default FeatureSearchField;
```

**Pattern Breakdown:**

1. **Minimum Characters**: Guard at the start of `handleSearch` — clear options and return early if input is fewer than 3 characters
2. **State Management**: Maintain local state for `options` and `loading`
3. **Error Handling**: Use `ToastContext` to show errors from API calls
4. **Async Search**: `handleSearch` fetches options from API only when input has ≥ 3 characters
5. **Loading State**: Set `loading` true during API call, false in finally block
6. **Value Selection**: Find selected object from options array in `onChange`
7. **Display Value**: Use `display` prop to show label, `value` for internal state

**⚠️ MANDATORY FOLDER RULE — Separate Folder Required (Search only):**

> **This rule applies exclusively to the `Search` component. No other Stratos component (e.g., `Select`, `TextField`, `DateField`, `RangeField`) requires its own dedicated folder or file.**

Every `Search` component usage **MUST** be extracted into its own dedicated folder containing the component file and its test file, exactly as shown in the complete example above. **NEVER** inline a `Search` component directly inside a parent component (e.g., a form, section, or page).

| Rule | Detail |
|------|--------|
| One folder per Search field | Each `Search` instance lives in its own `[Feature]Search[FieldName]/` folder (e.g., `SecuritiesSearchCfi/`, `SecuritiesSearchIsin/`) |
| Folder naming convention | `[Feature]Search[FieldName]` — the folder name is also the component name and file name (e.g., `SecuritiesSearchCfi/SecuritiesSearchCfi.tsx`) |
| Test file co-location | The test file lives inside the same folder: `[Feature]Search[FieldName]/[Feature]Search[FieldName].test.tsx` |
| Props interface | Export a `[Feature]Search[FieldName]Props` interface with `selected` and `handleChange` |
| Local state only | `options` and `loading` state must be managed inside the Search field file |
| Error handling | `ToastContext` usage for API errors stays inside the Search field file |
| Parent responsibility | The parent component only passes the selected value and a change handler — it never manages search options or loading state |

**Folder structure example:**
```
src/pages/feature/
├── FeatureSearchCfi/
│   ├── FeatureSearchCfi.tsx
│   └── FeatureSearchCfi.test.tsx
├── FeatureSearchIsin/
│   ├── FeatureSearchIsin.tsx
│   └── FeatureSearchIsin.test.tsx
└── FeatureForm/
    └── FeatureForm.tsx   ← imports from sibling folders, never inlines Search
```

> This rule exists because the `Search` component requires local state management (`options`, `loading`), async search logic, and error handling that would bloat and clutter the parent component. Isolating each `Search` field into its own dedicated folder keeps components small, testable, and aligned with the project's file-size and isolation guidelines.
>
> All other form components (`Select`, `TextField`, `NumberField`, `DateField`, `RangeField`, `Checkbox`, etc.) must **not** be extracted into separate files or folders — they should be used inline inside the parent form or section component.

**When to Use Search vs Select:**
- **Use Search**: When options come from an API based on user input (e.g., searching users, locations, BIC codes)
- **Use Select**: When you have a fixed, pre-loaded list of options (e.g., statuses, categories)

**Mandatory Identification Rules — Use `Search` when ANY of the following is true:**

| Signal | Examples |
|--------|---------|
| Label contains a search keyword | "Search BIC", "Search counterparty", "Find account" |
| Placeholder contains a search keyword | "Search...", "Type to search", "Search by name" |
| A magnifying glass / lens icon is inside or adjacent to the field | `SearchIcon` rendered as prefix, suffix, or standalone icon next to the input |
| The mockup/screenshot shows a field with a lens icon | Regardless of how the label reads |
| The HTML mockup contains `type="search"` or a `SearchIcon` sibling | Inspect provided HTML for these attributes or sibling icon components |

> If the above signals are absent but the options are loaded dynamically from an API, still use `Search` over `Select`.

### Checkbox

Checkbox input with label.

**Figma Mapping:** Square checkboxes, often in groups.

**Required Props:**
- `value`: Boolean state
- `onChange`: Handler function `(value: boolean) => void`

**Optional Props:**
- `label`: Label text
- `disabled`: Boolean
- `required`: Boolean
- `caption`: Help/error messages
- `id`, `className`, `qa`

**Example:**
```tsx
<Checkbox
  value={isChecked}
  label="I agree to terms and conditions"
  required
  onChange={setIsChecked}
/>
```

### RadioButton

Radio button input for mutually exclusive options.

**Required Props:**
- `value`: Boolean state
- `onChange`: Handler function

**Optional Props:**
- `label`: Label text
- `disabled`: Boolean
- `id`, `className`, `qa`

**Example:**
```tsx
<VerticalFlex $gap={Space.V8}>
  <RadioButton
    value={selectedOption === 'option1'}
    label="Option 1"
    onChange={() => setSelectedOption('option1')}
  />
  <RadioButton
    value={selectedOption === 'option2'}
    label="Option 2"
    onChange={() => setSelectedOption('option2')}
  />
</VerticalFlex>
```

### Switch

Toggle switch component.

**Required Props:**
- `value`: Boolean state
- `onChange`: Handler function

**Optional Props:**
- `label`: Label text
- `disabled`: Boolean
- `id`, `className`, `qa`

**Example:**
```tsx
<Switch
  value={isEnabled}
  label="Enable notifications"
  onChange={setIsEnabled}
/>
```

### DateField

Date picker component **for selecting a single date only**.

> **🚫 RESTRICTION — Single dates only.** `DateField` must NEVER be used to build a date range by placing two `DateField` components side by side. If you need a from/to, start/end, or min/max date pair, you MUST use [`RangeField`](#rangefield) instead. See the [RangeField section](#rangefield) for full details and examples.

**Required Props:**
- `value`: Date value (ISO string)
- `toggleMenuTitle`: Accessibility label for the calendar toggle button
- `prevMonthTitle`: Accessibility label for previous-month navigation
- `nextMonthTitle`: Accessibility label for next-month navigation
- `prevYearTitle`: Accessibility label for previous-year navigation
- `nextYearTitle`: Accessibility label for next-year navigation
- `onChange`: Handler function `(value: string) => void`

**Optional Props:**
- `label`: Field label
- `placeholder`: Placeholder text
- `disabled`: Boolean
- `required`: Boolean
- `variant`: Field variant
- `constraint`: Date boundaries (`DateConstraint`)
- `caption`: Validation/help messages
- `menuLocale`: Locale for the calendar menu
- `elementRef`: Ref to the input element
- `tabIndex`: Tab index
- `className`, `id`, `qa`
- `onFocus`, `onBlur`: Focus/blur event handlers

**Example:**
```tsx
<DateField
  value={value}
  label={props.label || 'Label'}
  disabled={props.disabled}
  required={props.required}
  variant={props.variant}
  constraint={props.constraint}
  toggleMenuTitle="Toggle the menu"
  prevMonthTitle="Previous month"
  nextMonthTitle="Next month"
  prevYearTitle="Previous year"
  nextYearTitle="Next year"
  caption={props.caption}
  id={Math.random().toString()}
  onChange={setValue}
/>
```

### RangeField

Date range picker component for selecting a start and end date in a single control.

**Figma Mapping:** Any date range input showing two date pickers (from/to, start/end, min/max) within a single labelled control.

**Required Props:**
- `value`: Object `{ from: string; to: string }` — ISO date strings, empty string when unset
- `label`: Field label
- `fromPlaceholder`: Placeholder text for the start date input
- `toPlaceholder`: Placeholder text for the end date input
- `prevMonthTitle`: Accessibility label for previous-month navigation
- `nextMonthTitle`: Accessibility label for next-month navigation
- `prevYearTitle`: Accessibility label for previous-year navigation
- `nextYearTitle`: Accessibility label for next-year navigation
- `toggleMenuTitle`: Accessibility label for the calendar toggle button
- `onChange`: Handler function `({ from, to }: { from: string; to: string }) => void`

**Optional Props:**
- `constraint`: `{ minDate?: string; maxDate?: string }` — ISO date string boundaries
- `disabled`: Boolean
- `required`: Boolean
- `caption`: Validation/help messages
- `qa`: Test identifier
- `id`, `className`

**⚠️ MANDATORY USAGE**: Always use `RangeField` (never two separate `DateField` components) when:
- Field names are clearly related pairs: `from`/`to`, `start`/`end`, `min`/`max`, or similar
- Both fields represent dates (ISO string type)
- The fields describe a date range or interval (e.g., `intendedSettlementDateFrom`/`intendedSettlementDateTo`, `tradeDateFrom`/`tradeDateTo`)

**Complete Example:**

```tsx
import { RangeField, singleCaption } from '@dap-ui/stratos';

<RangeField
  value={{
    from: searchData.tradeDateFrom,
    to: searchData.tradeDateTo,
  }}
  label={t('attributes.fields.tradeDate')}
  fromPlaceholder={t('common.from')}
  toPlaceholder={t('common.to')}
  prevMonthTitle={t('common.prevMonth')}
  nextMonthTitle={t('common.nextMonth')}
  prevYearTitle={t('common.prevYear')}
  nextYearTitle={t('common.nextYear')}
  toggleMenuTitle={t('common.toggleMenu')}
  caption={singleCaption({
    help: t('instructionSearchTab.dateHelpText'),
  })}
  qa="trade-date"
  onChange={({ from, to }) => handleChange({
    tradeDateFrom: from,
    tradeDateTo: to,
  })}
/>
```

**With Date Constraint (e.g., limit past dates to 3 months):**

```tsx
const date = new Date();
date.setMonth(date.getMonth() - 3);
const minDate = dateToString(date);

<RangeField
  value={{
    from: searchData.actualSettlementDateFrom,
    to: searchData.actualSettlementDateTo,
  }}
  label={t('attributes.fields.actualSettlementDate')}
  constraint={{ minDate }}
  fromPlaceholder={t('common.from')}
  toPlaceholder={t('common.to')}
  prevMonthTitle={t('common.prevMonth')}
  nextMonthTitle={t('common.nextMonth')}
  prevYearTitle={t('common.prevYear')}
  nextYearTitle={t('common.nextYear')}
  toggleMenuTitle={t('common.toggleMenu')}
  qa="actual-settlement-date"
  onChange={({ from, to }) => handleChange({
    actualSettlementDateFrom: from,
    actualSettlementDateTo: to,
  })}
/>
```

**Key Points:**
- `value.from` and `value.to` are ISO date strings; use empty string `''` for unset state (matches the `SearchModel` date field pattern)
- Both fields are updated together via a single `onChange` callback — destructure `{ from, to }` and map to the two model fields
- Use `constraint.minDate` / `constraint.maxDate` to restrict selectable dates (compute dynamically when needed)
- Use `dateToString` helper from `helpers` to convert `Date` objects to ISO strings for the constraint
- Always provide all five accessibility title props (`prevMonthTitle`, `nextMonthTitle`, `prevYearTitle`, `nextYearTitle`, `toggleMenuTitle`)

### Caption System

The caption system provides consistent validation and help messages.

**Helper Function:**
```tsx
singleCaption({ 
  help?: string;
  error?: string;
  warning?: string;
})
```

**Multiple Messages:**
```tsx
{
  errors: string[];
  warnings: string[];
  help: string;
  errorsLabel: string;
  warningsLabel: string;
  closeTitle: string;
  fieldLabel: string;
}
```

**Example:**
```tsx
// Single error
caption={singleCaption({ error: 'This field is required' })}

// Single warning
caption={singleCaption({ warning: 'Value seems unusual' })}

// Help text
caption={singleCaption({ help: 'Enter your full name' })}

// Multiple errors
caption={{
  errors: ['Field is required', 'Must be at least 8 characters'],
  warnings: [],
  help: '',
  errorsLabel: 'Errors',
  warningsLabel: 'Warnings',
  closeTitle: 'Close',
  fieldLabel: 'Password'
}}
```

---

## Feedback Components

### Banner (Notification)

Display important messages at the top of a page or section.

**Required Props:**
- `text`: Message text
- `variant`: `NotifyVariant.INFO` | `NotifyVariant.WARNING` | `NotifyVariant.ERROR` | `NotifyVariant.SUCCESS`

**Optional Props:**
- `title`: Optional title
- `showMoreLabel`, `showLessLabel`: For expandable content
- `onClose`: Close handler
- `actions`: Action buttons

**Example:**
```tsx
<Notify
  text="Your changes have been saved successfully"
  variant={NotifyVariant.SUCCESS}
/>

<Notify
  text="Warning: This action cannot be undone"
  variant={NotifyVariant.WARNING}
  showMoreLabel="Show more"
  showLessLabel="Show less"
/>
```

### Toast

Temporary notification that appears and dismisses automatically.

**Required Props:**
- `message`: Toast message
- `variant`: `ToastVariant.INFO` | `ToastVariant.SUCCESS` | `ToastVariant.WARNING` | `ToastVariant.ERROR`

**Optional Props:**
- `onClose`: Close handler
- `duration`: Auto-dismiss duration (ms)

**Example:**
```tsx
<Toast
  message="Item deleted successfully"
  variant={ToastVariant.SUCCESS}
/>
```

### Tooltip

Hover tooltip for additional information.

**Figma Mapping:** Small "i" icons or question marks near labels.

**Required Props:**
- `content`: Tooltip content
- `title`: Accessibility title

**Optional Props:**
- `children`: Trigger element (defaults to info icon)

**Example:**
```tsx
<Tooltip
  content="This is helpful information"
  title="More info"
/>

// In a label
<Label
  content={
    <>
      Field Name
      <Tooltip content="Additional help" title="Help" />
    </>
  }
/>
```

### Loader

Loading spinner indicator.

**Optional Props:**
- `size`: `LoaderSize.S` | `LoaderSize.M` (default) | `LoaderSize.L`
- `label`: Loading text

**Example:**
```tsx
<Loader label="Loading data..." />
```

### Progress Indicators

**ProgressBar** - Linear progress indicator

**Required Props:**
- `value`: Current progress (0-100)

**Optional Props:**
- `label`: Progress label
- `variant`: Display variant

**Example:**
```tsx
<ProgressBar value={75} label="75% complete" />
```

### Badge

Compact label component for displaying status, categories, or metadata. Supports icons, colors, sizes, and two appearance variants.

**Required Props (at least one of):**
- `label`: Badge text
- `leftIcon`: Icon component displayed on the left
- `rightIcon`: Icon component displayed on the right (at least one of `label`, `leftIcon`, or `rightIcon` is required)

**Optional Props:**
- `title`: Accessible title / tooltip text (used when displaying icon-only badges)
- `appearance`: `BadgeAppearance.CONTAINED` (default) | `BadgeAppearance.STANDALONE`
- `color`: `BadgeColor.BLACK` | `BadgeColor.GREY` | `BadgeColor.ORANGE` | `BadgeColor.BLUE` | `BadgeColor.TEAL` | `BadgeColor.GREEN` | `BadgeColor.RED` | `BadgeColor.WHITE`
- `size`: `BadgeSize.DEFAULT` (default) | `BadgeSize.COMPACT`

**Color Semantic Mapping:**
| Color | Typical Use Cases |
|-------|-------------------|
| `BadgeColor.BLACK` | Neutral, Draft, Not initiated, Canceled |
| `BadgeColor.GREY` | Edit in progress, No action required |
| `BadgeColor.ORANGE` | Awaiting action, New comment |
| `BadgeColor.BLUE` | Ongoing (1) |
| `BadgeColor.TEAL` | Ongoing (2) |
| `BadgeColor.GREEN` | Done, Completed, Approved, Validated |
| `BadgeColor.RED` | Aborted, Error, Rejected, Failed, Not signed |
| `BadgeColor.WHITE` | Custom badge |

**Example:**
```tsx
import { Badge, BadgeAppearance, BadgeColor, BadgeSize, Tooltip } from '@dap-ui/stratos';

// Default contained badge with label and icons
<Badge
  label="In Progress"
  color={BadgeColor.BLUE}
  leftIcon={SomeIcon}
/>

// Standalone appearance
<Badge
  label="Completed"
  appearance={BadgeAppearance.STANDALONE}
  color={BadgeColor.GREEN}
/>

// Compact size
<Badge
  label="Draft"
  size={BadgeSize.COMPACT}
  color={BadgeColor.BLACK}
  leftIcon={SomeIcon}
  rightIcon={SomeIcon}
/>

// Icon-only badge (use title for accessibility)
<Badge
  title="Status icon"
  leftIcon={SomeIcon}
/>

// With tooltip wrapper
<Tooltip content="Informative content" title="Show informative content">
  <Badge
    label="Tooltip"
    leftIcon={SomeIcon}
    rightIcon={SomeIcon}
  />
</Tooltip>
```

### Status Components

**StatusBadge** - Display status with badge

**Required Props:**
- `label`: Status text
- `variant`: Status type

**Example:**
```tsx
<StatusBadge label="Active" variant={StatusVariant.SUCCESS} />
<StatusBadge label="Pending" variant={StatusVariant.WARNING} />
```

### Chips

Small, compact elements for tags or filters.

**StaticChip** - Non-interactive chip

**Required Props:**
- `label`: Chip text

**Optional Props:**
- `icon`: Leading icon
- `color`: Background color

**Example:**
```tsx
<StaticChip label="Tag 1" />
<StaticChip label="Important" color={Color.Coral.V10} />
```

---

## Navigation Components

### Breadcrumb

Hierarchical navigation trail.

**Figma Mapping:** Horizontal list of links separated by chevrons or slashes.

**Required Props:**
- `items`: Array of `BreadcrumbItemModel`

**BreadcrumbItemModel:**
```tsx
{
  label: string;
  onClick?: () => void;
}
```

**Example:**
```tsx
const breadcrumbItems = [
  { label: 'Home', onClick: () => navigate('/') },
  { label: 'Products', onClick: () => navigate('/products') },
  { label: 'Details', onClick: () => navigate('/products/123') }
];

<Breadcrumb items={breadcrumbItems} />
```

### Tabs

Tabbed interface for switching between views.

**Required Props:**
- `tabs`: Array of tab objects
- `activeTab`: Currently active tab index
- `onChange`: Tab change handler

**Example:**
```tsx
<Tabs
  tabs={[
    { label: 'Overview' },
    { label: 'Details' },
    { label: 'History' }
  ]}
  activeTab={activeTabIndex}
  onChange={setActiveTabIndex}
/>
```

### Pagination

Page navigation for lists or tables.

**Required Props:**
- `page`: Current page (1-based)
- `totalPages`: Total number of pages
- `onChange`: Page change handler

**Optional Props:**
- `pageLabel`: Label for page indicator
- `prevLabel`, `nextLabel`: Navigation button labels

**Example:**
```tsx
<Pagination
  page={currentPage}
  totalPages={totalPages}
  pageLabel="Page"
  prevLabel="Previous"
  nextLabel="Next"
  onChange={setCurrentPage}
/>
```

### Stepper

Step-by-step progress indicator.

**Figma Mapping:** Horizontal line with numbered steps.

**Required Props:**
- `steps`: Array of step objects
- `activeStep`: Current active step index (1-based)

**Step Object:**
```tsx
{
  label: string;
  onClick?: () => void;
}
```

**Example:**
```tsx
<Stepper
  steps={[
    { label: 'Personal Info' },
    { label: 'Address' },
    { label: 'Payment' },
    { label: 'Confirmation' }
  ]}
  activeStep={2}
/>
```

### BackLink

Navigation link to return to previous page.

**Required Props:**
- `label`: Link text
- `onClick` or `href`: Navigation handler

**Example:**
```tsx
<BackLink label="Back to list" onClick={() => navigate(-1)} />
```

---

## Structure Components

### Modal

Dialog/modal window overlay.

**Figma Mapping:** Overlays with title, content, and action buttons.

**Required Props:**
- `title`: Modal title
- `body`: Modal content (ReactNode)
- `closeTitle`: Accessibility text for close button

**Optional Props:**
- `footer`: Footer content (typically buttons)
- `size`: `ModalSize.S` | `ModalSize.M` (default) | `ModalSize.L` | `ModalSize.XL`
- `noPadding`: Remove default body padding
- `onClose`: Close handler (also shows close button)
- `id`, `className`, `qa`

**Example:**
```tsx
<Modal
  title="Confirm Delete"
  body={
    <RegularTextM>
      Are you sure you want to delete this item? This action cannot be undone.
    </RegularTextM>
  }
  footer={
    <HorizontalFlex $justify="flex-end" $gap={Space.V8}>
      <Button 
        label="Cancel" 
        variant={ButtonVariant.SECONDARY}
        onClick={handleClose} 
      />
      <Button 
        label="Delete" 
        severity={ButtonSeverity.DANGER}
        onClick={handleDelete} 
      />
    </HorizontalFlex>
  }
  closeTitle="Close"
  onClose={handleClose}
/>
```

### Table

Data table with rows and columns.

**Figma Mapping:** Grid layouts with headers and data rows.

**Components:**
- `TableScroller` - Scrollable container
- `TableSectionTitle` - Section header
- `TableTitle` - Table title row
- `TableHead` - Column headers
- `TableBody` - Table rows

**TableHeadingModel:**
```tsx
{
  content: ReactNode;
  width?: number;
  align?: 'flex-start' | 'center' | 'flex-end' | 'stretch';
  breakpoint?: Breakpoint;
  sticky?: 'left' | 'right';
}
```

**TableRowModel:**
```tsx
{
  key: string;
  cells: TableCellModel[];
  onClick?: () => void;
  selected?: boolean;
}
```

**TableCellModel:**
```tsx
{
  content: ReactNode;
  width?: number;
  align?: 'flex-start' | 'center' | 'flex-end' | 'stretch';
}
```

**Example:**
```tsx
const headings = [
  { content: 'Name' },
  { content: 'Status', width: 150 },
  { content: 'Actions', width: 100, align: 'flex-end' }
];

const rows = [
  {
    key: 'row-1',
    cells: [
      { content: 'Item 1' },
      { content: <StatusBadge label="Active" variant={StatusVariant.SUCCESS} /> },
      { 
        content: (
          <HorizontalFlex $justify="flex-end">
            <IconButton icon={EditIcon} title="Edit" onClick={handleEdit} />
          </HorizontalFlex>
        )
      }
    ]
  }
];

<TableScroller>
  <TableTitle>
    <HeadingS>Data Table</HeadingS>
  </TableTitle>
  <TableHead headings={headings} />
  <TableBody rows={rows} />
</TableScroller>
```

### List

Alternative to table for simpler data display.

Similar structure to Table but with different styling.

**Example:**
```tsx
<ListScroller>
  <ListHead headings={headings} />
  <ListBody rows={rows} />
</ListScroller>
```

### Accordion

Expandable/collapsible content sections.

**Required Props:**
- `title`: Section title
- `children`: Content to show/hide

**Optional Props:**
- `expanded`: Control expansion state
- `onChange`: Expansion change handler

**Example:**
```tsx
<Accordion title="Advanced Settings">
  <VerticalFlex $gap={Space.V16}>
    <TextField value={setting1} label="Setting 1" onChange={setSetting1} />
    <TextField value={setting2} label="Setting 2" onChange={setSetting2} />
  </VerticalFlex>
</Accordion>
```

### Summary

Summary view with key-value pairs.

**Required Props:**
- `items`: Array of summary items

**Item Format:**
```tsx
{
  label: string;
  value: ReactNode;
}
```

**Example:**
```tsx
<Summary
  items={[
    { label: 'Total Items', value: '45' },
    { label: 'Active', value: '32' },
    { label: 'Pending', value: '13' }
  ]}
/>
```

### Filters

Filter panel for data tables/lists.

**Required Props:**
- `children`: Filter controls

**Optional Props:**
- `onApply`: Apply filters handler
- `onClear`: Clear filters handler

**Example:**
```tsx
<Filters onApply={handleApply} onClear={handleClear}>
  <Select 
    value={statusFilter} 
    options={statusOptions}
    label="Status"
    onChange={setStatusFilter} 
  />
  <DateField 
    value={dateFilter}
    label="Date"
    onChange={setDateFilter} 
  />
</Filters>
```

### SearchTrigger

A controlled text input with a built-in magnifying glass icon and a clear (`×`) button. It fires its `onChange` callback on every keystroke and calls it with an empty string when the user clicks the clear button. It has no internal state, no dropdown, and no autocomplete — it is purely a presentation component that delegates all logic to the parent.

**⚠️ WHEN TO USE:** Never infer or assume this component from a Figma design. Only use `SearchTrigger` when:
- The user explicitly requests it by name, or
- Another instruction file requires it as part of a defined implementation pattern

**Required Props:**
- `value`: Current string value (controlled)
- `onChange`: Handler `(value: string) => void` — called on every keystroke and on clear

**Optional Props:**
- `placeholder`: Placeholder text
- `clearTitle`: Accessibility label for the clear button
- `disabled`: Boolean
- `qa`: Test identifier

**Behavior:**
- Renders a text input preceded by a `SearchIcon`
- The clear button appears only when `value` is non-empty; clicking it calls `onChange('')`
- Does **not** debounce internally — the parent is responsible for throttling any expensive reactions to `onChange`
- Does **not** manage focus, history, or suggestions

**Usage Scenarios:**

This component is always paired with an `ActionMenu` for criteria selection and wrapped in a dedicated `FeatureSearches` component. There are two scenarios depending on context:

| Scenario | Behaviour |
|----------|-----------|
| **List page** | Updates Redux state **and** triggers a debounced data reload via `reloadData` prop |
| **Filter form** | Updates Redux state **only** — no data reload (the form's submit button triggers the search) |

---

#### Scenario 1 — List page (Redux + debounced reload)

```tsx
// FeatureSearches.tsx — part of a list page, reloads data with debounce

import type { ActionMenuOption } from '@dap-ui/stratos';
import {
  ActionMenu,
  Breakpoint,
  Button,
  ButtonVariant,
  ChevronDownIcon,
  ChevronUpIcon,
  HorizontalFlex,
  Label,
  PopoverSize,
  SearchTrigger,
  Space,
  useDebounce,
} from '@dap-ui/stratos';
import { useTranslate } from 'i18n';
import type { FeatureReloader } from 'models';
import { FeatureSearchCriteria } from 'models';
import type { FC } from 'react';
import { selectFeatureState, updateSearch } from 'store/feature/slice';
import { useAppDispatch, useAppSelector } from 'store/types';

export interface FeatureSearchesProps {
  reloadData: FeatureReloader;
}

const FeatureSearches: FC<FeatureSearchesProps> = ({ reloadData }) => {
  const t = useTranslate();
  const { search } = useAppSelector(selectFeatureState);
  const dispatch = useAppDispatch();
  const debounceReloadData = useDebounce(reloadData, 0.3);

  const criteriaLabel = t(`feature.columns.${search.searchCriteria}`);

  const handleChange = (searchKey: string, searchCriteria: FeatureSearchCriteria) => {
    const newSearch = {
      ...search,
      searchKey,
      searchCriteria,
    };

    dispatch(updateSearch(newSearch));
    debounceReloadData(newSearch);
  };

  const searchOptions = Object.values(FeatureSearchCriteria).map(value => ({
    label: t(`feature.columns.${value}`),
    value,
    onClick: () => handleChange(search.searchKey, value),
  } as ActionMenuOption));

  return (
    <HorizontalFlex
      $gapX={Space.V32}
      $gapY={Space.V4}
      $breakpoint={Breakpoint.S}
    >
      <SearchTrigger
        value={search.searchKey}
        placeholder={
          t(
            'common.searchCriteriaPlaceholder',
            undefined,
            { criteriaLabel }
         )
        }
        clearTitle={t('common.clearButton')}
        onChange={searchKey => handleChange(searchKey, search.searchCriteria)}
      />

      <HorizontalFlex $gap={Space.V16} $shrink>
        <Label content={t('common.searchForLabel')} />

        <ActionMenu
          options={searchOptions}
          size={PopoverSize.XS}
          getTrigger={({ open, updateOpen }) => (
            <Button
              label={criteriaLabel}
              rightIcon={open ? ChevronUpIcon : ChevronDownIcon}
              variant={ButtonVariant.GHOST}
              onClick={() => updateOpen(!open)}
            />
          )}
        />
      </HorizontalFlex>
    </HorizontalFlex>
  );
};

export default FeatureSearches;
```

---

#### Scenario 2 — Filter form (Redux only, no reload)

```tsx
// FeatureSearches.tsx — part of a filter/search form, updates Redux state only

import type { ActionMenuOption } from '@dap-ui/stratos';
import {
  ActionMenu,
  Breakpoint,
  Button,
  ButtonVariant,
  ChevronDownIcon,
  ChevronUpIcon,
  HorizontalFlex,
  Label,
  PopoverSize,
  SearchTrigger,
  Space,
} from '@dap-ui/stratos';
import { useTranslate } from 'i18n';
import { FeatureSearchCriteria } from 'models';
import type { FC } from 'react';
import { selectFeatureState, updateSearch } from 'store/feature/slice';
import { useAppDispatch, useAppSelector } from 'store/types';

const FeatureSearches: FC = () => {
  const t = useTranslate();
  const { search } = useAppSelector(selectFeatureState);
  const dispatch = useAppDispatch();

  const criteriaLabel = t(`feature.columns.${search.searchCriteria}`);

  const handleChange = (searchKey: string, searchCriteria: FeatureSearchCriteria) => {
    dispatch(updateSearch({ ...search, searchKey, searchCriteria }));
  };

  const searchOptions = Object.values(FeatureSearchCriteria).map(value => ({
    label: t(`feature.columns.${value}`),
    value,
    onClick: () => handleChange(search.searchKey, value),
  } as ActionMenuOption));

  return (
    <HorizontalFlex
      $gapX={Space.V32}
      $gapY={Space.V4}
      $breakpoint={Breakpoint.S}
    >
      <SearchTrigger
        value={search.searchKey}
        placeholder={
          t(
            'common.searchCriteriaPlaceholder',
            undefined,
            { criteriaLabel }
          )
        }
        clearTitle={t('common.clearButton')}
        onChange={searchKey => handleChange(searchKey, search.searchCriteria)}
      />

      <HorizontalFlex $gap={Space.V16} $shrink>
        <Label content={t('common.searchForLabel')} />

        <ActionMenu
          options={searchOptions}
          size={PopoverSize.XS}
          getTrigger={({ open, updateOpen }) => (
            <Button
              label={criteriaLabel}
              rightIcon={open ? ChevronUpIcon : ChevronDownIcon}
              variant={ButtonVariant.GHOST}
              onClick={() => updateOpen(!open)}
            />
          )}
        />
      </HorizontalFlex>
    </HorizontalFlex>
  );
};

export default FeatureSearches;
```

---

### Paper & PaperHeader

Container components for grouping content.

**Paper** - Card-like container
**PaperHeader** - Header section within Paper

**Example:**
```tsx
<Paper>
  <PaperHeader>
    <HeadingM>Section Title</HeadingM>
  </PaperHeader>
  <Padder $pad={Space.V24}>
    {/* Content */}
  </Padder>
</Paper>
```

---

## Patterns

### Card

Content card component for displaying grouped information.

**Figma Mapping:** Rectangular containers with borders/shadows, containing images, titles, and text.

**Components:**
- `Card` - Main container
- `CardBody` - Content area
- `CardTitle` - Title section
- `CardImage` - Optional image
- `CardTagLine` - Tag list
- `CardBadge` - Badge overlay
- `CardFooter` - Footer section
- `ClickableCard` - Clickable variant
- `ComposableCard` - Flexible composition

**Props:**
- Card: `$variant` - `CardVariant.ELEVATED` (default) | `CardVariant.OUTLINED`
- CardImage: `src`, `alt`, `$size` - `CardImageSize.SMALL` | `CardImageSize.MEDIUM` | `CardImageSize.LARGE`
- CardBadge: `$position` - `CardBadgePosition.LEFT` | `CardBadgePosition.RIGHT`

**Example:**
```tsx
<Card>
  <CardBody>
    <CardTitle>
      <CardImage 
        src="/image.png" 
        alt="Description"
        $size={CardImageSize.SMALL} 
      />
      <VerticalFlex $gap={Space.V4}>
        <HeadingM>Card Title</HeadingM>
        <CardTagLine tags={['Tag 1', 'Tag 2']} />
      </VerticalFlex>
    </CardTitle>
    <RegularTextM>
      Card description text goes here.
    </RegularTextM>
  </CardBody>
  <CardFooter>
    <Button label="Action" onClick={handleAction} />
  </CardFooter>
</Card>

// Clickable card
<ClickableCard onClick={handleClick}>
  <CardBody>
    <HeadingM>Clickable Card</HeadingM>
    <RegularTextM>Click anywhere on this card</RegularTextM>
  </CardBody>
</ClickableCard>
```

### EmptyState

Display when no content is available.

**Figma Mapping:** Centered illustrations/icons with text and optional action buttons.

**Required Props:**
- `title`: Main title
- `description`: Descriptive text

**Optional Props:**
- `actions`: Action buttons (ReactNode)
- `illustration`: Custom illustration

**Example:**
```tsx
<EmptyState
  title="No items found"
  description="There are no items to display. Create your first item to get started."
  actions={
    <Button 
      label="Create Item" 
      leftIcon={AddIcon}
      onClick={handleCreate} 
    />
  }
/>
```

### FormExtra

Additional form sections (help, related info).

**Required Props:**
- `children`: Content

**Example:**
```tsx
<FormExtra>
  <HeadingS>Additional Information</HeadingS>
  <RegularTextS>
    This information will help you complete the form correctly.
  </RegularTextS>
</FormExtra>
```

### BulkActions

Actions bar for selected items in lists/tables.

**Required Props:**
- `selectedCount`: Number of selected items
- `actions`: Action buttons
- `variant`: `BulkActionsVariant.TABLE` | `BulkActionsVariant.LIST`

**Optional Props:**
- `onClear`: Clear selection handler

**Example:**
```tsx
<BulkActions
  selectedCount={selectedItems.length}
  variant={BulkActionsVariant.TABLE}
  actions={
    <HorizontalFlex $gap={Space.V8}>
      <Button label="Delete" onClick={handleBulkDelete} />
      <Button label="Export" onClick={handleBulkExport} />
    </HorizontalFlex>
  }
  onClear={handleClearSelection}
/>
```

### ValidationComments

Comments/feedback system for validation workflows.

**Required Props:**
- `items`: Array of validation comments

**Example:**
```tsx
<ValidationComments
  items={[
    {
      author: 'John Doe',
      date: '2024-01-15',
      comment: 'Please review section 2',
      status: 'pending'
    }
  ]}
/>
```

### SearchCriteria

A composite pattern that pairs a `SearchTrigger` text input with an `ActionMenu` criteria selector. The user types a search term while choosing which attribute to search by via a ghost `Button` that opens a compact `ActionMenu` popover. The active criteria label is displayed on the button and the chevron icon reflects the open/closed state of the menu.

**Components:**
- `SearchTrigger` — Controlled text input for the search term (see [SearchTrigger](#searchtrigger))
- `ActionMenu` — Popover menu listing all searchable criteria as clickable options
- `Label` — Plain inline label (e.g. "Search for:")
- `Button` (ghost variant) — Renders the active criteria label and a chevron; acts as the `ActionMenu` trigger

**ActionMenu Props:**
- `options`: Array of `ActionMenuOption` objects `{ label: string; onClick: () => void }`
- `size`: `PopoverSize.XS` | `PopoverSize.S` | `PopoverSize.M` | `PopoverSize.L`
- `getTrigger`: Render-prop `({ open, updateOpen }) => ReactNode` — renders the trigger element; use `open` to swap chevron icons

**Label Props:**
- `content`: Label text or `ReactNode`

**Complete Example:**

```tsx
export enum CriteriaExample {
  TYPE_1 = 'Type 1',
  TYPE_2 = 'Type 2',
  TYPE_3 = 'Type 3',
}

const SearchCriteriaExample: FC = () => {
  const [criteria, setCriteria] = useState(CriteriaExample.TYPE_1);

  const searchOptions = Object.values(CriteriaExample).map(value => ({
    label: value,
    onClick: () => setCriteria(value as CriteriaExample),
  } as ActionMenuOption));

  return (
    <DocsContent>
      <HeadingL>
        Search criteria
      </HeadingL>

      <HorizontalFlex
        $gapX={Space.V32}
        $gapY={Space.V4}
        $breakpoint={Breakpoint.S}
      >
        <SearchTrigger
          value=""
          placeholder="Search for selected criteria"
          clearTitle="Clear"
          onChange={console.info}
        />

        <HorizontalFlex
          $gap={Space.V16}
          $shrink
        >
          <Label content="Search for:" />

          <ActionMenu
            options={searchOptions}
            size={PopoverSize.XS}
            getTrigger={({ open, updateOpen }) => (
              <Button
                label={criteria}
                rightIcon={open ? ChevronUpIcon : ChevronDownIcon}
                variant={ButtonVariant.GHOST}
                onClick={() => updateOpen(!open)}
              />
            )}
          />
        </HorizontalFlex>
      </HorizontalFlex>
    </DocsContent>
  );
};

export default SearchCriteriaExample;
```

**Pattern Breakdown:**

1. **Criteria enum**: Define an enum (or a `const` object) listing the available search criteria values; this is the single source of truth for both the `ActionMenu` options and the active-criteria state
2. **Local state**: `value` holds the current search text; `criteria` holds the active criteria selection — both are local `useState` values
3. **Options derivation**: Map `Object.values(criteriaEnum)` to `ActionMenuOption[]` — each option's `onClick` updates the `criteria` state
4. **SearchTrigger**: Bind its `value` to local state and call the parent `onSearch` handler (or any side-effect) from `onChange`
5. **ActionMenu trigger**: Use the `getTrigger` render-prop to render a ghost `Button` that shows the active criteria label; toggle `ChevronUpIcon` / `ChevronDownIcon` based on the `open` argument
6. **Layout**: Wrap in `HorizontalFlex` with `$breakpoint` so the trigger row wraps gracefully on small screens; use `$shrink` on the inner `HorizontalFlex` to keep the criteria selector compact

---

## Templates

### Page Header

Standard page header with breadcrumbs and title.

**Figma Mapping:** Top section of pages with navigation and title.

**Components:**
- Breadcrumb
- Paper with PaperHeader
- Stepper (for multi-step forms)

**Example - List Page:**
```tsx
<VerticalFlex $gap={Space.V12}>
  <Breadcrumb items={breadcrumbItems} />
  <Paper>
    <PaperHeader>
      <HorizontalFlex $justify="space-between">
        <HeadingL>Page Title</HeadingL>
        <Button 
          label="Create New" 
          leftIcon={AddIcon}
          onClick={handleCreate} 
        />
      </HorizontalFlex>
    </PaperHeader>
  </Paper>
</VerticalFlex>
```

**Example - Form Page:**
```tsx
<VerticalFlex $gap={Space.V12}>
  <Breadcrumb items={breadcrumbItems} />
  <Paper>
    <PaperHeader>
      <VerticalFlex $gap={Space.V16}>
        <HorizontalFlex $justify="space-between" $align="flex-start">
          <HorizontalFlex $gapX={Space.V12} $breakpoint={Breakpoint.M}>
            <HeadingL>Form Title</HeadingL>
            <VerticalSeparator $breakpoint={Breakpoint.M} />
            <HeadingL $tone={Color.Neutral.V50}>Subtitle</HeadingL>
          </HorizontalFlex>
          <CloseButton 
            title="Close" 
            size={IconSize.V32}
            onClick={handleClose} 
          />
        </HorizontalFlex>
        <Stepper
          steps={[
            { label: 'Step 1' },
            { label: 'Step 2' },
            { label: 'Step 3' }
          ]}
          activeStep={1}
        />
      </VerticalFlex>
    </PaperHeader>
  </Paper>
</VerticalFlex>
```

### Page Layouts

**LayoutBackground** - Root container with background color
**LayoutContainer** - Fixed-width content container

**Example:**
```tsx
<LayoutBackground>
  <LayoutContainer>
    {/* Page content */}
  </LayoutContainer>
</LayoutBackground>
```

---

## Common Patterns

### Form Layout

**Single Column Form:**
```tsx
<VerticalFlex $gap={Space.V16}>
  <TextField 
    value={field1} 
    label="Field 1" 
    required
    onChange={setField1} 
  />
  <TextField 
    value={field2} 
    label="Field 2" 
    onChange={setField2} 
  />
  <Select 
    value={field3} 
    options={options}
    label="Field 3"
    onChange={setField3} 
  />
  
  <HorizontalFlex $justify="flex-end" $gap={Space.V8}>
    <Button 
      label="Cancel" 
      variant={ButtonVariant.SECONDARY}
      onClick={handleCancel} 
    />
    <Button 
      label="Save" 
      type="submit"
      onClick={handleSave} 
    />
  </HorizontalFlex>
</VerticalFlex>
```

**Multi-Column Form:**
```tsx
<VerticalFlex $gap={Space.V16}>
  <ResponsiveGrid $l="repeat(2, 1fr)" $gap={Space.V16}>
    <TextField value={field1} label="First Name" onChange={setField1} />
    <TextField value={field2} label="Last Name" onChange={setField2} />
  </ResponsiveGrid>
  
  <ResponsiveGrid $l="repeat(3, 1fr)" $gap={Space.V16}>
    <TextField value={field3} label="City" onChange={setField3} />
    <TextField value={field4} label="State" onChange={setField4} />
    <TextField value={field5} label="Zip" onChange={setField5} />
  </ResponsiveGrid>
  
  <HorizontalFlex $justify="flex-end" $gap={Space.V8}>
    <Button label="Cancel" variant={ButtonVariant.SECONDARY} onClick={handleCancel} />
    <Button label="Save" onClick={handleSave} />
  </HorizontalFlex>
</VerticalFlex>
```

### Action Buttons Layout

**Right-aligned Actions:**
```tsx
<HorizontalFlex $justify="flex-end" $gap={Space.V8}>
  <Button label="Cancel" variant={ButtonVariant.SECONDARY} onClick={handleCancel} />
  <Button label="Save" onClick={handleSave} />
</HorizontalFlex>
```

**Space-between Actions:**
```tsx
<HorizontalFlex $justify="space-between">
  <Button label="Delete" severity={ButtonSeverity.DANGER} onClick={handleDelete} />
  <HorizontalFlex $gap={Space.V8}>
    <Button label="Cancel" variant={ButtonVariant.SECONDARY} onClick={handleCancel} />
    <Button label="Save" onClick={handleSave} />
  </HorizontalFlex>
</HorizontalFlex>
```

### List/Table with Actions

```tsx
<VerticalFlex $gap={Space.V16}>
  {/* Header with actions */}
  <HorizontalFlex $justify="space-between">
    <HeadingM>Items</HeadingM>
    <HorizontalFlex $gap={Space.V8}>
      <Button 
        label="Filter" 
        leftIcon={FilterIcon}
        variant={ButtonVariant.SECONDARY}
        onClick={handleFilter} 
      />
      <Button 
        label="Create" 
        leftIcon={AddIcon}
        onClick={handleCreate} 
      />
    </HorizontalFlex>
  </HorizontalFlex>
  
  {/* Table */}
  <TableScroller>
    <TableHead headings={headings} />
    <TableBody rows={rows} />
  </TableScroller>
  
  {/* Pagination */}
  <HorizontalFlex $justify="flex-end">
    <Pagination
      page={currentPage}
      totalPages={totalPages}
      onChange={setCurrentPage}
    />
  </HorizontalFlex>
</VerticalFlex>
```

### Tabs with Content

```tsx
const [activeTab, setActiveTab] = useState(0);

<VerticalFlex $gap={Space.V24}>
  <Tabs
    tabs={[
      { label: 'Overview' },
      { label: 'Details' },
      { label: 'History' }
    ]}
    activeTab={activeTab}
    onChange={setActiveTab}
  />
  
  {activeTab === 0 && <OverviewContent />}
  {activeTab === 1 && <DetailsContent />}
  {activeTab === 2 && <HistoryContent />}
</VerticalFlex>
```

### Loading States

```tsx
{isLoading ? (
  <Padder $pad={Space.V24}>
    <Loader label="Loading data..." />
  </Padder>
) : (
  <TableScroller>
    <TableHead headings={headings} />
    <TableBody rows={rows} />
  </TableScroller>
)}
```

### Empty States

```tsx
{items.length === 0 ? (
  <EmptyState
    title="No items found"
    description="Create your first item to get started"
    actions={
      <Button label="Create Item" leftIcon={AddIcon} onClick={handleCreate} />
    }
  />
) : (
  <TableScroller>
    <TableHead headings={headings} />
    <TableBody rows={rows} />
  </TableScroller>
)}
```

---

## Figma to Component Mapping Guide

### Visual Elements → Components

| Figma Element | Stratos Component | Notes |
|--------------|-------------------|-------|
| Large heading text | `HeadingL` | Page titles |
| Medium heading text | `HeadingM` | Section titles |
| Small heading text | `HeadingS` | Subsection titles |
| Body text | `RegularTextM` | Regular content |
| Small text | `RegularTextS` | Captions, notes |
| Primary button | `Button` with `variant={ButtonVariant.PRIMARY}` | Main actions |
| Secondary button | `Button` with `variant={ButtonVariant.SECONDARY}` | Alternative actions |
| Ghost/text button | `Button` with `variant={ButtonVariant.GHOST}` | Tertiary actions |
| Icon button | `IconButton` | Actions with only icons |
| Text input | `TextField` | Single-line inputs |
| Text area | `Textarea` | Multi-line inputs |
| Dropdown | `Select` | Single selection |
| Multi-select dropdown | `MultiSelect` | Multiple selections |
| Search/Autocomplete field | `Search` | Async searchable dropdown |
| Checkbox | `Checkbox` | Boolean choices |
| Radio button | `RadioButton` | Mutually exclusive choices |
| Toggle switch | `Switch` | On/off states |
| Date picker | `DateField` | **Single date only** — NEVER use two DateFields for a range |
| Date range picker | `RangeField` | **⚠️ MANDATORY** for any from/to date pair — always use instead of two DateFields |
| Data table | `TableScroller` + `TableHead` + `TableBody` | Tabular data |
| Card | `Card` + `CardBody` | Grouped content |
| Modal/Dialog | `Modal` | Overlay dialogs |
| Notification banner | `Notify` | Page-level messages |
| Toast message | `Toast` | Temporary notifications |
| Tooltip icon | `Tooltip` | Help icons |
| Breadcrumb | `Breadcrumb` | Navigation trail |
| Tabs | `Tabs` | Tab navigation |
| Stepper | `Stepper` | Multi-step progress |
| Loading spinner | `Loader` | Loading states |
| Status badge | `StatusBadge` | Status indicators |
| Tag/Chip | `StaticChip` | Tags, labels |
| Empty state illustration | `EmptyState` | No content states |

### Layout Patterns

| Figma Layout | Stratos Implementation |
|-------------|----------------------|
| Vertical stack | `<VerticalFlex $gap={Space.V16}>` |
| Horizontal row | `<HorizontalFlex $gap={Space.V8}>` |
| Grid layout | `<ResponsiveGrid $l="repeat(3, 1fr)">` |
| Centered content | `<VerticalFlex $align="center" $justify="center">` |
| Space between | `<HorizontalFlex $justify="space-between">` |
| Wrapped items | `<HorizontalFlex $wrap>` |

### Spacing Guidelines

- Small gaps: `Space.V4`, `Space.V8`
- Medium gaps: `Space.V12`, `Space.V16`
- Large gaps: `Space.V24`, `Space.V32`
- Extra large gaps: `Space.V48`, `Space.V64`

---

## Best Practices

### 1. Consistent Spacing
Always use the `Space` enum for spacing values to maintain consistency.

### 2. Responsive Design
Use `ResponsiveGrid` and breakpoint props (`$breakpoint`) for responsive layouts.

### 3. Accessibility
- Always provide `label` props for form fields
- Use `title` props for icon buttons
- Include `alt` text for images
- Use semantic HTML elements

### 4. State Management
- Use React hooks (`useState`) for component state
- Lift state up when multiple components need access
- Use controlled components for form inputs

### 5. Error Handling
- Always show validation errors using the `caption` prop
- Use appropriate `variant` values for notifications
- Provide clear, actionable error messages

### 6. Loading States
- Show `Loader` component during async operations
- Disable buttons during form submission
- Use `disabled` prop to prevent duplicate actions

### 7. Empty States
- Always provide an `EmptyState` when lists/tables have no data
- Include helpful text and primary action

### 8. Action Buttons
- Primary action: `ButtonVariant.PRIMARY`
- Secondary actions: `ButtonVariant.SECONDARY`
- Destructive actions: `ButtonSeverity.DANGER`
- Tertiary actions: `ButtonVariant.GHOST`

### 9. Date Ranges
- **NEVER** use two separate `DateField` components to represent a date range
- **ALWAYS** use the `RangeField` component for any from/to, start/end, or min/max date pair
- This applies to all contexts: search forms, filters, detail forms, modals, etc.
- `RangeField` accepts `value={{ from, to }}` and fires a single `onChange({ from, to })` callback
- See the [RangeField](#rangefield) section for required props and examples

---

## Import Statement

All components are imported from the main library:

```tsx
import {
  // Layout
  VerticalFlex,
  HorizontalFlex,
  ResponsiveGrid,
  Space,
  
  // Typography
  HeadingL,
  HeadingM,
  RegularTextM,
  
  // Actions
  Button,
  ButtonVariant,
  ButtonSeverity,
  IconButton,
  
  // Form
  TextField,
  Select,
  Checkbox,
  
  // Icons
  AddIcon,
  EditIcon,
  DeleteIcon,
  
  // And all other components...
} from 'stratos';
```

---

## Component Composition Examples

### Complete Form Example

```tsx
import { useState } from 'react';
import {
  VerticalFlex,
  HorizontalFlex,
  ResponsiveGrid,
  Space,
  HeadingL,
  HeadingM,
  TextField,
  Select,
  Checkbox,
  Button,
  ButtonVariant,
  Paper,
  singleCaption,
} from 'stratos';

function UserForm() {
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [country, setCountry] = useState('');
  const [acceptTerms, setAcceptTerms] = useState(false);

  const countryOptions = [
    { label: 'United States', value: 'us' },
    { label: 'United Kingdom', value: 'uk' },
    { label: 'Canada', value: 'ca' },
  ];

  return (
    <Paper>
      <VerticalFlex $gap={Space.V24} $pad={Space.V24}>
        <HeadingL>User Information</HeadingL>
        
        <VerticalFlex $gap={Space.V16}>
          <HeadingM>Personal Details</HeadingM>
          
          <ResponsiveGrid $l="repeat(2, 1fr)" $gap={Space.V16}>
            <TextField
              value={firstName}
              label="First Name"
              placeholder="Enter first name"
              required
              onChange={setFirstName}
            />
            <TextField
              value={lastName}
              label="Last Name"
              placeholder="Enter last name"
              required
              onChange={setLastName}
            />
          </ResponsiveGrid>
          
          <TextField
            value={email}
            label="Email Address"
            placeholder="email@example.com"
            required
            caption={singleCaption({ help: 'We will never share your email' })}
            onChange={setEmail}
          />
          
          <Select
            value={country}
            options={countryOptions}
            label="Country"
            placeholder="Select country"
            required
            emptyLabel="No countries available"
            filterPlaceholder="Search countries"
            onChange={setCountry}
          />
          
          <Checkbox
            value={acceptTerms}
            label="I accept the terms and conditions"
            required
            onChange={setAcceptTerms}
          />
        </VerticalFlex>
        
        <HorizontalFlex $justify="flex-end" $gap={Space.V8}>
          <Button
            label="Cancel"
            variant={ButtonVariant.SECONDARY}
            onClick={() => console.log('Cancel')}
          />
          <Button
            label="Save"
            disabled={!acceptTerms}
            onClick={() => console.log('Save')}
          />
        </HorizontalFlex>
      </VerticalFlex>
    </Paper>
  );
}
```

### Complete Table Example

```tsx
import { useState } from 'react';
import {
  VerticalFlex,
  HorizontalFlex,
  Space,
  HeadingM,
  Button,
  ButtonVariant,
  IconButton,
  ButtonSize,
  TableScroller,
  TableHead,
  TableBody,
  Pagination,
  StatusBadge,
  StatusVariant,
  AddIcon,
  EditIcon,
  DeleteIcon,
  FilterIcon,
} from 'stratos';

function UsersList() {
  const [currentPage, setCurrentPage] = useState(1);
  const totalPages = 10;

  const headings = [
    { content: 'Name' },
    { content: 'Email' },
    { content: 'Status', width: 150 },
    { content: 'Actions', width: 100, align: 'flex-end' },
  ];

  const rows = [
    {
      key: 'user-1',
      cells: [
        { content: 'John Doe' },
        { content: 'john@example.com' },
        { content: <StatusBadge label="Active" variant={StatusVariant.SUCCESS} /> },
        {
          content: (
            <HorizontalFlex $justify="flex-end">
              <IconButton
                icon={EditIcon}
                title="Edit"
                size={ButtonSize.XS}
                onClick={() => console.log('Edit')}
              />
              <IconButton
                icon={DeleteIcon}
                title="Delete"
                size={ButtonSize.XS}
                onClick={() => console.log('Delete')}
              />
            </HorizontalFlex>
          ),
        },
      ],
    },
    // More rows...
  ];

  return (
    <VerticalFlex $gap={Space.V16}>
      <HorizontalFlex $justify="space-between">
        <HeadingM>Users</HeadingM>
        <HorizontalFlex $gap={Space.V8}>
          <Button
            label="Filter"
            leftIcon={FilterIcon}
            variant={ButtonVariant.SECONDARY}
            onClick={() => console.log('Filter')}
          />
          <Button
            label="Create User"
            leftIcon={AddIcon}
            onClick={() => console.log('Create')}
          />
        </HorizontalFlex>
      </HorizontalFlex>

      <TableScroller>
        <TableHead headings={headings} />
        <TableBody rows={rows} />
      </TableScroller>

      <HorizontalFlex $justify="flex-end">
        <Pagination
          page={currentPage}
          totalPages={totalPages}
          pageLabel="Page"
          prevLabel="Previous"
          nextLabel="Next"
          onChange={setCurrentPage}
        />
      </HorizontalFlex>
    </VerticalFlex>
  );
}
```

---

This guide provides comprehensive instructions for converting Figma designs to Stratos React components. Use component props and composition patterns to match the visual design while maintaining accessibility and usability best practices.
