# Dhanman OVH Server Service Management

## 📝 Summary checklist of useful commands

| Action             | Command Example                                            |
| ------------------ | ---------------------------------------------------------- |
| Check status       | `sudo systemctl status <service>`                          |
| Start              | `sudo systemctl start <service>`                           |
| Stop               | `sudo systemctl stop <service>`                            |
| Restart            | `sudo systemctl restart <service>`                         |
| Enable at boot     | `sudo systemctl enable <service>`                          |
| Disable at boot    | `sudo systemctl disable <service>`                         |
| View logs (follow) | `sudo journalctl -u <service> -f`                          |
| List active        | `systemctl list-units --type=service \| grep dhanman`      |
| List all           | `systemctl list-unit-files --type=service \| grep dhanman` |

## 🔹 Service Names

### Prod Services

- `dhanman-common-prod.service`
- `dhanman-community-prod.service`
- `dhanman-document-prod.service`
- `dhanman-inventory-prod.service`
- `dhanman-payroll-prod.service`
- `dhanman-purchase-prod.service`
- `dhanman-sales-prod.service`

### QA Services

- `dhanman-common-qa.service`
- `dhanman-community-qa.service`
- `dhanman-document-qa.service`
- `dhanman-inventory-qa.service`
- `dhanman-payroll-qa.service`
- `dhanman-purchase-qa.service`
- `dhanman-sales-qa.service`

### Test Services

- `dhanman-common-test.service`
- `dhanman-community-test.service`
- `dhanman-document-test.service`
- `dhanman-inventory-test.service`
- `dhanman-payroll-test.service`
- `dhanman-purchase-test.service`
- `dhanman-sales-test.service`

---

## 🔹 Manage all services

### ✅ List all services matching "dhanman"

Copy:

```bash
systemctl list-units --type=service | grep dhanman
```

### ✅ List all services including inactive

Copy:

```bash
systemctl list-unit-files --type=service | grep dhanman
```

---

### 🔍 Check status

#### 🔍 Check status all QA services

Copy:

```bash
sudo systemctl status dhanman-common-qa.service
sudo systemctl status dhanman-community-qa.service
sudo systemctl status dhanman-document-qa.service
sudo systemctl status dhanman-inventory-qa.service
sudo systemctl status dhanman-payroll-qa.service
sudo systemctl status dhanman-purchase-qa.service
sudo systemctl status dhanman-sales-qa.service
```

#### 🔍 Check status all PROD services

Copy:

```bash
sudo systemctl status dhanman-common-prod.service
sudo systemctl status dhanman-community-prod.service
sudo systemctl status dhanman-document-prod.service
sudo systemctl status dhanman-inventory-prod.service
sudo systemctl status dhanman-payroll-prod.service
sudo systemctl status dhanman-purchase-prod.service
sudo systemctl status dhanman-sales-prod.service
```

#### 🔍 Check status all TEST services

Copy:

```bash
sudo systemctl status dhanman-common-test.service
sudo systemctl status dhanman-community-test.service
sudo systemctl status dhanman-document-test.service
sudo systemctl status dhanman-inventory-test.service
sudo systemctl status dhanman-payroll-test.service
sudo systemctl status dhanman-purchase-test.service
sudo systemctl status dhanman-sales-test.service
```

---

### ▶️ Start services

#### ▶️ Start all QA services

Copy:

```bash
sudo systemctl start dhanman-common-qa.service
sudo systemctl start dhanman-community-qa.service
sudo systemctl start dhanman-document-qa.service
sudo systemctl start dhanman-inventory-qa.service
sudo systemctl start dhanman-payroll-qa.service
sudo systemctl start dhanman-purchase-qa.service
sudo systemctl start dhanman-sales-qa.service
```

#### ▶️ Start all PROD services

Copy:

```bash
sudo systemctl start dhanman-common-prod.service
sudo systemctl start dhanman-community-prod.service
sudo systemctl start dhanman-document-prod.service
sudo systemctl start dhanman-inventory-prod.service
sudo systemctl start dhanman-payroll-prod.service
sudo systemctl start dhanman-purchase-prod.service
sudo systemctl start dhanman-sales-prod.service
```

#### ▶️ Start all TEST services

Copy:

```bash
sudo systemctl start dhanman-common-test.service
sudo systemctl start dhanman-community-test.service
sudo systemctl start dhanman-document-test.service
sudo systemctl start dhanman-inventory-test.service
sudo systemctl start dhanman-payroll-test.service
sudo systemctl start dhanman-purchase-test.service
sudo systemctl start dhanman-sales-test.service
```

### 🔴 Stop services

