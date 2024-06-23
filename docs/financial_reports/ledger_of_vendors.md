
# Ledger of Vendors

The vendor ledger shows transactions related to vendor accounts (Accounts Payable).

```sql
SELECT 
    th.transaction_date AS transaction_date,
    v.name AS vendor_name,
    coa.name AS account_name,
    CASE WHEN je.entry_type = 'C' THEN je.amount ELSE 0 END AS credit,
    CASE WHEN je.entry_type = 'D' THEN je.amount ELSE 0 END AS debit,
    SUM(CASE WHEN je.entry_type = 'C' THEN je.amount ELSE -je.amount END) OVER (PARTITION BY v.id ORDER BY th.transaction_date) AS balance
FROM 
    transaction_header th
JOIN 
    journal_entries je ON th.id = je.transaction_id
JOIN 
    chart_of_accounts coa ON je.account_id = coa.id
JOIN 
    vendors v ON th.vendor_id = v.id
WHERE 
    coa.account_type_id = (SELECT id FROM account_types WHERE name = 'Accounts Payable')
ORDER BY 
    th.transaction_date, v.name;
```