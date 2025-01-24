
# Accounting Documentation for Apartment Management System

This document outlines the **Chart of Accounts**, **Accounting Entries**, and the distinction between **Profit and Loss (P&L)** and **Balance Sheet** accounts for an apartment management system.

## **1. Chart of Accounts**

### **Asset Accounts**
- **1010 Cash**: Tracks cash on hand.
- **1020 Bank Account**: Tracks money in the bank.
- **1030 Accounts Receivable**: Tracks rent owed by tenants.
- **1040 Prepaid Expenses**: Tracks prepaid expenses (e.g., insurance).

### **Liability Accounts**
- **2010 Accounts Payable**: Tracks bills owed to vendors.
- **2020 Security Deposits**: Tracks security deposits from tenants.
- **2030 Unearned Rent**: Tracks rent received in advance.

### **Equity Accounts**
- **3010 Owner’s Equity**: Tracks the owner’s investment in the business.
- **3020 Retained Earnings**: Tracks profits reinvested in the business.

### **Revenue Accounts**
- **4010 Rent Income**: Tracks rental income from tenants.
- **4020 Late Fees**: Tracks late fees charged to tenants.

### **Expense Accounts**
- **5010 Utilities Expense**: Tracks utility bills (e.g., water, electricity).
- **5020 Maintenance Expense**: Tracks maintenance costs.
- **5030 Property Taxes**: Tracks property taxes.
- **5040 Insurance Expense**: Tracks insurance costs.

## **2. Accounting Entries**

### **2.1. When Rent Invoice is Raised**
- **Debit**: Accounts Receivable (Asset increases).
- **Credit**: Rent Income (Revenue increases).

**Journal Entry**:
- **Debit** : Accounts Receivable (1030) -  1,000
- **Credit**:RentIncome(4010)−1,000

### **2.2. When Rent is Paid by Tenant**
- **Debit**: Cash/Bank Account (Asset increases).
- **Credit**: Accounts Receivable (Asset decreases).

**Journal Entry**:
- **Debit**: Cash (1010) -  1,000
- **Credit**: AccountsReceivable(1030)−1,000

### **2.3. When a Bill is Raised (e.g., Maintenance)**
- **Debit**: Maintenance Expense (Expense increases).
- **Credit**: Accounts Payable (Liability increases).

**Journal Entry**:
- **Debit**: Maintenance Expense (5020) - 200
- **Credit**: AccountsPayable(2010)−200Credit:AccountsPayable(2010)−200

### **2.4. When a Bill is Paid**
- **Debit**: Accounts Payable (Liability decreases).
- **Credit**: Cash/Bank Account (Asset decreases).

**Journal Entry**:
- **Debit**: Accounts Payable (2010) -  200
- **Credit**: Cash(1010)−200

### **2.5. When Security Deposit is Received**
- **Debit**: Cash/Bank Account (Asset increases).
- **Credit**: Security Deposits (Liability increases).

**Journal Entry**:
- **Debit**: Cash (1010) -  500
- **Credit**: SecurityDeposits(2020)−500

### **2.6. When Security Deposit is Refunded**
- **Debit**: Security Deposits (Liability decreases).
- **Credit**: Cash/Bank Account (Asset decreases).

**Journal Entry**:
- **Debit**: Security Deposits (2020) -  500
- **Credit**:Cash(1010)−500

## **3. Profit and Loss (P&L) vs. Balance Sheet Accounts**

### **Profit and Loss Statement (P&L) Accounts**
- **Revenue Accounts**:
  - 4010 Rent Income
  - 4020 Late Fees
- **Expense Accounts**:
  - 5010 Utilities Expense
  - 5020 Maintenance Expense
  - 5030 Property Taxes
  - 5040 Insurance Expense

### **Balance Sheet Accounts**
- **Asset Accounts**:
  - 1010 Cash
  - 1020 Bank Account
  - 1030 Accounts Receivable
  - 1040 Prepaid Expenses
- **Liability Accounts**:
  - 2010 Accounts Payable
  - 2020 Security Deposits
  - 2030 Unearned Rent
- **Equity Accounts**:
  - 3010 Owner’s Equity
  - 3020 Retained Earnings

## **4. Example Transactions**

### **Transaction 1: Rent Invoice Raised**
- Tenant A is invoiced $1,000 for rent.
- **Debit**: Accounts Receivable (1030) -  1,000 
- **Credit**:RentIncome(4010)−1,000

### **Transaction 2: Rent Payment Received**
- Tenant A pays the $1,000 rent.
- **Debit**: Cash (1010) -  1,000
- **Credit**: AccountsReceivable(1030)−1,000

### **Transaction 3: Maintenance Bill Received**
- A maintenance bill of $200 is received.

- **Debit**: Maintenance Expense (5020) -  200
- **Credit**: AccountsPayable(2010)−200

### **Transaction 4: Maintenance Bill Paid**
- The $200 maintenance bill is paid.
- **Debit**: Accounts Payable (2010) -  200
- **Credit**: Cash(1010)−200


## **5. Visual Representation**

### **Profit and Loss Statement (P&L)**

Revenue: Rent Income, Late Fees  
Expenses: Utilities, Maintenance, Taxes, Insurance  
Net Profit/Loss → Transferred to Retained Earnings on Balance Sheet

### **Balance Sheet**

Assets: Cash, Bank, Accounts Receivable, Prepaid Expenses  
Liabilities: Accounts Payable, Security Deposits, Unearned Rent  
Equity: Owner’s Equity, Retained Earnings

## **6. Next Steps**
- Design the database schema to store these accounts.
- Implement the accounting logic in the C# backend.
- Create React forms to input and display financial data.