#### 🔴 Stop all QA services

Copy:

```bash
sudo systemctl stop dhanman-common-qa.service
sudo systemctl stop dhanman-community-qa.service
sudo systemctl stop dhanman-document-qa.service
sudo systemctl stop dhanman-inventory-qa.service
sudo systemctl stop dhanman-payroll-qa.service
sudo systemctl stop dhanman-purchase-qa.service
sudo systemctl stop dhanman-sales-qa.service
```

#### 🔴 Stop all PROD services

Copy:

```bash
sudo systemctl stop dhanman-common-prod.service
sudo systemctl stop dhanman-community-prod.service
sudo systemctl stop dhanman-document-prod.service
sudo systemctl stop dhanman-inventory-prod.service
sudo systemctl stop dhanman-payroll-prod.service
sudo systemctl stop dhanman-purchase-prod.service
sudo systemctl stop dhanman-sales-prod.service
```

#### 🔴 Stop all TEST services

Copy:

```bash
sudo systemctl stop dhanman-common-test.service
sudo systemctl stop dhanman-community-test.service
sudo systemctl stop dhanman-document-test.service
sudo systemctl stop dhanman-inventory-test.service
sudo systemctl stop dhanman-payroll-test.service
sudo systemctl stop dhanman-purchase-test.service
sudo systemctl stop dhanman-sales-test.service
```

### 🔄 Restart services

#### 🔄 Restart all QA services

Copy:

```bash
sudo systemctl restart dhanman-common-qa.service
sudo systemctl restart dhanman-community-qa.service
sudo systemctl restart dhanman-document-qa.service
sudo systemctl restart dhanman-inventory-qa.service
sudo systemctl restart dhanman-payroll-qa.service
sudo systemctl restart dhanman-purchase-qa.service
sudo systemctl restart dhanman-sales-qa.service
```

#### 🔄 Restart all PROD services

Copy:

```bash
sudo systemctl restart dhanman-common-prod.service
sudo systemctl restart dhanman-community-prod.service
sudo systemctl restart dhanman-document-prod.service
sudo systemctl restart dhanman-inventory-prod.service
sudo systemctl restart dhanman-payroll-prod.service
sudo systemctl restart dhanman-purchase-prod.service
sudo systemctl restart dhanman-sales-prod.service
```

#### 🔄 Restart all TEST services

Copy:

```bash
sudo systemctl restart dhanman-common-test.service
sudo systemctl restart dhanman-community-test.service
sudo systemctl restart dhanman-document-test.service
sudo systemctl restart dhanman-inventory-test.service
sudo systemctl restart dhanman-payroll-test.service
sudo systemctl restart dhanman-purchase-test.service
sudo systemctl restart dhanman-sales-test.service
```

### ⚙️ Enable services at boot

#### ⚙️ Enable all QA services

Copy:

```bash
sudo systemctl enable dhanman-common-qa.service
sudo systemctl enable dhanman-community-qa.service
sudo systemctl enable dhanman-document-qa.service
sudo systemctl enable dhanman-inventory-qa.service
sudo systemctl enable dhanman-payroll-qa.service
sudo systemctl enable dhanman-purchase-qa.service
sudo systemctl enable dhanman-sales-qa.service
```

#### ⚙️ Enable all PROD services

Copy:

```bash
sudo systemctl enable dhanman-common-prod.service
sudo systemctl enable dhanman-community-prod.service
sudo systemctl enable dhanman-document-prod.service
sudo systemctl enable dhanman-inventory-prod.service
sudo systemctl enable dhanman-payroll-prod.service
sudo systemctl enable dhanman-purchase-prod.service
sudo systemctl enable dhanman-sales-prod.service
```

#### ⚙️ Enable all TEST services

Copy:

```bash
sudo systemctl enable dhanman-common-test.service
sudo systemctl enable dhanman-community-test.service
sudo systemctl enable dhanman-document-test.service
sudo systemctl enable dhanman-inventory-test.service
sudo systemctl enable dhanman-payroll-test.service
sudo systemctl enable dhanman-purchase-test.service
sudo systemctl enable dhanman-sales-test.service
```

### 🔒 Disable services at boot

#### 🔒 Disable all QA services

Copy:

```bash
sudo systemctl disable dhanman-common-qa.service
sudo systemctl disable dhanman-community-qa.service
sudo systemctl disable dhanman-document-qa.service
sudo systemctl disable dhanman-inventory-qa.service
sudo systemctl disable dhanman-payroll-qa.service
sudo systemctl disable dhanman-purchase-qa.service
sudo systemctl disable dhanman-sales-qa.service
```

