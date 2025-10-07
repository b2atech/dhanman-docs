# Architecture Design Decisions

## Overview

This document captures key architectural design decisions, their rationale, trade-offs, and implications for the Dhanman ERP system. These decisions shape the system's structure, technology choices, and operational characteristics.

---

## Design Philosophy

### Core Principles

1. **Business Domain First**: Architecture driven by business capabilities and bounded contexts
2. **Evolutionary Design**: Support incremental changes and technological evolution
3. **Cloud-Native**: Designed for containerized deployment and horizontal scalability
4. **Developer Experience**: Balance architectural rigor with developer productivity
5. **Operational Excellence**: Build observability and reliability into the architecture

---

## Key Architectural Decisions

### 1. Microservices Architecture

**Decision**: Adopt microservices architecture over monolithic design

**Context:**
- Dhanman serves multiple business domains (Sales, Purchase, Payroll, Community)
- Need for independent deployment and scaling
- Multiple teams working on different features
- Different services may have different scaling requirements

**Rationale:**
- **Bounded Context Alignment**: Each service maps to a domain bounded context
- **Independent Deployment**: Deploy services without affecting others
- **Technology Flexibility**: Choose appropriate technology per service
- **Scalability**: Scale services based on individual load patterns
- **Team Autonomy**: Teams own services end-to-end

**Trade-offs:**

| Advantages | Disadvantages |
|------------|---------------|
| Independent deployment | Increased operational complexity |
| Better scalability | Network latency between services |
| Technology diversity | Distributed system challenges |
| Fault isolation | More complex testing |
| Team autonomy | Data consistency challenges |

**Alternatives Considered:**
- **Monolithic**: Rejected due to coupling and scaling limitations
- **Modular Monolith**: Considered but rejected for deployment flexibility needs
- **Service-Oriented Architecture (SOA)**: Too heavyweight with ESB requirements

**Implementation:**
```
Microservices:
- dhanman-common (Auth, Notifications, Ledger)
- dhanman-sales (Invoicing, Receipts)
- dhanman-purchase (Procurement, Bills)
- dhanman-payroll (Salaries, Employees)
- dhanman-community (Residents, Facilities)
- dhanman-inventory (Assets, Stock)
```

**Status**: ✅ Implemented

---

### 2. Event-Driven Architecture with RabbitMQ

**Decision**: Use RabbitMQ for asynchronous event-driven communication

**Context:**
- Services need to communicate without tight coupling
- Business workflows span multiple services
- Need for eventual consistency
- Requirement for audit trail and event history

**Rationale:**
- **Decoupling**: Services don't need direct knowledge of consumers
- **Asynchronous Processing**: Non-blocking operations improve responsiveness
- **Scalability**: Message broker handles load spikes
- **Reliability**: Persistent messages ensure no data loss
- **Integration**: Easy to add new services as event consumers

**Trade-offs:**

| Advantages | Disadvantages |
|------------|---------------|
| Loose coupling | Eventual consistency |
| Scalability | More complex debugging |
| Reliability | Message ordering challenges |
| Asynchronous processing | Requires message broker infrastructure |
| Event history | Potential message duplication |

**Why RabbitMQ over alternatives:**

**vs Apache Kafka:**
- RabbitMQ better for traditional message queuing
- Lower operational complexity
- Sufficient throughput for current needs
- Better routing capabilities

**vs Azure Service Bus:**
- RabbitMQ is open-source and cloud-agnostic
- Lower costs
- More control over infrastructure
- Similar features for our use cases

**vs AWS SQS/SNS:**
- Avoid cloud vendor lock-in
- Can deploy on-premises or any cloud
- More features (exchange types, routing)

**Implementation Details:**
```yaml
Exchanges:
  - dhanman.events (fanout) - Domain events
  - dhanman.commands (direct) - Service commands

Queues per Service:
  - {service}.events
  - {service}.commands
  - {service}.dlq (dead-letter queue)

Message Patterns:
  - Publish-Subscribe (events)
  - Point-to-Point (commands)
  - Request-Reply (synchronous operations)
```

**Status**: ✅ Implemented

---

### 3. CQRS (Command Query Responsibility Segregation)

**Decision**: Implement CQRS pattern using MediatR

**Context:**
- Different performance characteristics for reads vs writes
- Complex business logic for write operations
- Need for optimized read models
- Support for event sourcing

