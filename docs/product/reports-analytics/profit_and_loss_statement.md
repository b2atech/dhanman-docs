# Profit and Loss Statement

The profit and loss statement shows the organization’s revenues and expenses over a period.

```sql
-- Revenue
SELECT 
    'Revenue' AS section,
    coa.account_number,
    coa.name,
    SUM(CASE WHEN je.entry_type = 'C' THEN je.amount ELSE -je.amount END) AS balance
FROM 
    journal_entries je
JOIN 
    chart_of_accounts coa ON je.account_id = coa.id
WHERE 
    coa.account_type_id IN (7, 8)  -- Revenue Accounts
AND je.is_deleted = false
GROUP BY 
    coa.account_number, coa.name
UNION ALL
-- Expenses
SELECT 
    'Expenses' AS section,
    coa.account_number,
    coa.name,
    SUM(CASE WHEN je.entry_type = 'D' THEN je.amount ELSE -je.amount END) AS balance
FROM 
    journal_entries je
JOIN 
    chart_of_accounts coa ON je.account_id = coa.id
WHERE 
    coa.account_type_id IN (9, 10, 11)  -- Expense Accounts
AND je.is_deleted = false
GROUP BY 
    coa.account_number, coa.name
ORDER BY 
    section, account_number;
```