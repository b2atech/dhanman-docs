# 🧠 PostgreSQL Query Performance Monitoring & Tuning Guide

> **Purpose:** Quickly identify slow, expensive, or inefficient SQL queries using `pg_stat_statements`.

---

## ⚙️ 0️⃣ Enabling `pg_stat_statements`

Before running any of these queries, ensure it’s enabled in your PostgreSQL configuration.

### 1. Edit `postgresql.conf`:
```bash
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.max = 10000
pg_stat_statements.track = all
```

### 2. Restart PostgreSQL:
```bash
sudo systemctl restart postgresql
```

### 3. Create extension (once per database):
```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

---

## ⚡ 1️⃣ Top 10 Queries by Total Execution Time

👉 Shows which queries consume the most total time overall  
(even if fast but called frequently).

```sql
SELECT
    queryid,
    ROUND(total_exec_time::numeric, 2) AS total_exec_time_ms,
    calls,
    ROUND(mean_exec_time::numeric, 2) AS avg_exec_time_ms,
    ROUND((100 * total_exec_time / SUM(total_exec_time) OVER ())::numeric, 2) AS percent_of_total,
    LEFT(query, 150) AS query_sample
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```

🟢 Use this to spot which SQLs are burning CPU cumulatively.

---

## ⚙️ 2️⃣ Top 10 Queries by Average Execution Time

👉 Finds **slowest individual queries**, even if rarely executed.

```sql
SELECT
    queryid,
    ROUND(mean_exec_time::numeric, 2) AS avg_exec_time_ms,
    calls,
    ROUND(total_exec_time::numeric, 2) AS total_exec_time_ms,
    LEFT(query, 150) AS query_sample
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

🟡 Useful for tuning functions or complex joins.

---

## 🔁 3️⃣ Top 10 Queries by Call Count (Executions)

👉 Identifies **most frequently executed** queries.

```sql
SELECT
    queryid,
    calls,
    ROUND(total_exec_time::numeric, 2) AS total_exec_time_ms,
    ROUND(mean_exec_time::numeric, 2) AS avg_exec_time_ms,
    LEFT(query, 150) AS query_sample
FROM pg_stat_statements
ORDER BY calls DESC
LIMIT 10;
```

🟠 Often highlights repetitive ORM or API patterns.

---

## 💽 4️⃣ Top Queries by I/O Cost (Read-heavy)

👉 Detects **queries hitting disk more than memory** (possible missing indexes).

```sql
SELECT
    queryid,
    shared_blks_hit,
    shared_blks_read,
    ROUND(100 * shared_blks_read::numeric / NULLIF(shared_blks_hit + shared_blks_read, 0), 2) AS read_pct,
    LEFT(query, 150) AS query_sample
FROM pg_stat_statements
ORDER BY shared_blks_read DESC
LIMIT 10;
```

🔴 High `read_pct` = expensive disk I/O → index or caching issue.

---

## 🧩 5️⃣ Queries Sorted by Rows Processed

👉 Finds **queries returning massive datasets** (bad for performance).

```sql
SELECT
    queryid,
    calls,
    rows,
    ROUND(mean_exec_time::numeric, 2) AS avg_exec_time_ms,
    LEFT(query, 150) AS query_sample
FROM pg_stat_statements
ORDER BY rows DESC
LIMIT 10;
```

Useful for detecting heavy report-style queries.

---

## 🕒 6️⃣ Query Performance Over a Time Window

👉 Look at queries **executed recently** (after stats reset or degradation).

```sql
SELECT
    queryid,
    calls,
    ROUND(mean_exec_time::numeric, 2) AS avg_exec_time_ms,
    LEFT(query, 150) AS query_sample
FROM pg_stat_statements
WHERE total_exec_time > 0
ORDER BY mean_exec_time DESC
LIMIT 10;
```

To reset stats and start fresh:
```sql
SELECT pg_stat_statements_reset();
```

Then re-run these queries after a few hours or a day.

---

## 🧮 7️⃣ Query Efficiency (Time per Row)

👉 Detects **inefficient filters or joins** — slow per row processed.

```sql
SELECT
    queryid,
    ROUND(total_exec_time / NULLIF(rows, 0), 2) AS time_per_row_ms,
    rows,
    calls,
    LEFT(query, 150) AS query_sample
FROM pg_stat_statements
WHERE rows > 0
ORDER BY time_per_row_ms DESC
LIMIT 10;
```

---

## 🧹 8️⃣ Reset Statistics (New Analysis Cycle)

⚠️ This clears all accumulated history.

```sql
SELECT pg_stat_statements_reset();
```

Use this before benchmarking changes.

---

## 🧠 9️⃣ Find Queries by Database or User

👉 Separate workloads if multiple services share one PostgreSQL instance.

