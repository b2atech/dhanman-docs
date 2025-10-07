# 🏗️ System Architecture

This section documents the **Dhanman ERP system architecture**, key modules, guiding principles, and core design patterns used across all services.

---

## 📘 Contents

### **Overview**
- [Architecture Overview](overview.md) — High-level view of the system design, microservice boundaries, and data flow.
- [Architecture Principles](principles.md) — Core design principles such as modularity, scalability, and resilience.
- [Design Decisions](design-decisions.md) — Key architectural decisions, rationale, and trade-offs.
- [Deployment & Scalability](deployment-scalability.md) — Infrastructure topology, deployment procedures, and scaling strategies.
- [Security Architecture](security-architecture.md) — Authentication, authorization, data protection, and security best practices.

### **Architecture Decision Records (ADR)**
- [View ADRs](adr/) — Records of significant architectural decisions and rationale.
  - [ADR-0001: Use PostgreSQL 18](adr/0001-use-postgresql-18.md)

### **Diagrams**
- [Rendered Architecture Diagrams](diagrams/rendered/) — Finalized diagrams for presentations and documentation.
- [Source UML Files](diagrams/source/) — PlantUML, Mermaid, or draw.io sources for version-controlled diagrams.

### **Modules**
- [Service-Level Architecture](modules/) — Breakdown of modules such as Sales, Purchase, Inventory, Payroll, and Common.

### **Patterns**
- [CQRS](patterns/cqrs.md) — Command Query Responsibility Segregation pattern applied in Dhanman.
- [Domain-Driven Design](patterns/domain-driven-design.md) — DDD tactical patterns, bounded contexts, and domain modeling.
- [Event Sourcing & Messaging](patterns/event-sourcing.md) — RabbitMQ-based event-driven architecture with MassTransit patterns.
- [Communication Patterns](patterns/communication-patterns.md) — Synchronous and asynchronous inter-service communication.
- [Scheduled Jobs (Hangfire)](patterns/scheduled-jobs.md) — Background job processing and recurring task scheduling.
- [Resilience & Fault Tolerance](patterns/resilience.md) — Circuit breakers, retries, bulkheads, and error handling.

---

## 🧠 Architectural Summary

| Layer | Responsibility | Technology |
|-------|----------------|------------|
| **Presentation Layer** | React/TypeScript frontend for end-user interactions. | React 18, TypeScript, MUI |
| **API Layer** | .NET 9 microservices exposing RESTful endpoints for domain modules. | .NET 9, ASP.NET Core |
| **Application Layer** | CQRS handlers, DTOs, business workflows. | MediatR, FluentValidation |
| **Domain Layer** | Rich domain models, aggregates, domain events. | Pure C# with DDD patterns |
| **Messaging Layer** | RabbitMQ-based event-driven communication between services. | RabbitMQ 3.x |
| **Data Layer** | PostgreSQL 18 databases with schema-per-service and read models. | PostgreSQL 18, EF Core |
| **Storage Layer** | MinIO for document and media storage. | MinIO (S3-compatible) |
| **Job Processing** | Hangfire for background and scheduled tasks. | Hangfire 1.8+ |
| **Authentication** | Auth0 for identity and access management. | Auth0 SaaS |
| **Monitoring & Logging** | Grafana + Loki + Promtail for observability and alerting. | Grafana Stack |

---

## 🎯 Key Architectural Characteristics

### Microservices Architecture
- **6 core services** aligned with bounded contexts
- **Independent deployment** and scaling per service
- **Database per service** for data isolation
- **Event-driven integration** via RabbitMQ

### CQRS & Event Sourcing
- **Separate read and write models** for optimal performance
- **Domain events** published to event bus
- **Event handlers** in consuming services
- **Eventual consistency** across bounded contexts

### Domain-Driven Design
- **Rich domain models** with business logic
- **Aggregates** as consistency boundaries
- **Value objects** for immutable concepts
- **Domain services** for cross-aggregate operations

