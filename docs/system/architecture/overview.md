# Architecture Overview

Dhanman is an ERP built with microservices and CQRS:
- Services: Common, MyHome, Sales, Purchase, Inventory, Payroll
- Data: PostgreSQL per bounded context
- Messaging: RabbitMQ for events and integration
- Storage: MinIO for files and attachments
- Frontend: React/TypeScript SPA via API Gateway
- Observability: Promtail + Loki (logs), Grafana (dashboards), Netdata (+ Cloud) for node metrics, Uptime Kuma for uptime

Goals
- Independent deployability, clear bounded contexts
- Separation of write/read paths (CQRS)
- Strong observability
- Secure and multi-tenant ready