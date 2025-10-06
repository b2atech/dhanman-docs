# Accounts Payable Aging Report

This report shows the outstanding amounts owed to vendors and how long they have been outstanding.

```sql
SELECT 
    v.name AS vendor_name,
    coa.name AS account_name,
    je.amount,
    th.transaction_date + INTERVAL '30 days' AS due_date,  -- Assuming a 30-day payment term
    CASE 
        WHEN th.transaction_date + INTERVAL '30 days' <= CURRENT_DATE THEN 'Current'
        WHEN th.transaction_date + INTERVAL '30 days' BETWEEN CURRENT_DATE - INTERVAL '30 days' AND CURRENT_DATE THEN '1-30 Days Past Due'
        WHEN th.transaction_date + INTERVAL '30 days' BETWEEN CURRENT_DATE - INTERVAL '60 days' AND CURRENT_DATE - INTERVAL '31 days' THEN '31-60 Days Past Due'
        ELSE 'Over 60 Days Past Due'
    END AS aging_bucket
FROM 
    journal_entries je
JOIN 
    transaction_header th ON je.transaction_id = th.id
JOIN 
    chart_of_accounts coa ON je.account_id = coa.id
JOIN 
    vendors v ON th.vendor_id = v.id
WHERE 
    coa.account_type_id = (SELECT id FROM account_types WHERE name = 'Accounts Payable')
AND je.is_deleted = false
ORDER BY 
    v.name, th.transaction_date;
```