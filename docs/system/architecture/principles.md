# 🏠 Dhanman OVH VPS Infrastructure – Full Deployment Documentation

---

## 📆 1. Tech Stack Overview

| Layer              | Technology Used                        |
|--------------------|----------------------------------------|
| Backend APIs       | .NET 9                                 |
| Frontend           | React 18 (Vite)                        |
| Database           | PostgreSQL 17                          |
| Auth               | Auth0 (QA + PROD tenants)              |
| Logging            | Serilog → Promtail → Loki              |
| Monitoring         | Grafana, Prometheus, Node/PG Exporter, Uptime Kuma |
| Email              | Zoho Mail (MX), Brevo SMTP             |
| Code Quality       | SonarQube (Community)                  |
| Automation         | Ansible                                |
| CI/CD              | GitHub Actions                         |
| Reverse Proxy      | NGINX + Certbot                        |

---

## 🧰 2. Repositories Overview

| Repository             | Purpose |
|------------------------|---------|
| `dhanman-common`       | Shared organization-level API logic |
| `dhanman-community`    | Housing/residents management |
| `dhanman-inventory`    | Stock and warehouse management |
| `dhanman-payroll`      | Salary and employee management |
| `dhanman-purchase`     | Vendor, PO, GRN, Bills |
| `dhanman-sales`        | Customer billing, invoices |
| `dhanman-react`        | Frontend App |
| `b2a-crosscutting`     | Shared EF Core logic |
| └️ `b2a-permissions`  | Permission handling module |
| └️ `b2a-emailtemplate`| Email templating module |

---

## 🗃️ 3. Database Layout (PostgreSQL 17)

### ✅ Production
- `prod-dhanman-common`
- `prod-dhanman-community`
- `prod-dhanman-inventory`
- `prod-dhanman-payroll`
- `prod-dhanman-purchase`
- `prod-dhanman-sales`

### ✅ QA
- `qa-dhanman-common`
- `qa-dhanman-community`
- `qa-dhanman-inventory`
- `qa-dhanman-payroll`
- `qa-dhanman-purchase`
- `qa-dhanman-sales`

---

## ⚙️ 4. Deployment Architecture

### 🔹 Folder Structure (on OVH)
```
/var/www/
├── prod/
│   ├── dhanman-common/
│   │   ├── .env
│   │   └── logs/dhanman-common-YYYYMMDD.log
│   ├── ...
│   └── logs/
├── qa/
│   ├── dhanman-common/
│   │   ├── .env
│   │   └── logs/dhanman-common-YYYYMMDD.log
│   ├── ...
│   └── logs/
```

### 🔹 Ports
| Env | Service              | Port |
|-----|-----------------------|------|
| QA  | dhanman-common        | 5101 |
| QA  | dhanman-community     | 5102 |
| QA  | dhanman-inventory     | 5103 |
| QA  | dhanman-payroll       | 5104 |
| QA  | dhanman-purchase      | 5105 |
| QA  | dhanman-sales         | 5106 |
| PROD | dhanman-common       | 5001 |
| PROD | dhanman-community    | 5002 |
| PROD | dhanman-inventory    | 5003 |
| PROD | dhanman-payroll      | 5004 |
| PROD | dhanman-purchase     | 5005 |
| PROD | dhanman-sales        | 5006 |

### 🔹 .env Example (Per Service)
```env
ASPNETCORE_ENVIRONMENT=Production
ConnectionStrings__MainDb=Host=...;Database=prod-dhanman-common;...
ConnectionStrings__PermissionsDb=...;
Brevo__ApiKey=...;
Logging__Path=/var/www/prod/logs/
```
- Injected dynamically from GitHub Secrets during deployment.
- Ensures clean separation of environments.

---

## 🚀 5. CI/CD: GitHub Actions

### ✅ QA Deployment
- Triggered on merge to `main`.
- Auto deploys to OVH:
  - SSH
  - Rsync binaries
  - Generate `.env`
  - Restart systemd service

### ✅ PROD Deployment
- Manual via `workflow_dispatch`.
- Uses same logic but run intentionally.

### ✅ Secrets Management
| Secret Name                        | Purpose |
|-----------------------------------|---------|
| `DO_HOST`                         | OVH IP address |
| `DO_USER`                         | SSH user |
| `DO_SSH_KEY`                      | SSH private key |
| `CONNECTIONSTRINGS__PURCHASEDB_QA` | QA DB conn string |
| `CONNECTIONSTRINGS__PURCHASEDB_PROD` | PROD DB conn string |
| `CONNECTIONSTRINGS__PERMISSIONSDB_QA` | Permissions DB |
| `CONNECTIONSTRINGS__PERMISSIONSDB_PROD` | Permissions DB |
| `SONAR_TOKEN`                     | SonarCloud token |

---

## 🔐 6. Authentication with Auth0

- Two tenants: `qa-auth0`, `prod-auth0`
- Custom Actions:
  - Inject `customer_id`, `org_id` in access tokens
- Used in both frontend and backend

---

## 📄 7. Logging Architecture

- **Serilog** (JSON logs)
- Logs written to:
  - `/var/www/prod/logs/*.log`
  - `/var/www/qa/logs/*.log`
- Filename format: `service-name-YYYYMMDD.log`
- Promtail regex extracts service/environment
- Loki aggregates logs
- Grafana dashboards include:
  - Error logs
  - Recent events
  - SQL queries via EF

---

## 📊 8. Monitoring & Metrics

- **Uptime Kuma**: HTTP-based health monitoring
- **Prometheus**:
  - Node Exporter: CPU, RAM, disk
  - PostgreSQL Exporter: query times, active connections
- **Grafana Dashboards**:
  - Live stats
  - Alerts (future enhancement)

---

## 📧 9. Email Setup

- **Zoho Mail**:
  - Mailboxes like `info@dhanman.com`
  - SPF, DKIM, DMARC configured

- **Brevo SMTP**:
  - Used in email template service
  - Injected via `.env`

---

## 🔢 10. Code Quality

- **SonarQube (Community)**:
  - `.NET` and `React` projects
  - Scans run in pipeline
  - Token stored in `SONAR_TOKEN`

---

## 🔧 11. Future Improvements

- [ ] PgBouncer setup for DB pooling
- [ ] Auto backup of PostgreSQL
- [ ] Log archival + rotation
- [ ] Grafana alerts for anomalies
- [ ] Audit logging for user actions

---

## ✅ Summary Table

| Area           | Status            |
|----------------|-------------------|
| APIs           | 6 PROD + 6 QA     |
| Frontend       | React 18 SPA      |
| Authentication | Auth0 (multi-tenant) |
| CI/CD          | GitHub Actions    |
| Logging        | Serilog + Loki    |
| Monitoring     | Prometheus + Kuma |
| Email          | Zoho + Brevo SMTP |
| Code Quality   | SonarQube CI      |
| Deployment     | Ansible + GitHub  |

---
