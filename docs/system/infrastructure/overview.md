# Infrastructure Overview

Core components
- PostgreSQL (per service)
- RabbitMQ (events/integration)
- MinIO (S3-compatible storage)
- Grafana + Loki + Promtail (logs, dashboards)
- Netdata (+ Cloud) (system metrics)
- Uptime Kuma (HTTP checks)

Environments
- QA and Production on VPS hosts