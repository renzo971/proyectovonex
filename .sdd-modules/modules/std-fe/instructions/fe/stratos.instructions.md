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
- `CheckIcon`, `ErrorIcon`, `WarningIcon`, `InformationIcon`
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
<IconButton icon={EditIcon} title="Edit" size={ButtonSize.XS} onClick={handleEdit} />
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
<Link label="View details" rightIcon={ArrowRightIcon} onClick={handleViewDetails} />
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
<NumberField value={quantity} label="Quantity" min={0} max={100} onChange={setQuantity} />
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
  { label: 'Option 3', value: 'opt3', icon: CheckIcon },
];

<Select
  value={selectedValue}
  options={options}
  label="Choose an option"
  placeholder="Select one"
  emptyLabel="No options available"
  filterPlaceholder="Search options"
  onChange={setSelectedValue}
/>;
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
<Checkbox value={isChecked} label="I agree to terms and conditions" required onChange={setIsChecked} />
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
  <RadioButton value={selectedOption === 'option1'} label="Option 1" onChange={() => setSelectedOption('option1')} />
  <RadioButton value={selectedOption === 'option2'} label="Option 2" onChange={() => setSelectedOption('option2')} />
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
<Switch value={isEnabled} label="Enable notifications" onChange={setIsEnabled} />
```

### DateField

Date picker component.

**Required Props:**

- `value`: Date value
- `onChange`: Handler function

**Optional Props:**

- `label`: Field label
- `placeholder`: Placeholder text
- `disabled`: Boolean
- `required`: Boolean
- `caption`: Validation messages
- `minDate`, `maxDate`: Date constraints

**Example:**

```tsx
<DateField value={selectedDate} label="Select date" placeholder="DD/MM/YYYY" onChange={setSelectedDate} />
```

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
<Toast message="Item deleted successfully" variant={ToastVariant.SUCCESS} />
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
  { label: 'Details', onClick: () => navigate('/products/123') },
];

<Breadcrumb items={breadcrumbItems} />;
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
  tabs={[{ label: 'Overview' }, { label: 'Details' }, { label: 'History' }]}
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
  steps={[{ label: 'Personal Info' }, { label: 'Address' }, { label: 'Payment' }, { label: 'Confirmation' }]}
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
  body={<RegularTextM>Are you sure you want to delete this item? This action cannot be undone.</RegularTextM>}
  footer={
    <HorizontalFlex $justify="flex-end" $gap={Space.V8}>
      <Button label="Cancel" variant={ButtonVariant.SECONDARY} onClick={handleClose} />
      <Button label="Delete" severity={ButtonSeverity.DANGER} onClick={handleDelete} />
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
  { content: 'Actions', width: 100, align: 'flex-end' },
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
        ),
      },
    ],
  },
];

<TableScroller>
  <TableTitle>
    <HeadingS>Data Table</HeadingS>
  </TableTitle>
  <TableHead headings={headings} />
  <TableBody rows={rows} />
</TableScroller>;
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
    { label: 'Pending', value: '13' },
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
  <Select value={statusFilter} options={statusOptions} label="Status" onChange={setStatusFilter} />
  <DateField value={dateFilter} label="Date" onChange={setDateFilter} />
</Filters>
```

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
  <Padder $pad={Space.V24}>{/* Content */}</Padder>
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
  actions={<Button label="Create Item" leftIcon={AddIcon} onClick={handleCreate} />}
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
  <RegularTextS>This information will help you complete the form correctly.</RegularTextS>
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
      status: 'pending',
    },
  ]}
/>
```

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
        <Button label="Create New" leftIcon={AddIcon} onClick={handleCreate} />
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
          <CloseButton title="Close" size={IconSize.V32} onClick={handleClose} />
        </HorizontalFlex>
        <Stepper steps={[{ label: 'Step 1' }, { label: 'Step 2' }, { label: 'Step 3' }]} activeStep={1} />
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
  <LayoutContainer>{/* Page content */}</LayoutContainer>
</LayoutBackground>
```

---

## Common Patterns

### Form Layout

**Single Column Form:**

```tsx
<VerticalFlex $gap={Space.V16}>
  <TextField value={field1} label="Field 1" required onChange={setField1} />
  <TextField value={field2} label="Field 2" onChange={setField2} />
  <Select value={field3} options={options} label="Field 3" onChange={setField3} />

  <HorizontalFlex $justify="flex-end" $gap={Space.V8}>
    <Button label="Cancel" variant={ButtonVariant.SECONDARY} onClick={handleCancel} />
    <Button label="Save" type="submit" onClick={handleSave} />
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
      <Button label="Filter" leftIcon={FilterIcon} variant={ButtonVariant.SECONDARY} onClick={handleFilter} />
      <Button label="Create" leftIcon={AddIcon} onClick={handleCreate} />
    </HorizontalFlex>
  </HorizontalFlex>

  {/* Table */}
  <TableScroller>
    <TableHead headings={headings} />
    <TableBody rows={rows} />
  </TableScroller>

  {/* Pagination */}
  <HorizontalFlex $justify="flex-end">
    <Pagination page={currentPage} totalPages={totalPages} onChange={setCurrentPage} />
  </HorizontalFlex>
</VerticalFlex>
```

