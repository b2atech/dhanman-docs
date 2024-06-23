# Pending Dues Report

This report shows all the outstanding amounts owed by customers and vendors that are past due.

```sql
-- Pending Dues from Customers (Accounts Receivable)
SELECT 
    'Customer' AS type,
    c.name AS name,
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
    customers c ON th.customer_id = c.id
WHERE 
    coa.account_type_id = (SELECT id FROM account_types WHERE name = 'Accounts Receivable')
AND je.is_deleted = false
AND th.transaction_date + INTERVAL '30 days' <= CURRENT_DATE
ORDER BY 
    name, due_date;
```