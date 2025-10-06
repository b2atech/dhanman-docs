# 📄 PostgreSQL User Access Management (DhanMan on OVH)

## 🧾 Overview

This document defines:
- Which users (`dhanmanqa`, `dhanmanprod`) have access to which databases.
- How to **check**, **grant**, and **revoke** access using DBeaver or `psql`.
- How to restrict access using PostgreSQL configurations.

---

## 👤 User Access Matrix

| Database                  | dhanmanqa | dhanmanprod |
|---------------------------|-----------|-------------|
| qa-dhanman-common         | ✅ Full   | ❌ None     |
| qa-dhanman-community      | ✅ Full   | ❌ None     |
| qa-dhanman-inventory      | ✅ Full   | ❌ None     |
| qa-dhanman-payroll        | ✅ Full   | ❌ None     |
| qa-dhanman-purchase       | ✅ Full   | ❌ None     |
| qa-dhanman-sales          | ✅ Full   | ❌ None     |
| prod-dhanman-common       | ❌ None   | ✅ Full     |
| prod-dhanman-community    | ❌ None   | ✅ Full     |
| prod-dhanman-inventory    | ❌ None   | ✅ Full     |
| prod-dhanman-payroll      | ❌ None   | ✅ Full     |
| prod-dhanman-purchase     | ❌ None   | ✅ Full     |
| prod-dhanman-sales        | ❌ None   | ✅ Full     |

---

## 🔍 Diagnostic: Check Access in Any Database

Replace `'dhanmanqa'` with the target username:

```sql
WITH target_user AS (
  SELECT 'dhanmanqa'::text AS username
)

-- 1. Schema usage
SELECT 'Schema Usage' AS check_type, n.nspname AS object_name,
       CASE WHEN has_schema_privilege(t.username, n.nspname, 'USAGE') THEN '✅ USAGE'
            ELSE '❌ NO USAGE' END AS status
FROM pg_namespace n CROSS JOIN target_user t
WHERE n.nspname = 'public'

UNION ALL

-- 2. Table access
SELECT 'Table Access', t1.table_name,
       CASE WHEN t2.table_name IS NOT NULL THEN '✅ OK'
            ELSE '❌ MISSING' END
FROM information_schema.tables t1 CROSS JOIN target_user t
LEFT JOIN (
  SELECT DISTINCT table_name
  FROM information_schema.role_table_grants
  WHERE grantee = (SELECT username FROM target_user)
    AND table_schema = 'public'
) t2 ON t1.table_name = t2.table_name
WHERE t1.table_schema = 'public'

UNION ALL

-- 3. Sequence access
SELECT 'Sequence Access', s.relname,
       CASE
         WHEN has_sequence_privilege(t.username, s.oid, 'USAGE') AND
              has_sequence_privilege(t.username, s.oid, 'SELECT') AND
              has_sequence_privilege(t.username, s.oid, 'UPDATE')
         THEN '✅ OK' ELSE '❌ MISSING'
       END
FROM pg_class s
JOIN pg_namespace n ON s.relnamespace = n.oid
CROSS JOIN target_user t
WHERE s.relkind = 'S' AND n.nspname = 'public';
```

---

## ➕ Grant Full Access to a User on a Database

Run inside the **target QA database**:

```sql
-- Schema usage
GRANT USAGE, CREATE ON SCHEMA public TO dhanmanqa;

-- Table access
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO dhanmanqa;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO dhanmanqa;

-- Sequence access
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO dhanmanqa;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO dhanmanqa;
```

---

## ➖ Revoke All Access from a User on a Database

Run inside each **prod** database to revoke `dhanmanqa` access:

```sql
REVOKE CONNECT ON DATABASE "prod-dhanman-common" FROM dhanmanqa;
REVOKE ALL PRIVILEGES ON SCHEMA public FROM dhanmanqa;
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM dhanmanqa;
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM dhanmanqa;
```

Repeat for all `prod-dhanman-*` databases.

---

## 🔒 Restrict Access with `pg_hba.conf`

1. Edit the config:

```bash
sudo nano /etc/postgresql/<version>/main/pg_hba.conf
```

2. Add entries:

```conf
# Block dhanmanqa from PROD
host    prod-dhanman-common     dhanmanqa   0.0.0.0/0   reject
host    prod-dhanman-community  dhanmanqa   0.0.0.0/0   reject
host    prod-dhanman-inventory  dhanmanqa   0.0.0.0/0   reject
host    prod-dhanman-payroll    dhanmanqa   0.0.0.0/0   reject
host    prod-dhanman-purchase   dhanmanqa   0.0.0.0/0   reject
host    prod-dhanman-sales      dhanmanqa   0.0.0.0/0   reject

# Allow dhanmanqa for QA
host    qa-dhanman-common       dhanmanqa   0.0.0.0/0   md5
```

3. Reload PostgreSQL:

```bash
sudo systemctl reload postgresql
```

---

## 🧪 Test Connection via CLI

```bash
psql -U dhanmanqa -d qa-dhanman-common -h <host> -W
```

Or use DBeaver to test login with credentials.

---


ubuntu@vps-0e227e4b:~$ which psql
/usr/bin/psql