### Tabs with Content

```tsx
const [activeTab, setActiveTab] = useState(0);

<VerticalFlex $gap={Space.V24}>
  <Tabs
    tabs={[{ label: 'Overview' }, { label: 'Details' }, { label: 'History' }]}
    activeTab={activeTab}
    onChange={setActiveTab}
  />

  {activeTab === 0 && <OverviewContent />}
  {activeTab === 1 && <DetailsContent />}
  {activeTab === 2 && <HistoryContent />}
</VerticalFlex>;
```

### Loading States

```tsx
{
  isLoading ? (
    <Padder $pad={Space.V24}>
      <Loader label="Loading data..." />
    </Padder>
  ) : (
    <TableScroller>
      <TableHead headings={headings} />
      <TableBody rows={rows} />
    </TableScroller>
  );
}
```

### Empty States

```tsx
{
  items.length === 0 ? (
    <EmptyState
      title="No items found"
      description="Create your first item to get started"
      actions={<Button label="Create Item" leftIcon={AddIcon} onClick={handleCreate} />}
    />
  ) : (
    <TableScroller>
      <TableHead headings={headings} />
      <TableBody rows={rows} />
    </TableScroller>
  );
}
```

---

## Figma to Component Mapping Guide

### Visual Elements → Components

| Figma Element            | Stratos Component                                 | Notes                      |
| ------------------------ | ------------------------------------------------- | -------------------------- |
| Large heading text       | `HeadingL`                                        | Page titles                |
| Medium heading text      | `HeadingM`                                        | Section titles             |
| Small heading text       | `HeadingS`                                        | Subsection titles          |
| Body text                | `RegularTextM`                                    | Regular content            |
| Small text               | `RegularTextS`                                    | Captions, notes            |
| Primary button           | `Button` with `variant={ButtonVariant.PRIMARY}`   | Main actions               |
| Secondary button         | `Button` with `variant={ButtonVariant.SECONDARY}` | Alternative actions        |
| Ghost/text button        | `Button` with `variant={ButtonVariant.GHOST}`     | Tertiary actions           |
| Icon button              | `IconButton`                                      | Actions with only icons    |
| Text input               | `TextField`                                       | Single-line inputs         |
| Text area                | `Textarea`                                        | Multi-line inputs          |
| Dropdown                 | `Select`                                          | Single selection           |
| Multi-select dropdown    | `MultiSelect`                                     | Multiple selections        |
| Checkbox                 | `Checkbox`                                        | Boolean choices            |
| Radio button             | `RadioButton`                                     | Mutually exclusive choices |
| Toggle switch            | `Switch`                                          | On/off states              |
| Date picker              | `DateField`                                       | Date selection             |
| Data table               | `TableScroller` + `TableHead` + `TableBody`       | Tabular data               |
| Card                     | `Card` + `CardBody`                               | Grouped content            |
| Modal/Dialog             | `Modal`                                           | Overlay dialogs            |
| Notification banner      | `Notify`                                          | Page-level messages        |
| Toast message            | `Toast`                                           | Temporary notifications    |
| Tooltip icon             | `Tooltip`                                         | Help icons                 |
| Breadcrumb               | `Breadcrumb`                                      | Navigation trail           |
| Tabs                     | `Tabs`                                            | Tab navigation             |
| Stepper                  | `Stepper`                                         | Multi-step progress        |
| Loading spinner          | `Loader`                                          | Loading states             |
| Status badge             | `StatusBadge`                                     | Status indicators          |
| Tag/Chip                 | `StaticChip`                                      | Tags, labels               |
| Empty state illustration | `EmptyState`                                      | No content states          |

### Layout Patterns

| Figma Layout     | Stratos Implementation                             |
| ---------------- | -------------------------------------------------- |
| Vertical stack   | `<VerticalFlex $gap={Space.V16}>`                  |
| Horizontal row   | `<HorizontalFlex $gap={Space.V8}>`                 |
| Grid layout      | `<ResponsiveGrid $l="repeat(3, 1fr)">`             |
| Centered content | `<VerticalFlex $align="center" $justify="center">` |
| Space between    | `<HorizontalFlex $justify="space-between">`        |
| Wrapped items    | `<HorizontalFlex $wrap>`                           |

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

          <Checkbox value={acceptTerms} label="I accept the terms and conditions" required onChange={setAcceptTerms} />
        </VerticalFlex>

        <HorizontalFlex $justify="flex-end" $gap={Space.V8}>
          <Button label="Cancel" variant={ButtonVariant.SECONDARY} onClick={() => console.log('Cancel')} />
          <Button label="Save" disabled={!acceptTerms} onClick={() => console.log('Save')} />
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
              <IconButton icon={EditIcon} title="Edit" size={ButtonSize.XS} onClick={() => console.log('Edit')} />
              <IconButton icon={DeleteIcon} title="Delete" size={ButtonSize.XS} onClick={() => console.log('Delete')} />
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
          <Button label="Create User" leftIcon={AddIcon} onClick={() => console.log('Create')} />
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
