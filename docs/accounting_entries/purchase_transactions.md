# Purchase

## Purchase Transaction

A purchase transaction is recorded when goods or services are bought from a vendor.

**Accounts Affected:**

- **Purchase Expense (Expense)**: Increase (Debit)
  - Account: `50010 Direct Materials`, `50110 Direct Labor`, or other relevant expense accounts
- **Accounts Payable (Liability)**: Increase (Credit)
  - Account: `21010 Trade Payables`
- **Inventory (Asset)**: Increase (Debit)
  - Account: `11300 Inventory`
- **Tax Receivable (Asset)**: Increase (Debit)
  - Account: `11410 SGST Receivable`
  - Account: `11420 CGST Receivable`
  - Account: `11430 IGST Receivable`

## Purchase Return

Purchase returns occur when you return goods to a vendor that were previously purchased.

**Accounts Affected:**

- **Purchase Expense (Expense)**: Decrease (Credit)
  - Account: `50010 Direct Materials`, `50110 Direct Labor`, or other relevant expense accounts
- **Accounts Payable (Liability)**: Decrease (Debit)
  - Account: `21010 Trade Payables`
- **Inventory (Asset)**: Decrease (Credit)
  - Account: `11300 Inventory`
- **Tax Receivable (Asset)**: Decrease (Credit)
  - Account: `11410 SGST Receivable`
  - Account: `11420 CGST Receivable`
  - Account: `11430 IGST Receivable`

## Purchase Discount

Purchase discounts are reductions in the amount owed to vendors, usually offered for early payment.

**Accounts Affected:**

- **Purchase Expense (Expense)**: Decrease (Credit)
  - Account: `50010 Direct Materials`, `50110 Direct Labor`, or other relevant expense accounts
- **Accounts Payable (Liability)**: Decrease (Debit)
  - Account: `21010 Trade Payables`

## Cash Purchase

Cash purchases occur when goods or services are bought, and payment is made immediately in cash.

**Accounts Affected:**

- **Purchase Expense (Expense)**: Increase (Debit)
  - Account: `50010 Direct Materials`, `50110 Direct Labor`, or other relevant expense accounts
- **Cash and Cash Equivalents (Asset)**: Decrease (Credit)
  - Account: `11110 Petty Cash` or `11120 Bank Accounts`
- **Inventory (Asset)**: Increase (Debit)
  - Account: `11300 Inventory`
- **Tax Receivable (Asset)**: Increase (Debit)
  - Account: `11410 SGST Receivable`
  - Account: `11420 CGST Receivable`
  - Account: `11430 IGST Receivable`

## Credit Purchase

Credit purchases occur when goods or services are bought, and payment is made at a later date.

**Accounts Affected:**

- **Purchase Expense (Expense)**: Increase (Debit)
  - Account: `50010 Direct Materials`, `50110 Direct Labor`, or other relevant expense accounts
- **Accounts Payable (Liability)**: Increase (Credit)
  - Account: `21010 Trade Payables`
- **Inventory (Asset)**: Increase (Debit)
  - Account: `11300 Inventory`
- **Tax Receivable (Asset)**: Increase (Debit)
  - Account: `11410 SGST Receivable`
  - Account: `11420 CGST Receivable`
  - Account: `11430 IGST Receivable`

## Process for Recording and Paying Bills

### Step 1: Create the Bill in the Purchase Module

**Accounts Affected:**

- **Electricity Expense (Expense):** Increase (Debit)
  - Account: `51510 Electricity Expense`
- **Trade Payables (Liability):** Increase (Credit)
  - Account: `21010 Trade Payables`

**Example Journal Entry for Bill Creation:**

| Date       | Account                       | Debit  | Credit | Increase/Decrease |
| ---------- | ----------------------------- | ------ | ------ | ----------------- |
| 2024-04-01 | Electricity Expense (Expense) | 500.00 |        | Increase (Debit)  |
| 2024-04-01 | Trade Payables (Liability)    |        | 500.00 | Increase (Credit) |

### Step 2: Make the Payment

**Accounts Affected:**

- **Trade Payables (Liability):** Decrease (Debit)
  - Account: `21010 Trade Payables`
- **Cash and Cash Equivalents (Asset):** Decrease (Credit)
  - Account: `11120 Bank Accounts`

**Example Journal Entry for Payment:**
| Date | Account | Debit | Credit | Increase/Decrease |
|------------|-----------------------------|---------|---------|-------------------|
| 2024-04-10 | Trade Payables (Liability) | 500.00 | | Decrease (Debit) |
| 2024-04-10 | Bank Accounts (Asset) | | 500.00 | Decrease (Credit) |

## Explanation and Best Practices

1.  **Categorization:**

    - **Liabilities:** This is the parent category for all liability accounts.
    - **Current Liabilities:** Sub-category under Liabilities for short-term obligations.
    - **Trade Payables:** Specific account under Current Liabilities for payables to vendors and other short-term obligations.

2.  **Bill Creation:**

    - Record the bill in the purchase module to increase the respective expense account and the trade payables account.

3.  **Payment Processing:**

    - When making a payment, decrease the trade payables account and the cash or bank account.

By following this structure, you ensure that your accounting records are accurate, consistent, and aligned with standard accounting practices. This approach also provides clear visibility into your financial obligations and helps maintain an audit trail for all transactions.