**Rationale:**
- **Separation of Concerns**: Read and write models optimized independently
- **Scalability**: Scale read and write sides separately
- **Performance**: Optimized queries without business logic overhead
- **Maintainability**: Clear structure for operations
- **Flexibility**: Different data models for reads vs writes

**Trade-offs:**

| Advantages | Disadvantages |
|------------|---------------|
| Optimized performance | Increased complexity |
| Clear separation | More code to maintain |
| Independent scaling | Potential data staleness |
| Better testability | Learning curve |

**Why MediatR:**
- Proven .NET library
- In-process messaging (low latency)
- Clean handler pattern
- Pipeline behaviors for cross-cutting concerns
- Good community support

**Implementation Pattern:**
```csharp
Commands (Write):
  CreateInvoiceCommand → CreateInvoiceCommandHandler
  - Validates business rules
  - Modifies domain entities
  - Publishes domain events
  - Returns Result<T>

Queries (Read):
  GetInvoiceByIdQuery → GetInvoiceByIdQueryHandler
  - Bypasses domain model
  - Reads optimized projections
  - Returns DTOs
  - No side effects
```

**Status**: ✅ Implemented

---

### 4. PostgreSQL as Primary Database

**Decision**: Use PostgreSQL 18 as the primary database for all services

**Context:**
- Need for relational data model
- ACID transactions required
- JSON support for flexible schemas
- Open-source preference
- Multi-tenancy support

**Rationale:**
- **Maturity**: Battle-tested, reliable RDBMS
- **Features**: JSON/JSONB, full-text search, GIS support
- **Performance**: Excellent query performance
- **Cost**: Open-source, no licensing fees
- **Scalability**: Read replicas, partitioning support
- **Community**: Large community, extensive documentation

**Trade-offs:**

| Advantages | Disadvantages |
|------------|---------------|
| ACID compliance | Vertical scaling limits |
| Rich feature set | Complex sharding |
| JSON support | Not ideal for document storage |
| Open-source | Manual operational overhead |

**Database Per Service:**
```
Production:
- prod-dhanman-common
- prod-dhanman-sales
- prod-dhanman-purchase
- prod-dhanman-payroll
- prod-dhanman-community
- prod-dhanman-inventory

QA:
- qa-dhanman-common
- qa-dhanman-sales
- ... (similar structure)
```

**Why not NoSQL:**
- Accounting requires ACID transactions
- Complex relational queries needed
- Data integrity critical for financial records
- Team expertise in SQL

**Status**: ✅ Implemented

---

### 5. Domain-Driven Design (DDD)

**Decision**: Apply DDD tactical patterns in domain layer

**Context:**
- Complex business domain with specific rules
- Need for rich domain model
- Multiple bounded contexts
- Business logic centralization

**Rationale:**
- **Business Alignment**: Code reflects business concepts
- **Ubiquitous Language**: Shared vocabulary between team and domain experts
- **Encapsulation**: Business logic in domain entities
- **Maintainability**: Clear domain boundaries
- **Testability**: Domain logic testable in isolation

**DDD Patterns Applied:**
```
✅ Entities - Objects with identity (Invoice, PurchaseOrder)
✅ Value Objects - Immutable objects (Money, Address)
✅ Aggregates - Consistency boundaries (Invoice + LineItems)
✅ Domain Events - Business occurrences (InvoiceCreated)
✅ Repositories - Persistence abstraction
✅ Domain Services - Cross-aggregate operations
✅ Bounded Contexts - Service boundaries
```

**Trade-offs:**

| Advantages | Disadvantages |
|------------|---------------|
| Business alignment | Learning curve |
| Rich domain model | More code |
| Clear boundaries | Can be over-engineered |
| Testable | Requires domain expertise |

**Status**: ✅ Implemented

---

### 6. Hangfire for Scheduled Jobs

**Decision**: Use Hangfire for background job processing and scheduling

**Context:**
- Need for reliable background job processing
- Scheduled tasks (e.g., monthly invoice generation)
- Delayed jobs (e.g., payment reminders)
- Job monitoring and management

**Rationale:**
- **Persistence**: Jobs survive application restarts
- **Dashboard**: Built-in monitoring UI
- **Retry Logic**: Automatic retry with exponential backoff
- **Flexibility**: Fire-and-forget, delayed, recurring jobs
- **Integration**: Works well with PostgreSQL

**Why Hangfire over alternatives:**

**vs Quartz.NET:**
- Hangfire has better dashboard
- Simpler configuration
- Better persistence options

**vs Azure Functions:**
- Avoid cloud lock-in
- More control over execution
- Lower costs

