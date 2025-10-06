# PostgreSQL Setup

- One DB/schema per service (no cross-service FKs)
- Recommended: migrations per service
- Backups: nightly logical dumps; verify restore regularly
- Performance: indexes for hot queries; connection pool sizing
- Security: separate users/roles per service; least privilege