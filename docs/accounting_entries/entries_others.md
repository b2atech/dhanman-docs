# Other Accounting Transactions and Affected Accounts

## Payroll Transactions
Payroll transactions are recorded when employee salaries and wages are paid.

**Accounts Affected:**
- **Salaries and Wages (Expense)**: Increase
  - Account: `51710 Salaries and Wages`
- **Payroll Taxes (Expense)**: Increase
  - Account: `51810 Payroll Taxes`
- **Employee Benefits (Expense)**: Increase
  - Account: `51910 Employee Benefits`
- **Cash and Cash Equivalents (Asset)**: Decrease
  - Account: `11110 Petty Cash` or `11120 Bank Accounts`

## Loan Transactions
Loan transactions are recorded when a company borrows or repays a loan.

### Loan Disbursement
**Accounts Affected:**
- **Cash and Cash Equivalents (Asset)**: Increase
  - Account: `11120 Bank Accounts`
- **Loans Payable (Liability)**: Increase
  - Account: `22010 Short-Term Loans` or `26010 Long-Term Loans`

### Loan Repayment
**Accounts Affected:**
- **Loans Payable (Liability)**: Decrease
  - Account: `22010 Short-Term Loans` or `26010 Long-Term Loans`
- **Cash and Cash Equivalents (Asset)**: Decrease
  - Account: `11120 Bank Accounts`
- **Interest Expense (Expense)**: Increase
  - Account: `53010 Interest Expense`

## Fixed Asset Purchase
Fixed asset purchases are recorded when the company buys property, plant, or equipment.

**Accounts Affected:**
- **Property, Plant, and Equipment (Asset)**: Increase
  - Account: `12010 Property, Plant, and Equipment`
- **Cash and Cash Equivalents (Asset)**: Decrease
  - Account: `11110 Petty Cash` or `11120 Bank Accounts`
- **Accounts Payable (Liability)**: Increase (if bought on credit)
  - Account: `21010 Trade Payables`

## Depreciation
Depreciation is recorded to allocate the cost of fixed assets over their useful lives.

**Accounts Affected:**
- **Accumulated Depreciation (Contra Asset)**: Increase
  - Account: `12010 Property, Plant, and Equipment` (or a specific account for accumulated depreciation)
- **Depreciation Expense (Expense)**: Increase
  - Account: `51710 Depreciation Expense`

## Amortization
Amortization is recorded to allocate the cost of intangible assets over their useful lives.

**Accounts Affected:**
- **Accumulated Amortization (Contra Asset)**: Increase
  - Account: `12020 Intangible Assets` (or a specific account for accumulated amortization)
- **Amortization Expense (Expense)**: Increase
  - Account: `51720 Amortization Expense`

## Prepaid Expense Adjustment
Adjustments are made to recognize prepaid expenses over time.

**Accounts Affected:**
- **Prepaid Expenses (Asset)**: Decrease
  - Account: `11400 Prepaid Expenses`
- **Expense Account (Expense)**: Increase
  - Account: `51010 Selling Expenses`, `51110 Marketing Expenses`, or other relevant expense accounts

## Accrued Expense Adjustment
Adjustments are made to record expenses that have been incurred but not yet paid.

**Accounts Affected:**
- **Accrued Liabilities (Liability)**: Increase
  - Account: `24010 Accrued Liabilities`
- **Expense Account (Expense)**: Increase
  - Account: `51010 Selling Expenses`, `51110 Marketing Expenses`, `51210 Administrative Expenses`, or other relevant expense accounts

## Unearned Revenue Adjustment
Adjustments are made to recognize revenue from unearned revenue over time.

**Accounts Affected:**
- **Unearned Revenue (Liability)**: Decrease
  - Account: `25010 Unearned Revenue`
- **Revenue Account (Revenue)**: Increase
  - Account: `40010 Domestic Sales`, `40110 Export Sales`, `41010 Service Revenue`, or other relevant revenue accounts

## Bad Debt Write-off
Bad debts are written off when it is determined that certain receivables will not be collected.

**Accounts Affected:**
- **Allowance for Doubtful Accounts (Contra Asset)**: Increase
  - Account: `11200 Accounts Receivable` (or a specific account for allowance)
- **Bad Debt Expense (Expense)**: Increase
  - Account: `53110 Other Expenses` (or a specific account for bad debt)

## Intercompany Transactions
Intercompany transactions are recorded for transfers between different entities within the same organization.

### Intercompany Receivables/Payables
**Accounts Affected:**
- **Intercompany Receivable (Asset)**: Increase
  - Account: (specific intercompany receivable account)
- **Intercompany Payable (Liability)**: Increase
  - Account: (specific intercompany payable account)

These are common situations that require entries to be made to the `transaction_header` and `journal_entries` tables, along with the typical accounts affected by each type of transaction.