**vs Custom Solution:**
- Don't reinvent the wheel
- Proven reliability
- Active maintenance

**Job Types Used:**
```
Fire-and-Forget: Email notifications
Delayed: Payment reminders
Recurring: Monthly invoice generation, daily reports
Continuations: Sequential workflows
Batches: Bulk operations
```

**Status**: ✅ Implemented

---

### 7. Auth0 for Authentication

**Decision**: Use Auth0 for authentication and authorization

**Context:**
- Need for secure authentication
- OAuth2/OIDC support required
- Multi-tenancy requirements
- Social login support

**Rationale:**
- **Security**: Industry-standard security practices
- **Features**: MFA, SSO, social logins
- **Multi-tenancy**: Separate tenants for QA and Production
- **Maintenance**: Managed service, no security patches to apply
- **Compliance**: SOC2, HIPAA compliance

**Trade-offs:**

| Advantages | Disadvantages |
|------------|---------------|
| Managed security | Vendor lock-in |
| Rich features | Costs scale with users |
| Compliance | External dependency |
| Quick implementation | Limited customization |

**Implementation:**
```
Tenants:
- qa-auth0 (QA environment)
- prod-auth0 (Production)

Custom Actions:
- Inject customer_id, org_id in tokens
- Custom claims for roles

Integration:
- Frontend: Auth0 React SDK
- Backend: JWT Bearer authentication
```

**Status**: ✅ Implemented

---

### 8. .NET 9 for Backend Services