#### 🔒 Disable all PROD services

Copy:

```bash
sudo systemctl disable dhanman-common-prod.service
sudo systemctl disable dhanman-community-prod.service
sudo systemctl disable dhanman-document-prod.service
sudo systemctl disable dhanman-inventory-prod.service
sudo systemctl disable dhanman-payroll-prod.service
sudo systemctl disable dhanman-purchase-prod.service
sudo systemctl disable dhanman-sales-prod.service
```

#### 🔒 Disable all TEST services

Copy:

```bash
sudo systemctl disable dhanman-common-test.service
sudo systemctl disable dhanman-community-test.service
sudo systemctl disable dhanman-document-test.service
sudo systemctl disable dhanman-inventory-test.service
sudo systemctl disable dhanman-payroll-test.service
sudo systemctl disable dhanman-purchase-test.service
sudo systemctl disable dhanman-sales-test.service
```

### 📜 View logs

#### 📜 View logs all QA services

Copy:

```bash
sudo journalctl -u dhanman-common-qa.service -f
sudo journalctl -u dhanman-community-qa.service -f
sudo journalctl -u dhanman-document-qa.service -f
sudo journalctl -u dhanman-inventory-qa.service -f
sudo journalctl -u dhanman-payroll-qa.service -f
sudo journalctl -u dhanman-purchase-qa.service -f
sudo journalctl -u dhanman-sales-qa.service -f
```

#### 📜 View logs all PROD services

Copy:

```bash
sudo journalctl -u dhanman-common-prod.service -f
sudo journalctl -u dhanman-community-prod.service -f
sudo journalctl -u dhanman-document-prod.service -f
sudo journalctl -u dhanman-inventory-prod.service -f
sudo journalctl -u dhanman-payroll-prod.service -f
sudo journalctl -u dhanman-purchase-prod.service -f
sudo journalctl -u dhanman-sales-prod.service -f
```

#### 📜 View logs all TEST services

Copy:

```bash
sudo journalctl -u dhanman-common-test.service -f
sudo journalctl -u dhanman-community-test.service -f
sudo journalctl -u dhanman-document-test.service -f
sudo journalctl -u dhanman-inventory-test.service -f
sudo journalctl -u dhanman-payroll-test.service -f
sudo journalctl -u dhanman-purchase-test.service -f
sudo journalctl -u dhanman-sales-test.service -f
```

---

## 🐇 RabbitMQ Docker Debugging & Status Check

### 🔍 1. List all running containers

```bash
docker ps
```

> Shows all running containers, including RabbitMQ if active.

---

### 🛑 2. Check all containers (even stopped ones)

```bash
docker ps -a
```

> Lists all containers including stopped RabbitMQ ones. Useful if the container has exited or crashed.

---

### 🐳 3. Start RabbitMQ containers (if stopped)

```bash
docker start rabbitmq-prod
docker start rabbitmq-qa
```

> Restarts your RabbitMQ production and QA containers if they're not running.

---

### 📊 4. Check RabbitMQ container status (from host)

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

> Displays a clean table of container names, their status (`Up`, `Exited`, etc.), and port mappings.

---

### 🧠 5. Access RabbitMQ Management UI in browser

- Prod: http://your-server-ip:15672
- QA: http://your-server-ip:15673

> 📝 Default login:
>
> ```
> Username: guest
> Password: guest
> ```
>
> Note: `guest` user only works from localhost by default.

---

### 🧪 6. Inspect internal RabbitMQ node status

```bash
docker exec -it rabbitmq-prod rabbitmqctl status
docker exec -it rabbitmq-qa rabbitmqctl status
```

> Executes RabbitMQ CLI command inside the container to show node health, running apps, memory usage, etc.

---

### 📦 7. List queues inside RabbitMQ node (optional)

```bash
docker exec -it rabbitmq-prod rabbitmqctl list_queues
docker exec -it rabbitmq-qa rabbitmqctl list_queues
```

> Displays all queues and their message counts.

---

### 🔁 8. Set containers to auto-restart on system reboot

```bash
docker update --restart unless-stopped rabbitmq-prod
docker update --restart unless-stopped rabbitmq-qa
```

> Ensures RabbitMQ containers auto-start after a server reboot or Docker service restart.

---

### 🔐 9. (Optional) Create a non-guest user for remote login

```bash
docker exec -it rabbitmq-prod rabbitmqctl add_user admin strongpassword
docker exec -it rabbitmq-prod rabbitmqctl set_user_tags admin administrator
docker exec -it rabbitmq-prod rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"
```

> `guest` cannot log in remotely — use this to create a new admin user for secure remote access.

---