# 🏗 Infrastructure Overview

Dhanman runs on **OVH Cloud VPS servers** for QA and Production.

| Environment | Location | IP Address | Purpose |
|--------------|-----------|-------------|----------|
| **Production** | Singapore | `51.79.156.217` | Live customer environment |
| **QA** | France | `54.37.159.71` | Pre-production / testing |

Provisioning, deployment, and monitoring are managed centrally from **Raigad (WSL)** via **Ansible** playbooks.

---

## 🔧 Components at a Glance

| Layer | Technology | Description |
|-------|-------------|-------------|
| **Application** | .NET 9 Microservices | Common, Sales, Purchase, Payroll, Inventory, Community, Document, Payment |
| **Database** | PostgreSQL 18 | Separate DB per service and environment |
| **Messaging** | RabbitMQ | Environment-specific vhosts; integrated with MassTransit |
| **Storage** | MinIO | Document storage |
| **Monitoring** | Prometheus, Loki, Grafana, Uptime Kuma | Metrics, logs, dashboards |
| **Security** | Vault, UFW, Certbot | Secrets, firewall, SSL |
| **Automation** | Ansible, Jenkins, GitHub Actions | CI/CD and environment provisioning |

---

## 📍 Infrastructure Layers

- **Deployment Architecture & Scalability:**  
  → [deployment-scalability.md](deployment-scalability.md)  
  Covers full topology diagrams, NGINX configs, CI/CD pipelines, and scaling roadmap.

- **Infrastructure Service Map:**  
  → [overview/infra-service-map.md](overview/infra-service-map.md)  
  Live mapping of all running services (Docker + systemd), ports, configs, and exporters.

- **Monitoring & Observability:**  
  → [monitoring/postgres_query_monitoring.md](../monitoring/postgres_query_monitoring.md)  
  Explains query-level performance tracking and Prometheus integration.

- **Disaster Recovery:**  
  → [scripts/dr-audit-extended.md](../scripts/dr-audit-extended.md)  
  Details nightly Backblaze snapshot automation (`dr-audit-extended.sh`).

---

## 🚀 Management Approach

- **Configuration:** Managed through Ansible (`~/dhanman-infra/ansible/roles`)
- **Secrets:** Stored in HashiCorp Vault (Prod and QA isolated)
- **SSL:** Automated renewal via Certbot + NGINX reload
- **Logging:** Centralized via Loki stack (`logs.dhanman.com`)
- **Backups:** Daily via audit script, uploaded to Backblaze B2

---

✅ *For a full list of live services, containers, and ports — see [Infrastructure Service Map](overview/infra-service-map.md).*
