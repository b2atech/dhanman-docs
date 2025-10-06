# Balance Sheet

The balance sheet shows the financial position of the organization, detailing assets, liabilities, and equity.

```sql
-- Assets
SELECT 
    'Assets' AS section,
    coa.account_number,
    coa.name,
    SUM(CASE WHEN je.entry_type = 'D' THEN je.amount ELSE -je.amount END) AS balance
FROM 
    journal_entries je
JOIN 
    chart_of_accounts coa ON je.account_id = coa.id
WHERE 
    coa.account_type_id IN (1, 2)  -- Current Assets and Non-Current Assets
AND je.is_deleted = false
GROUP BY 
    coa.account_number, coa.name
UNION ALL
-- Liabilities
SELECT 
    'Liabilities' AS section,
    coa.account_number,
    coa.name,
    SUM(CASE WHEN je.entry_type = 'C' THEN je.amount ELSE -je.amount END) AS balance
FROM 
    journal_entries je
JOIN 
    chart_of_accounts coa ON je.account_id = coa.id
WHERE 
    coa.account_type_id IN (3, 4)  -- Current Liabilities and Non-Current Liabilities
AND je.is_deleted = false
GROUP BY 
    coa.account_number, coa.name
UNION ALL
-- Equity
SELECT 
    'Equity' AS section,
    coa.account_number,
    coa.name,
    SUM(CASE WHEN je.entry_type = 'C' THEN je.amount ELSE -je.amount END) AS balance
FROM 
    journal_entries je
JOIN 
    chart_of_accounts coa ON je.account_id = coa.id
WHERE 
    coa.account_type_id IN (5, 6)  -- Various Equity Accounts
AND je.is_deleted = false
GROUP BY 
    coa.account_number, coa.name
ORDER BY 
    section, account_number;
```