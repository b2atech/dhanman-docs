# 🧠 Dhanman QA Monitoring Stack — Full Setup & Troubleshooting Guide

**Applies to:**  
Host: `dhanman-qa` (OVH VPS, Ubuntu)  
Stack: Prometheus + Grafana + Loki + Promtail + RabbitMQ + Node Exporter  

---

## 🔧 1. File Paths & Key Configurations

| Component | Container Name | Config File (Host Path) | Purpose |
|------------|----------------|--------------------------|----------|
| **Prometheus** | `prometheus` | `/home/ubuntu/prometheus.yml` | Scrape metrics from RabbitMQ, Node Exporter, and itself |
| **Loki** | `loki-stack-loki-1` | `/home/ubuntu/loki-stack/loki-config.yaml` | Centralized log store |
| **Promtail** | `promtail` | `/home/ubuntu/loki-stack/promtail-config.yaml` | Log collector for `/var/www/qa/logs` and `/var/www/prod/logs` |
| **Grafana** | `loki-stack-grafana-1` | Docker volume `/var/lib/grafana` | Dashboards for logs and metrics |
| **RabbitMQ** | `rabbitmq-qa` | N/A (managed by Docker) | Message broker; exposes metrics on `15692` |
| **Node Exporter** | `node-exporter` | Runs directly via Docker command | System-level CPU/memory/disk metrics |

---

## ⚙️ 2. Prometheus Configuration (`/home/ubuntu/prometheus.yml`)

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  # Self-monitoring
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  # Node Exporter (host metrics)
  - job_name: "node_exporter"
    static_configs:
      - targets: ["172.17.0.1:9100"]

  # RabbitMQ metrics
  - job_name: "rabbitmq"
    static_configs:
      - targets: ["rabbitmq-qa:15692"]
```

🧠 **Why `172.17.0.1`?**  
Prometheus runs inside Docker. From a container, `localhost` refers to itself. The Docker bridge gateway (`172.17.0.1`) reaches the host machine.

---

## 📄 3. Promtail Configuration (`/home/ubuntu/loki-stack/promtail-config.yaml`)

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki-stack-loki-1:3100/loki/api/v1/push

scrape_configs:
  - job_name: dhanman-logs
    static_configs:
      - targets: [localhost]
        labels:
          env: qa
          __path__: /var/www/qa/logs/dhanman-*.log
      - targets: [localhost]
        labels:
          env: prod
          __path__: /var/www/prod/logs/dhanman-*.log
      - targets: [localhost]
        labels:
          env: test
          __path__: /var/www/test/logs/dhanman-*.log

    pipeline_stages:
      - drop:
          expression: '/metrics'

      - regex:
          expression: '.*/dhanman-(?P<service_name>[a-zA-Z0-9_]+)-\d{8}\.log'
          source: filename

      - replace:
          expression: 'unknown_service'
          replace: 'unmatched'

      - json:
          expressions:
            level: Level
            message: MessageTemplate
            environment: Properties.environment

      - labels:
          env:
          service_name:
          level:
          environment:
```

✅ **Purpose:** Sends QA/Prod/Test logs to Loki with environment + service labels.

---

## 🐇 4. RabbitMQ Configuration

**Container:** `rabbitmq-qa`  
**Image:** `rabbitmq:3.13-management`

RabbitMQ exposes Prometheus metrics on port **15692** using the built-in plugin.

```bash
sudo docker exec -it rabbitmq-qa rabbitmq-plugins enable rabbitmq_prometheus
sudo docker restart rabbitmq-qa
```

Verify:
```bash
curl http://172.19.0.2:15692/metrics | head -n 10
```
✅ Expected: metrics starting with `rabbitmq_…`

---

## 🧍 5. Node Exporter Setup

### Run Node Exporter

