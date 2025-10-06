# Ledger of Customers

The customer ledger shows transactions related to customer accounts (Accounts Receivable).

```sql
SELECT 
    th.transaction_date AS transaction_date,
    c.name AS customer_name,
    coa.name AS account_name,
    CASE WHEN je.entry_type = 'D' THEN je.amount ELSE 0 END AS debit,
    CASE WHEN je.entry_type = 'C' THEN je.amount ELSE 0 END AS credit,
    SUM(CASE WHEN je.entry_type = 'D' THEN je.amount ELSE -je.amount END) OVER (PARTITION BY c.id ORDER BY th.transaction_date) AS balance
FROM 
    transaction_header th
JOIN 
    journal_entries je ON th.id = je.transaction_id
JOIN 
    chart_of_accounts coa ON je.account_id = coa.id
JOIN 
    customers c ON th.customer_id = c.id
WHERE 
    coa.account_type_id = (SELECT id FROM account_types WHERE name = 'Accounts Receivable')
ORDER BY 
    th.transaction_date, c.name;
```
