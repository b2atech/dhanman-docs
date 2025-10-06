# Test ID Strategy for dhanman-app

This document outlines the conventions and best practices for using `data-testid` attributes in the dhanman-app React application to support reliable E2E testing with Playwright.

## Overview

The `data-testid` attribute is used to provide stable, semantic selectors for automated testing. Unlike CSS classes or element types that might change due to styling or refactoring, `data-testid` attributes are specifically intended for testing and remain stable across UI changes.

## Naming Conventions

### Format
Use kebab-case for all test IDs:
```tsx
data-testid="auth0-login-button"
data-testid="invoice-create-form"
data-testid="bill-status-badge"
```

### Component-Based Naming
Structure test IDs to reflect the component hierarchy and purpose:

```
[feature]-[component]-[element]
```

**Examples:**
- `auth0-login-button` - Auth0 login button
- `invoice-create-form` - Invoice creation form
- `bill-list-table` - Bills listing table
- `payment-approve-modal` - Payment approval modal
- `ledger-export-button` - Ledger export functionality

### Specific Naming Patterns

#### Forms
- `{feature}-{action}-form` - Main form container
- `{feature}-{field}-input` - Input fields
- `{feature}-{action}-submit` - Submit buttons
- `{feature}-{action}-cancel` - Cancel buttons

**Examples:**
```tsx
<form data-testid="invoice-create-form">
  <input data-testid="invoice-amount-input" />
  <input data-testid="invoice-description-input" />
  <button data-testid="invoice-create-submit">Create Invoice</button>
  <button data-testid="invoice-create-cancel">Cancel</button>
</form>
```

#### Lists and Tables
- `{feature}-list-container` - List wrapper
- `{feature}-list-item` - Individual list items
- `{feature}-table-row` - Table rows
- `{feature}-{action}-button` - Action buttons within lists

**Examples:**
```tsx
<div data-testid="bill-list-container">
  <div data-testid="bill-list-item">
    <button data-testid="bill-view-button">View</button>
    <button data-testid="bill-edit-button">Edit</button>
  </div>
</div>
```

#### Navigation and UI Elements
- `{section}-nav-link` - Navigation links
- `{feature}-status-badge` - Status indicators
- `{feature}-filter-{type}` - Filter controls
- `{feature}-search-input` - Search inputs

**Examples:**
```tsx
<nav>
  <a data-testid="bills-nav-link">Bills</a>
  <a data-testid="invoices-nav-link">Invoices</a>
  <a data-testid="payments-nav-link">Payments</a>
</nav>

<span data-testid="bill-status-badge">Approved</span>
<input data-testid="invoice-search-input" placeholder="Search invoices..." />
```

## Implementation Guidelines

### 1. Add to Interactive Elements
Prioritize adding `data-testid` to elements that users interact with:
- Buttons
- Form inputs
- Links
- Dropdowns
- Modals
- Tables

### 2. Use Semantic IDs
Make test IDs descriptive of the element's purpose, not its appearance:
```tsx
// Good
<button data-testid="invoice-approve-button">Approve</button>

// Avoid
<button data-testid="green-button">Approve</button>
```

### 3. Maintain Consistency
Use consistent patterns across similar components:
```tsx
// All approval buttons follow the same pattern
<button data-testid="invoice-approve-button">Approve Invoice</button>
<button data-testid="bill-approve-button">Approve Bill</button>
<button data-testid="payment-approve-button">Approve Payment</button>
```

### 4. Dynamic Test IDs
For dynamic content (like lists), include unique identifiers:
```tsx
{bills.map(bill => (
  <div key={bill.id} data-testid={`bill-item-${bill.id}`}>
    <button data-testid={`bill-edit-button-${bill.id}`}>Edit</button>
    <button data-testid={`bill-delete-button-${bill.id}`}>Delete</button>
  </div>
))}
```

## Best Practices

### 1. Keep Test IDs Stable
- Don't include dynamic values that change frequently (like timestamps)
- Don't use auto-generated IDs unless they're deterministic
- Prefer business logic identifiers over technical ones

### 2. Document Complex Components
For complex components with multiple interactive elements, document the test ID structure:

```tsx
/**
 * Invoice Form Component Test IDs:
 * - invoice-create-form: Main form container
 * - invoice-amount-input: Amount input field
 * - invoice-date-picker: Date picker component
 * - invoice-vendor-select: Vendor dropdown
 * - invoice-create-submit: Form submission button
 * - invoice-create-cancel: Cancel button
 */
```

### 3. Avoid Over-Testing
Don't add test IDs to every element - focus on:
- User interaction points
- Critical business logic elements
- Elements that are hard to select otherwise

### 4. Coordinate with Tests
Ensure test IDs are added before writing the corresponding E2E tests, and keep the test file documentation in sync with component changes.

## Current Test Coverage

### Implemented
- **Auth0 Login Button** (`auth0-login-button`) - Login page authentication

### Planned Extensions
Future areas for test ID implementation:
- Bill creation and management forms
- Invoice workflow and approval processes
- Payment processing interfaces
- Ledger and reporting features
- User management and settings
- Dashboard and analytics components

## Testing Integration

### Playwright Usage
```typescript
// Using test IDs in Playwright tests
await page.getByTestId('auth0-login-button').click();
await page.getByTestId('invoice-create-form').waitFor();
await page.getByTestId('bill-amount-input').fill('100.00');
```

### Test Organization
Organize tests to match the test ID naming structure:
```
e2e/
├── auth/
│   └── login.spec.ts
├── bills/
│   ├── create.spec.ts
│   └── approve.spec.ts
├── invoices/
│   ├── create.spec.ts
│   └── workflow.spec.ts
└── payments/
    └── process.spec.ts
```

## Maintenance

### Regular Review
- Review test IDs during code reviews
- Update this document when adding new patterns
- Ensure test IDs remain consistent across feature additions
- Remove obsolete test IDs when refactoring components

### Versioning
When making breaking changes to test IDs:
1. Update this document with the new patterns
2. Update corresponding tests
3. Consider backward compatibility for gradual migration

---

**Note:** This strategy document should be updated as the testing infrastructure grows and new patterns emerge. All team members should follow these conventions to maintain consistency across the application.