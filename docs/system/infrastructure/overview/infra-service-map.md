# 🏗 Dhanman Production Infrastructure Map

This document provides a full overview of the Dhanman production server (`dhanman-prod`), detailing which services run in Docker versus directly on the host, along with configuration paths, log locations, and exposed ports.

---

## 🧩 1. Dockerized Services

| Container | Image | Purpose | Ports |
|------------|--------|----------|--------|
| `loki-stack_loki_1` | grafana/loki:latest | Centralized log store | 3100 |
| `loki-stack_promtail_1` | grafana/promtail:2.9.0 | Log collector (tails `/var/www/{env}/logs/*.log`) | Internal |
| `loki-stack_grafana_1` | grafana/grafana:latest | Visualization dashboards (Loki, Prometheus) | 3000 |
| `rabbitmq-prod` | rabbitmq:3-management | Message broker for all services | 5672, 15672 |
| `rabbitmq-exporter` | kbudde/rabbitmq-exporter | RabbitMQ metrics for Prometheus | 9102 |
| `uptime-kuma` | louislam/uptime-kuma:latest | Service uptime monitoring | 3001 |
| `portainer` | portainer/portainer-ce:latest | Docker management UI | 9443 |

**Docker Compose file:**  
`/home/ubuntu/loki-stack/docker-compose.yml`

---

## 🧮 2. Host-Based Services (via systemd)

| Service | Type | Purpose | Port | Config |
|----------|------|----------|------|--------|
| `postgresql@18-main` | PostgreSQL | Core DB for all microservices | 5432 | `/var/lib/postgresql/18/main` |
| `postgres_exporter` | Prometheus Exporter | PostgreSQL metrics for Prometheus | 9187 | `/etc/postgres_exporter/queries_pg_stat_statements.yaml` |
| `prometheus` | Prometheus TSDB | Metrics collection | 9090 | `/etc/prometheus/prometheus.yml` |
| `node_exporter` | Prometheus Exporter | Host metrics (CPU, memory, disk) | 9100 | `/usr/local/bin/node_exporter` |
| `nginx` | Web proxy | Reverse proxy & SSL | 80 / 443 | `/etc/nginx/nginx.conf` |

---

## 🧰 3. Configuration File Map

| Service | Config File | Description |
|----------|--------------|--------------|
| Grafana | `/etc/grafana/grafana.ini` | Global Grafana config |
| Prometheus | `/etc/prometheus/prometheus.yml` | Target scrape definitions |
| Postgres Exporter | `/etc/postgres_exporter/queries_pg_stat_statements.yaml` | Custom SQL metrics (query stats) |
| NGINX | `/etc/nginx/nginx.conf` | Global NGINX config |
| Loki Stack | `/home/ubuntu/loki-stack/docker-compose.yml` | Docker services (Loki, Promtail, Grafana) |

---

## 🗂 4. NGINX Site Configs

Located in `/etc/nginx/sites-enabled/`

Includes:
- `prod.*.dhanman.com` → Production microservices  
- `qa.*.dhanman.com` → QA environment  
- `test.*.dhanman.com` → Test environment  
- `grafana`, `prom.dhanman.com`, `vault.dhanman.com`, `uptime-kuma`, etc.

NGINX handles reverse proxy + SSL termination for all subdomains.

---

## 📊 5. Prometheus Integrations

Prometheus scrapes the following targets:

- `localhost:9187` → PostgreSQL Exporter  
- `localhost:9100` → Node Exporter  
- `localhost:9102` → RabbitMQ Exporter  
- `loki-stack_loki_1` → Loki internal metrics  

Config file: `/etc/prometheus/prometheus.yml`

---

## 🪵 6. Log & Data Paths

| Service | Log Path | Notes |
|----------|-----------|--------|
| PostgreSQL | `/var/log/postgresql/postgresql-18-main.log` | Auto Explain + Query logs |
| Promtail (container) | `/var/www/{qa,prod,test}/logs/` | Scraped by Promtail |
| Prometheus | `/var/lib/prometheus/` | Metric storage |
| Loki | `/opt/loki-data/` (in container) | Log chunks |
| NGINX | `/var/log/nginx/` | Access & error logs |

---

## 🔌 7. Network & Ports

| Port | Service | Description |
|-------|----------|--------------|
| 22 | SSH |
| 80 / 443 | NGINX |
| 5432 | PostgreSQL |
| 9187 | PostgreSQL Exporter |
| 9090 | Prometheus |
| 9100 | Node Exporter |
| 9102 | RabbitMQ Exporter |
| 15672 / 5672 | RabbitMQ |
| 3000 | Grafana |
| 3100 | Loki |
| 3001 | Uptime Kuma |
| 9443 | Portainer |
| 8200 / 8201 | Vault |
| 9000 / 9200 | MinIO |

---

## 🧭 8. Architecture Summary

- **Metrics:** Prometheus + Node Exporter + Postgres Exporter + RabbitMQ Exporter  
- **Logs:** Promtail → Loki → Grafana  
- **Monitoring:** Grafana + Uptime Kuma  
- **Reverse Proxy & SSL:** NGINX (Let’s Encrypt / Certbot)  
- **Data Storage:** PostgreSQL 18-main  
- **Message Broker:** RabbitMQ (Prod vhost)  
- **Secrets Management:** Vault (Prod instance)

---

✅ **Status:** Verified configuration as of *October 18, 2025*
