# 🏗️ System Documentation

Technical documentation for the **Dhanman ERP** system — covering its **architecture**, **infrastructure**, **development standards**, **operations**, and **security**.

---

## 📚 Sections

### **Architecture**
- [Overview](architecture/overview.md)
- [Diagrams](architecture/diagrams/)
- [ADRs (Architecture Decision Records)](architecture/adr/)
- [Modules](architecture/modules/)
- [Patterns](architecture/patterns/)

### **Infrastructure**
- [Overview](infrastructure/overview.md)
- [Database Setup](infrastructure/database/postgresql-setup.md)
- [Messaging (RabbitMQ)](infrastructure/messaging/rabbitmq-setup.md)
- [Storage (MinIO)](infrastructure/storage/minio-setup.md)
- [Monitoring (Grafana, Loki)](infrastructure/monitoring/grafana-loki.md)

### **Development**
- [Getting Started](development/getting-started.md)
- [Project Structure](development/project-structure/create-new-project.md)
- [Standards & Guidelines](development/standards/)
- [Entity Management](development/entity-management/create-entity-task.md)
- [API Contracts](development/api-internal/service-contracts.md)
- [Testing](development/testing/)

### **Operations**
- [Deployment Guides](operations/deployment/)
- [Runbooks](operations/runbooks/)
- [Monitoring & Dashboards](operations/monitoring/)

### **Security**
- [Authentication Flow](security/authentication-flow.md)
- [Permissions & Roles](security/permissions-naming-guidelines.md)
- [Secrets Management](security/secrets-management.md)
- [Policies](security/office_etiquette_policy.md)

### **Onboarding**
- [Developer Onboarding](onboarding/developer-onboarding.md)
- [First Contribution](onboarding/first-contribution.md)

---

## 🧩 Dhanman Microservices

| Service | Purpose |
|----------|----------|
| **dhanman-common** | Shared services, authentication, and multitenancy |
| **dhanman-myhome** | Community, gate, water, and events modules |
| **dhanman-sales** | Financial management and invoicing |
| **dhanman-purchase** | Vendor and purchase management |
| **dhanman-inventory** | Asset and inventory tracking |
| **dhanman-payroll** | Employee and payroll management |
| **dhanman-app** | React/TypeScript frontend application |

---

📘 **Next Step:**  
Explore [Architecture → Overview](architecture/overview.md) to understand the system’s overall design.