```bash
sudo docker run -d \
  --name node-exporter \
  --restart always \
  -p 9100:9100 \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /:/rootfs:ro \
  prom/node-exporter:latest \
  --path.procfs=/host/proc \
  --path.sysfs=/host/sys \
  --collector.filesystem.ignored-mount-points="^/(sys|proc|dev|host|etc)($|/)"
```

Verify:
```bash
curl http://localhost:9100/metrics | head -n 10
```
✅ Expect lines starting with `# HELP node_cpu_seconds_total`.

---

## 📡 6. Docker Networking

| Container | Networks |
|------------|-----------|
| `prometheus` | `bridge`, `prometheus_default` |
| `rabbitmq-qa` | `bridge`, `prometheus_default` |

### Commands Used
```bash
sudo docker network ls
sudo docker network connect prometheus_default prometheus
sudo docker restart prometheus rabbitmq-qa
```

### Verify
```bash
sudo docker exec -it prometheus ping -c 2 rabbitmq-qa
```
✅ Expected: replies from `172.19.0.2`.

---

## 🧪 7. Verification Commands

| Check | Command | Expected |
|--------|----------|-----------|
| **RabbitMQ metrics** | `curl http://172.19.0.2:15692/metrics | head` | Lines with `# HELP rabbitmq_...` |
| **Node Exporter metrics** | `curl http://localhost:9100/metrics | head` | Lines with `# HELP node_cpu_seconds_total` |
| **Prometheus targets** | `http://<QA-IP>:9090/targets` | All 3 targets show **UP** |
| **Loki logs** | Grafana → Explore → Loki | `{env="qa"}` shows logs |
| **Grafana dashboards** | Import IDs `10991` (RabbitMQ) & `1860` (Node Exporter) | Panels display live data |

---

## 🧯 8. Troubleshooting Cheat Sheet

| Issue | Root Cause | Fix |
|--------|-------------|-----|
| Promtail `failed to create client manager` | Missing `clients:` block | Add Loki client URL under `clients:` |
| Prometheus `lookup rabbitmq-qa: no such host` | Containers on different networks | Connect to `prometheus_default` network |
| RabbitMQ dashboard empty | Plugin disabled / wrong IP | Enable `rabbitmq_prometheus` & update target |
| Node Exporter `DOWN` | Using `localhost` inside container | Use `172.17.0.1` instead |
| Port 9100 conflict | Stale process | `sudo lsof -i :9100` → kill PID |
| Grafana logs missing | Promtail regex issue | Check `regex` & `labels` stages |

---

## 🧰 9. Useful Docker & Network Commands

```bash
# List all containers
sudo docker ps -a

# Inspect container networks
sudo docker inspect <container-name> | grep Network

# View logs
sudo docker logs -f <container-name>

# Get container IP
sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <container-name>

# List Docker networks
sudo docker network ls
```

---

## 🧱 10. Future Recommendations

- Combine monitoring stack in one **Docker Compose**:
  - prometheus, loki, promtail, grafana, node-exporter, rabbitmq.
- Add persistent volumes for Prometheus and Loki.
- Backup configs:
  ```bash
  sudo tar -czf /root/monitoring-backup-$(date +%F).tar.gz /home/ubuntu/prometheus.yml /home/ubuntu/loki-stack/
  ```

---

### ✅ Quick Validation Checklist

| Service | URL | Validation |
|----------|-----|-------------|
| Prometheus | `http://54.37.159.71:9090` | `node_exporter`, `rabbitmq`, `prometheus` = UP |
| Grafana | `http://54.37.159.71:3000` | Dashboards 10991 + 1860 load properly |
| RabbitMQ | `http://54.37.159.71:15672` | Web UI accessible |
| Loki Logs | Grafana → Explore → `{env="qa"}` | Recent logs visible |
| Node Exporter | `http://54.37.159.71:9100/metrics` | Shows CPU, memory, disk metrics |

---

🧩 **End of Documentation**  
_Use this guide as your single source of truth for all future monitoring-related troubleshooting on `dhanman-qa`._

