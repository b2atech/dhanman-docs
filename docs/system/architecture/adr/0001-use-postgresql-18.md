# ADR 0001: Use PostgreSQL 18 as Primary Database

## Status
✅ **Accepted** - Implemented across all services

## Context

Dhanman ERP requires a robust, scalable database system to store:
- Financial transactions and ledger entries (ACID compliance critical)
- Customer, vendor, and employee records
- Purchase orders, invoices, and bills
- Payroll and attendance data
- Community and facility management data
- Audit logs and system events

### Requirements
1. **ACID Compliance**: Financial data requires strong transactional guarantees
2. **Relational Model**: Complex relationships between entities (invoices ↔ line items, POs ↔ GRNs)
3. **JSON Support**: Flexible schema for extensible data (custom fields, metadata)
4. **Performance**: Handle thousands of transactions per day
5. **Multi-tenancy**: Support organization-level data isolation
6. **Open Source**: No licensing costs, community support
7. **Proven Technology**: Battle-tested in production environments
8. **Developer Familiarity**: Team expertise in SQL

## Decision

We will use **PostgreSQL 18** as the primary database for all microservices with streaming replication for high availability.

### Key Factors

#### 1. ACID Compliance
PostgreSQL provides full ACID compliance, critical for financial data:
- **Atomicity**: All ledger entries succeed or fail together
- **Consistency**: Database constraints enforce business rules
- **Isolation**: Concurrent transactions don't interfere
- **Durability**: Committed data persists even with system failures

#### 2. Advanced Features
- **JSON/JSONB**: Store flexible data structures without schema changes
- **Full-Text Search**: Search invoices, POs, and documents
- **Array Types**: Store lists of values efficiently
- **Procedural Extensions (PL/pgSQL)**: Complex business logic in database
- **Generated Columns**: Computed values (e.g., invoice total)
- **Partitioning**: Split large tables by date or tenant
- **CTEs and Window Functions**: Complex analytical queries

#### 3. Performance
- **Excellent query optimizer**: Efficient execution plans
- **Indexes**: B-tree, Hash, GiST, GIN for different use cases
- **Parallel queries**: Utilize multiple CPU cores
- **Connection pooling**: Efficient resource usage
- **Materialized views**: Pre-computed aggregations

#### 4. Scalability & High Availability
- **Streaming replication**: Real-time data replication for HA
- **Read replicas**: Scale read operations
- **Partitioning**: Manage large tables efficiently
- **Logical replication**: Flexible replication topologies

## Implementation Details

### Database Per Service
Each microservice has its own database for data isolation:

```
Production:
- prod-dhanman-common
- prod-dhanman-sales
- prod-dhanman-purchase
- prod-dhanman-payroll
- prod-dhanman-community
- prod-dhanman-inventory

QA:
- qa-dhanman-common
- qa-dhanman-sales
- qa-dhanman-purchase
- qa-dhanman-payroll
- qa-dhanman-community
- qa-dhanman-inventory
```

### PostgreSQL-Specific Features Used

- **JSONB columns** for flexible metadata
- **Array types** for lists (tags, attachments)
- **Full-text search** for document searching
- **Generated columns** for computed fields
- **PL/pgSQL functions** for complex calculations
- **Streaming replication** for high availability

## Consequences

### Positive
✅ **ACID compliance** ensures data integrity for financial transactions  
✅ **Rich feature set** (JSON, arrays, FTS) reduces need for external services  
✅ **Excellent performance** for OLTP workloads  
✅ **Strong community** and extensive documentation  
✅ **Cost-effective** - no licensing fees  
✅ **Cross-platform** - runs on Linux in production  
✅ **Great .NET support** via Entity Framework Core and Npgsql  
✅ **High availability** via streaming replication  

### Negative
⚠️ **Operational overhead** - Requires versioned schema sync across QA/Prod using nightly jobs  
⚠️ **Vertical scaling limits** - Eventual need for horizontal scaling  
⚠️ **Replication lag** - Streaming replication introduces small delays  

### Mitigation Strategies

**For Schema Sync:**
- Automated nightly sync jobs between QA and Prod schemas
- EF Core migrations tracked in version control
- Validation scripts to ensure schema consistency

**For Vertical Scaling:**
- Plan for read replicas when needed
- Implement caching layer (Redis) for frequent reads
- Consider partitioning for large tables

**For Replication Lag:**
- Monitor replication lag metrics
- Use synchronous replication for critical operations if needed
- Design application to handle eventual consistency

## Related Documentation
- [Database Setup](../../infrastructure/database/postgresql-setup.md)
- [Entity Framework Core](../../development/standards/)
- [Multi-tenancy Strategy](../design-decisions.md)

---

**Date**: January 2024  
**Authors**: Architecture Team  
**Status**: Accepted and Implemented
