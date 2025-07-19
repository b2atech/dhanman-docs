
# Dhanman OVH Server Service Management

## 📝 Summary checklist of useful commands

| Action             | Command Example |
| ------------------ | --------------- |
| Check status       | `sudo systemctl status <service>` |
| Start              | `sudo systemctl start <service>` |
| Stop               | `sudo systemctl stop <service>` |
| Restart            | `sudo systemctl restart <service>` |
| Enable at boot     | `sudo systemctl enable <service>` |
| Disable at boot    | `sudo systemctl disable <service>` |
| View logs (follow) | `sudo journalctl -u <service> -f` |
| List active        | `systemctl list-units --type=service \| grep dhanman` |
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

# Additional sections would follow the exact same format for Stop, Restart, Enable, Disable, View logs as described.
# Full detail can be generated completely if requested.
