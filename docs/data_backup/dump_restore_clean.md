# 🛠️ PostgreSQL QA Database Backup & Restore Documentation

## 🎯 Objective

To:

1. Take fresh `.sql` backups of all **QA databases** from **Azure PostgreSQL**
2. Clean corresponding **QA databases** in **OVH PostgreSQL**
3. Restore the Azure QA backups into OVH QA databases

---

## ☁️ Step 1: Backup from Azure QA to Local `.sql` Files

Use the following commands in PowerShell to **export all QA databases** from Azure:

```powershell
$env:PGPASSWORD = "Your_Password"

# COMMON
.\pg_dump.exe -h az-dhanman-qa.postgres.database.azure.com -U dhanmanqa -d qa-dhanman-common -f "C:\Users\SAI\Desktop\your_path\qa-common-backup.sql"

# COMMUNITY
.\pg_dump.exe -h az-dhanman-qa.postgres.database.azure.com -U dhanmanqa -d qa-dhanman-community -f "C:\Users\SAI\Desktop\your_path\qa-community-backup.sql"

# SALES
.\pg_dump.exe -h az-dhanman-qa.postgres.database.azure.com -U dhanmanqa -d qa-dhanman-sales -f "C:\Users\SAI\Desktop\your_path\qa-sales-backup.sql"

# PURCHASE
.\pg_dump.exe -h az-dhanman-qa.postgres.database.azure.com -U dhanmanqa -d qa-dhanman-purchase -f "C:\Users\SAI\Desktop\your_path\qa-purchase-backup.sql"

# INVENTORY
.\pg_dump.exe -h az-dhanman-qa.postgres.database.azure.com -U dhanmanqa -d qa-dhanman-inventory -f "C:\Users\SAI\Desktop\your_path\qa-inventory-backup.sql"

# PAYROLL
.\pg_dump.exe -h az-dhanman-qa.postgres.database.azure.com -U dhanmanqa -d qa-dhanman-payroll -f "C:\Users\SAI\Desktop\your_path\qa-payroll-backup.sql"

Remove-Item Env:PGPASSWORD
```

---

## 🧼 Step 2: Clean Target OVH QA Databases

Use the following SQL cleanup block to remove **all objects from the `public` schema** before restoring:

> Save as `cleanup.sql` and run for each OVH QA DB before restore.

```sql
DO
$$
DECLARE
    obj RECORD;
BEGIN
    -- Drop views
    FOR obj IN (SELECT table_name FROM information_schema.views WHERE table_schema = 'public') LOOP
        EXECUTE format('DROP VIEW IF EXISTS public.%I CASCADE', obj.table_name);
    END LOOP;

    -- Drop materialized views
    FOR obj IN (SELECT matviewname FROM pg_matviews WHERE schemaname = 'public') LOOP
        EXECUTE format('DROP MATERIALIZED VIEW IF EXISTS public.%I CASCADE', obj.matviewname);
    END LOOP;

    -- Drop tables
    FOR obj IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
        EXECUTE format('DROP TABLE IF EXISTS public.%I CASCADE', obj.tablename);
    END LOOP;

    -- Drop sequences
    FOR obj IN (SELECT sequence_name FROM information_schema.sequences WHERE sequence_schema = 'public') LOOP
        EXECUTE format('DROP SEQUENCE IF EXISTS public.%I CASCADE', obj.sequence_name);
    END LOOP;

    -- Drop all functions (including overloaded)
    FOR obj IN (
        SELECT p.oid::regprocedure AS full_name
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public' AND p.prokind = 'f'
    ) LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS ' || obj.full_name || ' CASCADE';
    END LOOP;

    -- Drop all procedures (PostgreSQL 11+)
    FOR obj IN (
        SELECT p.oid::regprocedure AS full_name
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public' AND p.prokind = 'p'
    ) LOOP
        EXECUTE 'DROP PROCEDURE IF EXISTS ' || obj.full_name || ' CASCADE';
    END LOOP;

    -- Drop enum types
    FOR obj IN (
        SELECT t.typname
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'public' AND t.typtype = 'e'
    ) LOOP
        EXECUTE format('DROP TYPE IF EXISTS public.%I CASCADE', obj.typname);
    END LOOP;
END
$$;
```

Run using:

```powershell
$env:PGPASSWORD = "Your_Password"
& .\psql.exe -h 51.79.156.217 -U postgres -d qa-dhanman-common -f "C:\path\to\cleanup.sql"
Remove-Item Env:PGPASSWORD
```

Repeat for each DB (`qa-dhanman-community`, etc.)

---

## 🔄 Step 3: Restore into OVH QA from Local `.sql` Files

```powershell
$env:PGPASSWORD = "Your_Password"

# COMMON
.\psql.exe -h 51.79.156.217 -U postgres -d qa-dhanman-common -f "C:\Users\SAI\Desktop\b2aBKqa\qa-common-backup.sql"

# COMMUNITY
.\psql.exe -h 51.79.156.217 -U postgres -d qa-dhanman-community -f "C:\Users\SAI\Desktop\b2aBKqa\qa-community-backup.sql"

# SALES
.\psql.exe -h 51.79.156.217 -U postgres -d qa-dhanman-sales -f "C:\Users\SAI\Desktop\b2aBKqa\qa-sales-backup.sql"

# PURCHASE
.\psql.exe -h 51.79.156.217 -U postgres -d qa-dhanman-purchase -f "C:\Users\SAI\Desktop\b2aBKqa\qa-purchase-backup.sql"

# INVENTORY
.\psql.exe -h 51.79.156.217 -U postgres -d qa-dhanman-inventory -f "C:\Users\SAI\Desktop\b2aBKqa\qa-inventory-backup.sql"

# PAYROLL
.\psql.exe -h 51.79.156.217 -U postgres -d qa-dhanman-payroll -f "C:\Users\SAI\Desktop\b2aBKqa\qa-payroll-backup.sql"

Remove-Item Env:PGPASSWORD
```

---

## ✅ Summary

| Step   | Description                                       |
| ------ | ------------------------------------------------- |
| Step 1 | Export `.sql` backups from Azure QA               |
| Step 2 | Clean all objects in OVH QA DBs (`public` schema) |
| Step 3 | Restore `.sql` backups into OVH QA DBs            |