### Resilience Patterns
- **Retry policies** with exponential backoff
- **Circuit breakers** for failing services
- **Bulkheads** for resource isolation
- **Timeout policies** for bounded waiting
- **Health checks** for service monitoring

### Security
- **Auth0** for authentication with JWT tokens
- **Role-based access control** (RBAC) with permissions
- **Multi-tenancy** with data isolation
- **Encryption** at rest and in transit
- **Audit logging** for compliance

---

## 🔄 Data Flow Example: Invoice Creation

```
1. User submits invoice (Frontend)
   ↓
2. Sales API validates and creates invoice
   ↓
3. Invoice saved to PostgreSQL (Sales DB)
   ↓
4. InvoiceCreatedEvent published to RabbitMQ
   ↓
   ├─▶ 5a. Common Service: Updates ledger entries
   ├─▶ 5b. Notification Service: Sends email to customer
   └─▶ 5c. Analytics Service: Updates dashboard metrics
   ↓
6. Hangfire schedules payment reminder (delayed job)
```

---

## 📐 Design Principles

1. **Business Domain First**: Architecture driven by business capabilities
2. **Evolutionary Design**: Support incremental changes and technological evolution
3. **Cloud-Native**: Designed for containerized deployment and horizontal scalability
4. **Developer Experience**: Balance architectural rigor with developer productivity
5. **Operational Excellence**: Build observability and reliability into the architecture
6. **Security by Design**: Security considerations at every layer
7. **Fail Fast, Recover Quickly**: Resilience patterns for fault tolerance

---

## 🚀 Technology Stack

### Backend
- **.NET 9** (C#) - High-performance, cross-platform
- **ASP.NET Core** - Web API framework
- **Entity Framework Core** - ORM with PostgreSQL provider
- **MediatR** - CQRS implementation
- **FluentValidation** - Input validation

### Frontend
- **React 18** - UI library
- **TypeScript** - Type-safe JavaScript
- **Material-UI (MUI)** - Component library
- **React Query** - Data fetching and caching

### Infrastructure
- **PostgreSQL 18** - Primary database
- **RabbitMQ 3.x** - Message broker
- **MinIO** - Object storage (S3-compatible)
- **Hangfire** - Background job processing
- **Redis** - Distributed caching (planned)

### Observability
- **Grafana** - Dashboards and visualization
- **Loki** - Log aggregation
- **Promtail** - Log shipping
- **Netdata** - System metrics
- **Uptime Kuma** - Uptime monitoring

### DevOps
- **GitHub Actions** - CI/CD pipelines
- **Ansible** - Infrastructure automation
- **NGINX** - Reverse proxy and load balancer
- **Docker** - Containerization (for infrastructure services)
- **Let's Encrypt** - SSL/TLS certificates

---

## 📚 Further Reading

### Getting Started
1. [Architecture Overview](overview.md) - Understand the big picture
2. [Design Decisions](design-decisions.md) - Learn why we made these choices
3. [CQRS Pattern](patterns/cqrs.md) - Understand our command/query separation
4. [Communication Patterns](patterns/communication-patterns.md) - How services talk to each other

### Deep Dives
- [Domain-Driven Design](patterns/domain-driven-design.md) - Rich domain modeling
- [Resilience Patterns](patterns/resilience.md) - Building fault-tolerant systems
- [Security Architecture](security-architecture.md) - Protecting data and users
- [Deployment & Scalability](deployment-scalability.md) - Operations and scaling

### Implementation Guides
- [Scheduled Jobs](patterns/scheduled-jobs.md) - Background task processing
- [Event Sourcing](patterns/event-sourcing.md) - Event-driven integration
- [ADRs](adr/) - Decision records and rationale

---

📘 **Next Step:**  
Start with the [Architecture Overview](overview.md) or check [Diagrams → Source](diagrams/source/) for detailed flow visualizations.