**Decision**: Use .NET 9 (C#) for all backend microservices

**Context:**
- Need for high-performance backend
- Cross-platform deployment
- Modern language features
- Team expertise

**Rationale:**
- **Performance**: Excellent throughput and low latency
- **Productivity**: Modern C# features, strong typing
- **Ecosystem**: Rich library ecosystem
- **Cross-platform**: Runs on Linux (production servers)
- **Long-term Support**: Microsoft backing

**Why .NET over alternatives:**

**vs Node.js:**
- Better performance for CPU-intensive tasks
- Stronger typing
- Better tooling (Visual Studio, Rider)

**vs Java:**
- More modern language features
- Better async/await support
- Lighter memory footprint

**vs Python:**
- Much better performance
- Strong typing
- Better for financial calculations

**Status**: ✅ Implemented

---

### 9. React + TypeScript for Frontend

**Decision**: Use React with TypeScript for the web application

**Context:**
- Need for rich, interactive UI
- Single-page application requirements
- Team preference and expertise
- Strong ecosystem

**Rationale:**
- **Component Model**: Reusable UI components
- **Type Safety**: TypeScript catches errors at compile time
- **Ecosystem**: Large library ecosystem (MUI, React Query)
- **Performance**: Virtual DOM for efficient updates
- **Developer Experience**: Great tooling and debugging

**Technology Stack:**
```
- React 18
- TypeScript
- Material-UI (MUI)
- React Query (data fetching)
- React Router (routing)
- Vite (build tool)
```

**Status**: ✅ Implemented

---

### 10. Clean Architecture / Layered Architecture

**Decision**: Organize code in clean architecture layers

**Context:**
- Need for maintainable codebase
- Clear separation of concerns
- Testability requirements
- Technology independence

**Layers:**
```
1. Domain Layer (Core)
   - Entities, Value Objects, Aggregates
   - Domain Events, Interfaces
   - No external dependencies

2. Application Layer
   - CQRS handlers (Commands, Queries)
   - DTOs, Mappers, Validators
   - Depends on Domain

3. Infrastructure Layer
   - EF Core implementations
   - RabbitMQ, External APIs
   - Depends on Domain and Application

4. API/Presentation Layer
   - Controllers, SignalR hubs
   - Request/Response models
   - Depends on Application
```

**Benefits:**
- **Testability**: Domain logic testable without infrastructure
- **Maintainability**: Clear responsibilities
- **Flexibility**: Can swap implementations
- **Independence**: Business logic isolated from frameworks

**Status**: ✅ Implemented

---

### 11. MinIO for Object Storage

**Decision**: Use MinIO for document and file storage

**Context:**
- Need for scalable file storage
- PDF invoices, images, documents
- S3-compatible API preferred
- Self-hosted requirement

**Rationale:**
- **S3 Compatible**: Standard API
- **Self-hosted**: Control over data
- **Performance**: Fast file access
- **Scalability**: Distributed storage support

**Why MinIO:**
- Open-source
- Production-ready
- Easy deployment
- No vendor lock-in

**Use Cases:**
```
- Invoice PDFs
- Payslip documents
- User profile images
- Import/export files
- Backup archives
```

**Status**: ✅ Implemented

---

### 12. Grafana + Loki + Promtail for Observability

**Decision**: Use Grafana stack for logging and monitoring

**Context:**
- Need for centralized logging
- Service health monitoring
- Performance metrics tracking
- Alert management

**Components:**
```
Promtail: Log collection from services
Loki: Log aggregation and storage
Grafana: Visualization and dashboards
Prometheus: Metrics collection (planned)
Netdata: System-level metrics
```

**Why this stack:**
- Open-source
- Lightweight (compared to ELK stack)
- Good integration between components
- Excellent visualization (Grafana)
- Cost-effective

**Status**: ✅ Implemented

---

### 13. API Gateway Pattern (Future)

**Decision**: Plan to implement API Gateway using NGINX/Ocelot

**Context:**
- Currently using NGINX as reverse proxy
- Need for centralized routing
- Rate limiting requirements
- Authentication/authorization enforcement

**Planned Features:**
```
- Request routing
- Load balancing
- Rate limiting
- Authentication
- Response caching
- API versioning
```

**Status**: 🔄 Planned

---

### 14. Multi-tenancy Strategy

**Decision**: Database-per-tenant with schema isolation

**Context:**
- Need for data isolation
- Performance requirements
- Compliance and security
- Scalability considerations

**Strategy:**
```
Organization Level:
- Each organization has org_id
- Row-level security via filters
- Shared database schema
- Custom database per organization (optional)

Tenant Identification:
- JWT claims (org_id, customer_id)
- Global query filters in EF Core
- Tenant resolver middleware
```

**Benefits:**
- Data isolation
- Performance optimization
- Cost-effective
- Easier backups per tenant

**Status**: ✅ Implemented

---

## Technology Stack Summary

| Layer | Technology | Version | Status |
|-------|-----------|---------|--------|
| **Backend** | .NET | 9 | ✅ |
| **Frontend** | React | 18 | ✅ |
| **Language** | TypeScript | 5.x | ✅ |
| **Database** | PostgreSQL | 18 | ✅ |
| **Messaging** | RabbitMQ | 3.x | ✅ |
| **Caching** | Redis | 7.x | 🔄 Planned |
| **Object Storage** | MinIO | Latest | ✅ |
| **Job Scheduling** | Hangfire | 1.8+ | ✅ |
| **Authentication** | Auth0 | - | ✅ |
| **Logging** | Loki + Promtail | Latest | ✅ |
| **Monitoring** | Grafana + Netdata | Latest | ✅ |
| **Reverse Proxy** | NGINX | Latest | ✅ |
| **CI/CD** | GitHub Actions | - | ✅ |
| **Infrastructure** | Ansible | Latest | ✅ |

---

## Decision Process

When making architectural decisions, we consider:

1. **Business Requirements**: Does it solve the business problem?
2. **Technical Fit**: Does it align with existing architecture?
3. **Team Capability**: Can the team implement and maintain it?
4. **Cost**: What are the licensing and operational costs?
5. **Scalability**: Will it scale with growth?
6. **Risk**: What are the risks and mitigation strategies?
7. **Alternatives**: What other options exist?

---

## Future Considerations

### Under Evaluation

- **Caching Strategy**: Redis for distributed caching
- **API Gateway**: Ocelot or custom gateway
- **Service Mesh**: Istio or Linkerd for advanced routing
- **Event Sourcing**: Full event sourcing for audit trail
- **GraphQL**: Alternative API query language
- **gRPC**: For internal service-to-service communication

### Deferred

- **Kubernetes**: Current deployment works well, defer until scale requires it
- **Cloud Migration**: Stay on VPS until growth requires cloud scalability
- **Microservices Split**: Current services are appropriate size

---

## Related Documentation
- [Architecture Overview](../overview.md)
- [Patterns](./README.md)
- [ADRs](../adr/)

---

## Summary

Dhanman's architecture decisions prioritize:
- **Business alignment** through DDD and bounded contexts
- **Scalability** via microservices and event-driven design
- **Reliability** with proven technologies (PostgreSQL, RabbitMQ, .NET)
- **Operational excellence** through observability and automation
- **Developer productivity** with modern tools and patterns
- **Flexibility** to evolve with business needs

These decisions form a solid foundation for a scalable, maintainable ERP system that can grow with the business.
