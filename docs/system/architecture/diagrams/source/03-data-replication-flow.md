# Data Replication & Refresh Flow

```mermaid
sequenceDiagram
    participant ProdDB as PostgreSQL 18 (Prod)
    participant Mirror as PostgreSQL 18 (QA Mirror)
    participant Jenkins as Jenkins CI/CD
    participant QA as PostgreSQL 18 (QA Main)
    participant B2 as Backblaze B2

    ProdDB->>Mirror: WAL Streaming Replication (Async)
    Jenkins->>ProdDB: pg_dump (Nightly / On-demand)
    ProdDB-->>B2: Upload Dump (Encrypted)
    Jenkins->>QA: SCP & Restore Dump
    QA-->>B2: Archive old dumps
    Note over Jenkins,QA: QA Refresh Job executes restore, reindexes DB, and resets permissions.
