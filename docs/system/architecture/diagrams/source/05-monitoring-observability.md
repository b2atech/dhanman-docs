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
