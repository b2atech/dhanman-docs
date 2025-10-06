#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Starting Dhanman Documentation refactor for MkDocs (docs/)..."

ROOT="docs"

echo "📁 Creating directory structure under $ROOT ..."
mkdir -p "$ROOT/system/architecture/diagrams/source"
mkdir -p "$ROOT/system/architecture/diagrams/rendered"
mkdir -p "$ROOT/system/architecture/adr"
mkdir -p "$ROOT/system/architecture/modules"
mkdir -p "$ROOT/system/development/getting-started"
mkdir -p "$ROOT/system/development/standards"
mkdir -p "$ROOT/system/development/project-structure"
mkdir -p "$ROOT/system/development/patterns"
mkdir -p "$ROOT/system/development/testing"
mkdir -p "$ROOT/system/infrastructure/servers"
mkdir -p "$ROOT/system/infrastructure/database"
mkdir -p "$ROOT/system/infrastructure/networking"
mkdir -p "$ROOT/system/operations/deployment"
mkdir -p "$ROOT/system/operations/runbooks"
mkdir -p "$ROOT/system/operations/monitoring"
mkdir -p "$ROOT/system/security"
mkdir -p "$ROOT/product/getting-started"
mkdir -p "$ROOT/product/financial-management"
mkdir -p "$ROOT/product/community"
mkdir -p "$ROOT/product/gate-management"
mkdir -p "$ROOT/product/payroll"
mkdir -p "$ROOT/product/purchase-management"
mkdir -p "$ROOT/product/inventory-assets"
mkdir -p "$ROOT/product/water-management"
mkdir -p "$ROOT/product/events-calendar"
mkdir -p "$ROOT/product/api-reference"

echo "📝 Writing section index pages..."

# docs/system/index.md
cat > "$ROOT/system/index.md" << 'EOF'
# System Documentation

Technical documentation for Dhanman ERP system architecture, infrastructure, and operations.

## Sections

- Architecture
  - [Overview](architecture/)
  - [Diagrams](architecture/diagrams/)
  - [ADRs](architecture/adr/)
  - [Modules](architecture/modules/)
- Infrastructure
  - [Servers](../infrastructure/servers/)
  - [Database](../infrastructure/database/)
  - [Networking](../infrastructure/networking/)
- Development
  - [Getting Started](../development/getting-started/)
  - [Standards](../development/standards/)
  - [Testing](../development/testing/)
- Operations
  - [Deployment](../operations/deployment/)
  - [Runbooks](../operations/runbooks/)
  - [Monitoring](../operations/monitoring/)
- Security
  - [Overview](../security/)

## Dhanman Microservices

- dhanman-common (C#) — Shared services, auth, multitenancy
- dhanman-myhome (C#) — Community, gate, water, events
- dhanman-sales (C#) — Financial management, invoicing
- dhanman-purchase (C#) — Vendor and purchase management
- dhanman-inventory (C#) — Asset and inventory management
- dhanman-payroll (C#) — Employee and payroll management
- dhanman-app (React/TypeScript) — Frontend application
EOF

# docs/system/architecture/index.md
cat > "$ROOT/system/architecture/index.md" << 'EOF'
# Architecture

Dhanman is built using a microservices architecture with the CQRS pattern, deployed on dedicated VPS servers with PostgreSQL replication.

## Components

1. [Diagrams](diagrams/)
2. [ADRs](adr/)
3. [Modules](modules/)
   - [dhanman-common](modules/common.md)
   - [dhanman-myhome](modules/myhome.md)
   - [dhanman-sales](modules/sales.md)
   - [dhanman-purchase](modules/purchase.md)
   - [dhanman-inventory](modules/inventory.md)
   - [dhanman-payroll](modules/payroll.md)
   - [dhanman-app](modules/frontend.md)

## Key Patterns

- CQRS
  - Commands: write operations via MediatR handlers
  - Queries: read operations with optimized data access
  - See: diagrams/source/command-call-flow.puml
- Microservices
  - Independent deployments, per-service DBs
  - RabbitMQ for async messaging
  - API Gateway for external access
- Domain-Driven Design (DDD)
  - Clean Architecture layers
  - Domain models encapsulate business logic
  - Repository pattern for data access

## Infrastructure

- Production: Singapore VPS (51.79.156.217)
- QA: France VPS (54.37.159.71)
- Database: PostgreSQL 18 with streaming replication
- Message Queue: RabbitMQ
- Object Storage: MinIO
- Monitoring: Grafana + Loki + Netdata

## Related

- [Infrastructure Topology](diagrams/source/01-infrastructure-topology-current.md)
- [Development Guidelines](../development/getting-started/)
- [Deployment Procedures](../operations/deployment/)
EOF

# docs/system/architecture/diagrams/source/05-monitoring-observability.md
cat > "$ROOT/system/architecture/diagrams/source/05-monitoring-observability.md" << 'EOF'
````markdown
# Monitoring & Observability Stack

Dhanman uses a comprehensive monitoring stack for system health, logs, and metrics.

```mermaid
graph TB
    subgraph Applications["🖥️ Applications"]
        ProdServices["Production Services<br/>dhanman-*"]
        QAServices["QA Services<br/>qa-dhanman-*"]
    end

    subgraph LogAggregation["📝 Log Aggregation"]
        Promtail["Promtail<br/>Log Shipper"]
        Loki["Loki<br/>Log Storage"]
    end

    subgraph Visualization["📊 Visualization"]
        Grafana["Grafana<br/>Dashboards"]
    end

    subgraph SystemMetrics["📈 System Metrics"]
        Netdata["Netdata<br/>System Monitor"]
        NetdataCloud["Netdata Cloud<br/>Centralized Metrics"]
    end

    subgraph Uptime["✅ Uptime Monitoring"]
        UptimeKuma["Uptime Kuma<br/>Service Health Checks"]
    end

    ProdServices -->|"Logs to file"| Promtail
    QAServices -->|"Logs to file"| Promtail
    Promtail -->|"Ships logs"| Loki
    Loki -->|"Query logs"| Grafana

    ProdServices -->|"System metrics"| Netdata
    QAServices -->|"System metrics"| Netdata
    Netdata -->|"Aggregate"| NetdataCloud

    UptimeKuma -->|"HTTP checks"| ProdServices
    UptimeKuma -->|"HTTP checks"| QAServices

    style Grafana fill:#FF6C37,stroke:#333,stroke-width:3px
    style Loki fill:#FDB714,stroke:#333,stroke-width:3px
    style Netdata fill:#00AB44,stroke:#333,stroke-width:3px
    style UptimeKuma fill:#5CDD8B,stroke:#333,stroke-width:3px