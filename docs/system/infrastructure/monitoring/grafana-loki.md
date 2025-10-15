# 📘 Promtail, Loki, and Grafana Setup Overview

This document explains the roles, flow, and architecture of the **Promtail–Loki–Grafana** stack used in the Dhanman infrastructure for centralized log management.

---

## 🧩 Components and Their Roles

### 1. **Promtail (Log Collector)**
- **Purpose:** Reads and ships log files from servers.
- **Responsibilities:**
  - Watches log files (e.g., `/var/www/prod/logs/*.log`).
  - Adds contextual **labels** like `service`, `env`, and `filename`.
  - Sends log data to **Loki** over HTTP.
- **Example:**
  ```bash
  /var/www/qa/logs/dhanman-purchase-20251015.log → Loki (service=purchase, env=qa)
  ```

---

### 2. **Loki (Log Aggregator / Storage)**
- **Purpose:** Acts as the central database for logs.
- **Responsibilities:**
  - Receives and indexes logs from Promtail.
  - Stores logs efficiently in chunks (like Prometheus for logs).
  - Supports queries using **LogQL** (Loki Query Language).
- **Example Query:**
  ```logql
  {service="purchase", level="Error"}
  ```

---

### 3. **Grafana (Visualizer / Dashboard)**
- **Purpose:** Provides the UI for log exploration and monitoring.
- **Responsibilities:**
  - Connects to Loki as a **data source**.
  - Displays logs in tables, graphs, or custom dashboards.
  - Allows filtering, searching, and alert creation.
- **Example Usage:**
  - Dashboard panels for: *Recent Error Logs*, *Log Count by Service*, *SQL Query Logs*.

---

## ⚙️ Data Flow Summary

1. **Promtail** reads and labels logs.  
2. **Promtail** pushes logs to **Loki**.  
3. **Grafana** queries **Loki** to visualize and analyze logs.

---

## 🖼️ Architecture Diagram (Mermaid)

```mermaid
graph TD
    A[Application Logs<br/>/var/www/{env}/logs/*.log] -->|Tails & Labels| B[Promtail<br/>(Log Collector)]
    B -->|Pushes via HTTP| C[Loki<br/>(Log Aggregator & Storage)]
    C -->|Queries via LogQL| D[Grafana<br/>(Dashboard & Visualization)]

    subgraph Environments
    A
    end

    subgraph Dhanman Infrastructure
    B
    C
    D
    end
```

---

## 🧠 Example: Dhanman QA Setup

| Component | Host / Container | Role |
|------------|------------------|------|
| **Promtail** | `qa` droplet | Collects logs from `/var/www/qa/logs/` |
| **Loki** | Docker container `loki` | Receives and stores logs |
| **Grafana** | Accessible at `https://logs.dhanman.com` | Visualizes logs and metrics |

**Promtail Configuration Snippet:**
```yaml
scrape_configs:
  - job_name: "qa-logs"
    static_configs:
      - targets: ["localhost"]
        labels:
          env: "qa"
          __path__: /var/www/qa/logs/*.log
```

**Loki Endpoint:**
```yaml
url: http://loki:3100/loki/api/v1/push
```

**Grafana Panels:**
- ✅ Recent Error Logs (filtered by service/env)
- 📊 Log Count per Service (QA/PROD)
- 🔍 SQL Query Logs (Entity Framework tracking)

---

## 🧾 Summary Table

| Tool | Function | Acts On | Outputs To |
|------|------------|----------|-------------|
| **Promtail** | Collects logs | Log files | Loki |
| **Loki** | Stores & indexes | Logs | Grafana |
| **Grafana** | Displays & alerts | Loki | Dashboard/UI |

---

## 🚀 Benefits of This Setup
- Centralized log visibility across all services.  
- Easy filtering by environment (QA / PROD) and service name.  
- Lightweight and efficient (no heavy Elasticsearch setup).  
- Integrates seamlessly with existing monitoring (Prometheus, Node Exporter).

---

**Author:** B2A Technologies Pvt. Ltd.  
**Project:** Dhanman Logging & Monitoring Architecture  
**Date:** 2025-10-15
