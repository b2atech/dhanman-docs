# 🏗️ System Architecture

This section documents the **Dhanman ERP system architecture**, key modules, guiding principles, and core design patterns used across all services.

---

## 📘 Contents

### **Overview**
- [Architecture Overview](overview.md) — High-level view of the system design, microservice boundaries, and data flow.
- [Architecture Principles](principles.md) — Core design principles such as modularity, scalability, and resilience.

### **Architecture Decision Records (ADR)**
- [View ADRs](adr/) — Records of significant architectural decisions and rationale.

### **Diagrams**
- [Rendered Architecture Diagrams](diagrams/rendered/) — Finalized diagrams for presentations and documentation.
- [Source UML Files](diagrams/source/) — PlantUML, Mermaid, or draw.io sources for version-controlled diagrams.

### **Modules**
- [Service-Level Architecture](modules/) — Breakdown of modules such as Sales, Purchase, Inventory, Payroll, and Common.

### **Patterns**
- [CQRS](patterns/cqrs.md) — Command Query Responsibility Segregation pattern applied in Dhanman.
- [Event Sourcing](patterns/event-sourcing.md) — Approach for maintaining domain history and system consistency.

---

## 🧠 Architectural Summary

| Layer | Responsibility |
|-------|----------------|
| **Presentation Layer** | React/TypeScript frontend for end-user interactions. |
| **API Layer** | .NET 9 microservices exposing RESTful endpoints for domain modules. |
| **Messaging Layer** | RabbitMQ-based event-driven communication between services. |
| **Data Layer** | PostgreSQL 18 databases with schema-per-service and shared read models. |
| **Storage Layer** | MinIO for document and media storage. |
| **Monitoring & Logging** | Grafana + Loki + Promtail for observability and alerting. |

---

📘 **Next Step:**  
Explore the [Architecture Overview](overview.md) or check [Diagrams → Source](diagrams/source/) for detailed flow visualizations.
