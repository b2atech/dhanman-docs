## 🛠️ Additional Debugging & Troubleshooting Examples

---

### 🔎 Check for failed services (system-wide)
> Shows all services that are in a failed state.
```bash
systemctl --failed    # List all failed systemd services
```

---

### 🕵️‍♂️ Investigate why a service failed
> Shows the last status, including error messages and exit code.
```bash
systemctl status dhanman-common-qa.service --no-pager    # See full status and last error for service
```
> For more detailed logs:
```bash
journalctl -xeu dhanman-common-qa.service    # See extended error logs for the service
```

---

### 📜 View recent logs for a service
> Shows the last 50 log lines for the service.
```bash
journalctl -u dhanman-common-qa.service -n 50    # Show last 50 log lines
```

---

### 🔄 See all restart, stop, start events for a service
> Filter logs for restart, stop, start, and failure events.
```bash
journalctl -u dhanman-common-qa.service | grep -Ei 'failed|restart|stop|start'
```

---

### 🔌 Check if a port is listening on Ubuntu
> Shows which process (if any) is listening on the given port.
```bash
sudo netstat -tulpn | grep 5673    # Show process listening on port 5673
```
> Or, using `ss` (modern systems):
```bash
sudo ss -tulpn | grep 5673         # Show process listening on port 5673
```

---

### 🧑‍💻 Check resource usage for troubleshooting crashes
> Shows CPU and memory usage for all processes.
```bash
top    # Real-time system monitor; press q to exit
```
> If you have `htop` installed (more user-friendly):
```bash
htop   # Advanced system monitor (install with sudo apt install htop)
```
> Shows RAM usage for a specific service:
```bash
ps aux | grep dhanman-common-qa
```
> Check disk space:
```bash
df -h  # Show disk space usage
```

---

### 🐳 Docker container logs and status

> View last 50 lines of logs for RabbitMQ QA container:
```bash
docker logs rabbitmq-qa --tail 50   # Last 50 log lines for rabbitmq-qa
```
> Follow logs live:
```bash
docker logs -f rabbitmq-qa          # Live log streaming for rabbitmq-qa
```

---

### 🕸️ Test network connectivity to RabbitMQ (from Ubuntu host)
> Check if you can connect to RabbitMQ on port 5673:
```bash
nc -vz localhost 5673    # Test connection to localhost port 5673
```
> For remote hosts, replace `localhost` with the IP.

---

### 🧩 Check core dumps (advanced crash debugging)
> Install core dump tools:
```bash
sudo apt install systemd-coredump    # Install core dump viewer
```
> List all core dumps:
```bash
coredumpctl list                     # List all core dumps
```
> Show info about the latest core dump:
```bash
coredumpctl info                     # Details of the last core dump
```

---

### 🕰️ Check server uptime and reboot history
> See how long the server has been running:
```bash
uptime    # Shows current uptime
```
> Check last reboot time:
```bash
who -b    # Shows last boot time
```
> List all reboot events:
```bash
last reboot    # Shows reboot history
```

---

### 📅 Show last successful run, start, stop, and crash times for a service
> Filter logs for start, stop, crash, and error events:
```bash
journalctl -u dhanman-common-qa.service --since "2 days ago" | grep -Ei 'Starting|Started|Stopped|failed|crash|error'
```

---

## ℹ️ Comment Guide
- Each command includes a brief comment explaining its purpose.
- Replace `<service>` with the actual service name, e.g., `dhanman-common-qa.service`.
- Use these for quick troubleshooting, historical checks, and root cause analysis.