```sql
SELECT
    datname,
    usename,
    COUNT(*) AS distinct_queries,
    SUM(calls) AS total_calls,
    ROUND(SUM(total_exec_time)::numeric, 2) AS total_exec_time_ms
FROM pg_stat_statements s
JOIN pg_database d ON s.dbid = d.oid
JOIN pg_user u ON s.userid = u.usesysid
GROUP BY datname, usename
ORDER BY total_exec_time_ms DESC;
```

---

## 🧾 🔟 Additional Useful Metrics

### 1. Total execution time across all queries
```sql
SELECT ROUND(SUM(total_exec_time)::numeric, 2) AS total_exec_time_ms FROM pg_stat_statements;
```

### 2. Average execution time overall
```sql
SELECT ROUND(AVG(mean_exec_time)::numeric, 2) AS avg_exec_time_ms FROM pg_stat_statements;
```

### 3. Query latency histogram (approx)
```sql
SELECT
  width_bucket(mean_exec_time, 0, 500, 10) AS bucket,
  COUNT(*) AS queries,
  MIN(mean_exec_time) AS min_ms,
  MAX(mean_exec_time) AS max_ms
FROM pg_stat_statements
GROUP BY bucket
ORDER BY bucket;
```

---

## 📊 1️⃣1️⃣ Integrating with Grafana / Prometheus

- Use **postgres_exporter** and ensure `pg_stat_statements` metrics are enabled.
- Example Prometheus query:
  ```
  pg_stat_statements_mean_exec_time_seconds
  ```
- Build Grafana dashboards:
  - **Top queries by exec time**
  - **Calls per minute**
  - **Cache hit ratio**
  - **Disk reads vs memory hits**

---

## 🧩 1️⃣2️⃣ Cache Hit Ratio (Overall DB Health)

```sql
SELECT
  ROUND((sum(blks_hit)*100 / (sum(blks_hit) + sum(blks_read)))::numeric, 2) AS cache_hit_ratio
FROM pg_statio_user_tables;
```

Ideal ratio: **> 99%** for healthy caching.

---

## 🧰 1️⃣3️⃣ Index Usage Ratio

```sql
SELECT
  schemaname,
  relname,
  ROUND(100 * idx_scan / NULLIF(seq_scan + idx_scan, 0), 2) AS idx_usage_pct,
  seq_scan,
  idx_scan
FROM pg_stat_user_tables
ORDER BY idx_usage_pct ASC;
```

Low index usage (< 90%) → potential missing indexes.

---

## 🔬 1️⃣4️⃣ Table Bloat and Vacuum Stats

```sql
SELECT
    schemaname, relname, n_live_tup, n_dead_tup,
    ROUND(100.0 * n_dead_tup / (n_live_tup + 1), 2) AS dead_pct
FROM pg_stat_user_tables
ORDER BY dead_pct DESC
LIMIT 10;
```

Run `VACUUM (VERBOSE, ANALYZE);` if dead tuples > 10–15%.

---

## 💡 Pro Tips

- Reset stats weekly:
  ```sql
  SELECT pg_stat_statements_reset();
  ```
- Track query changes with **Grafana panels or cron job exports**.
- Focus tuning efforts on:
  - **Top total execution time** queries (high cumulative cost)
  - **High disk I/O** queries (index/caching)
  - **Slow per row** queries (inefficient joins)

---

## 🧩 1️⃣5️⃣ Suggested Monitoring Cycle

| Step | Task | Frequency |
|------|------|------------|
| 1️⃣ | `pg_stat_statements_reset()` | Weekly |
| 2️⃣ | Capture Top 10 by Exec Time, Avg Time, Calls | Daily |
| 3️⃣ | Tune Queries (Indexes, Rewrites) | Continuous |
| 4️⃣ | Measure Cache Hit Ratio & Index Usage | Weekly |
| 5️⃣ | Vacuum/Analyze | Weekly or after large deletes |

---

## 🧾 1️⃣6️⃣ Reference Views

| View | Description |
|------|--------------|
| `pg_stat_statements` | Query-level performance metrics |
| `pg_stat_user_tables` | Table-level stats |
| `pg_statio_user_tables` | Disk I/O per table |
| `pg_locks` | Lock contention tracking |
| `pg_indexes` | Index definitions |

---

### 🧰 Example: Investigating a Slow Query

1. Find it using Top 10 by `mean_exec_time`.
2. Copy the `queryid`.
3. Run `EXPLAIN (ANALYZE, BUFFERS)` on the original SQL.
4. Optimize with:
   - Indexes on JOIN or WHERE columns.
   - Materialized views for reports.
   - Reduced column selection.

---

## 🧭 Summary

- `pg_stat_statements` = the **foundation of PostgreSQL performance tuning**.
- Pair it with:
  - `pg_stat_activity` for live sessions
  - `pg_stat_user_tables` for table-level stats
  - `pg_stat_bgwriter` for checkpoint I/O

---

✨ **Use this file as a ready toolkit for database performance reviews.**
