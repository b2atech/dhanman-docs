-- ============================================
-- 🔍 PostgreSQL Sequence Integrity Checker & Fixer
-- Scans all identity/serial columns in the DB
-- Prints mismatched sequences (and optionally fixes them)
-- ============================================

DO $$
DECLARE
    -- ⚙️ CONFIGURATION FLAG
    -- Set this to TRUE to automatically fix mismatched sequences
    -- Set to FALSE to only print what needs fixing
    fix_sequences BOOLEAN := FALSE;

    rec RECORD;
    seq_name TEXT;
    tbl_name TEXT;
    col_name TEXT;
    max_id BIGINT;
    curr_val BIGINT;
    fix_sql TEXT;
BEGIN
    RAISE NOTICE '🔎 Checking all identity/serial sequences in database...';
    RAISE NOTICE '⚙️  Auto-fix mode: %', fix_sequences;

    FOR rec IN
        SELECT
            n.nspname AS schema_name,
            c.relname AS table_name,
            a.attname AS column_name,
            pg_get_serial_sequence(format('%I.%I', n.nspname, c.relname), a.attname) AS sequence_name
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        JOIN pg_attribute a ON a.attrelid = c.oid
        WHERE a.attnum > 0
          AND NOT a.attisdropped
          AND (
              a.attidentity IN ('a','d')
              OR pg_get_serial_sequence(format('%I.%I', n.nspname, c.relname), a.attname) IS NOT NULL
          )
          AND c.relkind = 'r'
        ORDER BY n.nspname, c.relname
    LOOP
        seq_name := rec.sequence_name;
        tbl_name := format('%I.%I', rec.schema_name, rec.table_name);
        col_name := rec.column_name;

        IF seq_name IS NULL THEN
            CONTINUE;
        END IF;

        EXECUTE format('SELECT COALESCE(MAX(%I),0) FROM %s', col_name, tbl_name)
        INTO max_id;

        EXECUTE format('SELECT last_value FROM %s', seq_name)
        INTO curr_val;

        IF curr_val <= max_id THEN
            fix_sql := format(
                'SELECT setval(''%s'', %s, true);',
                seq_name,
                max_id + 1
            );

            IF fix_sequences THEN
                EXECUTE fix_sql;
                RAISE NOTICE '🛠️ FIXED → % (seq=%): old=% new_start=%',
                    tbl_name, seq_name, curr_val, max_id + 1;
            ELSE
                RAISE NOTICE '❌ % (seq=%): current=% max=% → FIX SQL: %',
                    tbl_name, seq_name, curr_val, max_id, fix_sql;
            END IF;
        ELSE
            RAISE NOTICE '✅ % (seq=%): current=% max=% → OK',
                tbl_name, seq_name, curr_val, max_id;
        END IF;
    END LOOP;

    RAISE NOTICE '✅ Sequence check complete.';
END $$;
