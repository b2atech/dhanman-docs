# Trial Balance

The trial balance is a summary of all the debits and credits in the ledger.

```sql
SELECT 
    coa.account_number,
    coa.name,
    SUM(CASE WHEN je.entry_type = 'D' THEN je.amount ELSE 0 END) AS total_debits,
    SUM(CASE WHEN je.entry_type = 'C' THEN je.amount ELSE 0 END) AS total_credits
FROM 
    journal_entries je
JOIN 
    chart_of_accounts coa ON je.account_id = coa.id
WHERE 
    je.is_deleted = false
GROUP BY 
    coa.account_number, coa.name
ORDER BY 
    coa.account_number;
```