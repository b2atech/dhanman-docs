## 🛠️ Additional Debugging & Troubleshooting Examples

> **Troubleshooting Sequence**: Follow this logical progression from basic system checks to advanced debugging techniques.

---

### � Set Docker containers to auto-restart (unless stopped manually)

> Configure containers for resilience after debugging.

```bash
docker update --restart=unless-stopped dc2e017a761c   # Set Grafana to auto-restart
docker update --restart=unless-stopped 25f887b8c4b4   # Set Loki to auto-restart
docker update --restart=unless-stopped 490ec2335d55   # Set Promtail to auto-restart
docker update --restart=unless-stopped 2793193cd3f7   # Set RabbitMQ to auto-restart
docker update --restart=unless-stopped <jenkins_id>   # Set Jenkins to auto-restart
```

---

## 🔍 **Phase 1: System Health Overview**

### 🕰️ Check server uptime and reboot history

> Start with understanding the system's current state and recent activity.

```bash
uptime           # Shows current uptime and load average
who -b           # Shows last boot time
last reboot      # Shows reboot history
```

---

### 🧑‍💻 Check resource usage for troubleshooting crashes

> Identify if resource constraints are causing issues.

```bash
top              # Real-time system monitor; press q to exit
htop             # Advanced system monitor (install with sudo apt install htop)
df -h            # Show disk space usage
free -h          # Show memory usage
```

> Check specific service resource usage:

```bash
ps aux | grep dhanman-common-qa    # Shows RAM/CPU usage for specific service
```

---

## 🔧 **Phase 2: Service Status Investigation**

### 🔎 Check for failed services (system-wide)

> Get an overview of all system service issues.

```bash
systemctl --failed    # List all failed systemd services
```

---

### 🕵️‍♂️ Investigate why a service failed

> Deep dive into specific service failures.

```bash
systemctl status dhanman-common-qa.service --no-pager    # See full status and last error
journalctl -xeu dhanman-common-qa.service               # See extended error logs
```

---

### 📜 View recent logs for a service

> Analyze recent service activity and patterns.

```bash
journalctl -u dhanman-common-qa.service -n 50           # Show last 50 log lines
journalctl -u dhanman-common-qa.service --since "1 hour ago"  # Show recent logs
```

---

### � Show last successful run, start, stop, and crash times for a service

> Track service lifecycle events and identify patterns.

```bash
journalctl -u dhanman-common-qa.service --since "2 days ago" | grep -Ei 'Starting|Started|Stopped|failed|crash|error'
```

---

### 🔄 See all restart, stop, start events for a service

> Filter for service state changes to understand behavior patterns.

```bash
journalctl -u dhanman-common-qa.service | grep -Ei 'failed|restart|stop|start'
```

---

## 🌐 **Phase 3: Network & Connectivity Checks**

### 🔌 Check if a port is listening on Ubuntu

> Verify if services are properly bound to expected ports.

```bash
sudo netstat -tulpn | grep 5673    # Show process listening on port 5673
sudo ss -tulpn | grep 5673         # Modern alternative using ss command
```

---

### �️ Test network connectivity to RabbitMQ (from Ubuntu host)

> Validate network connectivity to critical services.

```bash
nc -vz localhost 5673    # Test connection to localhost port 5673
nc -vz <remote_ip> 5673  # Test connection to remote host (replace <remote_ip>)
```

---

## 🐳 **Phase 4: Docker Container Debugging**

### 🐳 Docker container logs and status

> Investigate containerized service issues.

```bash
docker ps -a                        # Show all containers and their status
docker logs rabbitmq-qa --tail 50   # Last 50 log lines for specific container
docker logs -f rabbitmq-qa          # Live log streaming
docker stats                        # Real-time container resource usage
```

---

## 🧩 **Phase 5: Advanced Debugging (When Standard Methods Fail)**

### 🧩 Check core dumps (advanced crash debugging)

> Investigate application crashes at the system level.

```bash
sudo apt install systemd-coredump    # Install core dump viewer
coredumpctl list                     # List all core dumps
coredumpctl info                     # Details of the last core dump
coredumpctl dump <PID> > core.dump   # Export specific core dump for analysis
```

---

## ℹ️ Comment Guide

- Each command includes a brief comment explaining its purpose.
- Replace `<service>` with the actual service name, e.g., `dhanman-common-qa.service`.
- Use these for quick troubleshooting, historical checks, and root cause analysis.
