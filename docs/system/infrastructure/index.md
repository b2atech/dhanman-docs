# 🧱 Infrastructure

This section documents the **server infrastructure, networking, and deployment backbone** of the Dhanman system.  
It includes details on database setup, message brokers, storage systems, and observability tools.

---

## 📘 Contents

### **Overview**
- [Infrastructure Overview](overview.md) — A complete view of server clusters, environments, and deployment topology.

### **Components**
- [Database](database/postgresql-setup.md) — PostgreSQL configuration, replication, and backup strategy.
- [Messaging](messaging/rabbitmq-setup.md) — RabbitMQ setup and exchange/queue conventions.
- [Storage](storage/minio-setup.md) — MinIO-based document and media storage.
- [Monitoring](monitoring/grafana-loki.md) — Logging and metrics using Loki, Promtail, Grafana.

---

## 🖥️ Environment Summary

| Environment | Host | Purpose |
|--------------|------|----------|
| **Production** | `51.79.156.217` | Live deployment with SSL, monitoring, and backups. |
| **QA** | `54.37.159.71` | Testing and pre-production environment. |

---

📘 **Next Step:**  
View the [Infrastructure Overview](overview.md) or dive into [Database Setup](database/postgresql-setup.md).
