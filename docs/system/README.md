# System Documentation

Technical documentation for Dhanman ERP system architecture, infrastructure, and operations.

## 📚 Sections

### Architecture
- [Overview](architecture/overview.md)
- [Diagrams](architecture/diagrams/) - Infrastructure and application architecture
- [ADRs](architecture/adr/) - Architecture Decision Records
- [Modules](architecture/modules/) - Per-service architecture

### Infrastructure
- [Servers](infrastructure/servers/) - Production and QA server details
- [Database](infrastructure/database/) - PostgreSQL setup and replication
- [Networking](infrastructure/networking/) - DNS, SSL, firewall configuration

### Development
- [Getting Started](development/getting-started.md)
- [Standards](development/standards/) - Coding standards and best practices
- [Testing](development/testing/) - Testing strategy and guidelines

### Operations
- [Deployment](operations/deployment/) - Deployment procedures
- [Runbooks](operations/runbooks/) - Operational procedures
- [Monitoring](operations/monitoring/) - Monitoring and alerting

## 🏗️ Dhanman Microservices

- dhanman-common (C#) - Shared services, auth, multitenancy
- dhanman-myhome (C#) - Community, gate, water, events
- dhanman-sales (C#) - Financial management, invoicing
- dhanman-purchase (C#) - Vendor and purchase management
- dhanman-inventory (C#) - Asset and inventory management
- dhanman-payroll (C#) - Employee and payroll management
- dhanman-app (React/TypeScript) - Frontend application