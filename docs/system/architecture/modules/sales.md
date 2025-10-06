# DhanMan Sales Service Architecture

This diagram represents the internal layered architecture of the `Dhanman.Sales` service using the C4 model principles.

---
```plantuml
@startuml
!includeurl https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/v2.7.0/C4_Component.puml

' Tag styles
AddElementTag("application", $bgColor="#42A5F5", $fontColor="white", $shape=RoundedBoxShape())
AddElementTag("domain", $bgColor="#7E57C2", $fontColor="white", $shape=RoundedBoxShape())
AddElementTag("infrastructure", $bgColor="#26A69A", $fontColor="white", $shape=RoundedBoxShape())
AddElementTag("crosscutting", $bgColor="#EF6C00", $fontColor="white", $shape=RoundedBoxShape())

' System boundary
System_Boundary(s1, "Dhanman.Sales") {

  Container_Boundary(api, "Sales.Api (.NET API)", $tags="application") {
    Container(controller, "Controllers", "ASP.NET Controllers", "Handles HTTP requests", $tags="application")
    Container(middleware, "Middleware", ".NET Middleware", "Handles auth, logging, exceptions", $tags="application")
    Container(serviceLayer, "Services", "UserContextService, TokenService", "Shared app-level services", $tags="application")
  }

  Container_Boundary(app, "Sales.Application", $tags="application") {
    Container(cq, "CQ Layer", "Command/Query Interfaces", "Defines use-case entrypoints", $tags="application")
    Container(handlers, "Handlers", "Command & Query Handlers", "Executes business logic", $tags="application")
    Container(features, "Features", "Company, Invoice, Customer, etc.", "App-level features", $tags="application")
    Container(abstractions, "Abstractions", "Interfaces", $tags="application")
    Container(behaviors, "Behaviors", "Caching, Validation, Logging", $tags="application")
    Container(contracts, "Contracts", "DTOs", $tags="application")
  }

  Container_Boundary(domain, "Sales.Domain", $tags="domain") {
    Container(entities, "Entities", "Domain Models", $tags="domain")
    Container(domainAbstractions, "Abstractions", "Domain Interfaces", $tags="domain")
    Container(authz, "Authorization", "Domain-level permissions", $tags="domain")
  }

  Container_Boundary(persistence, "Sales.Persistence", $tags="infrastructure") {
    Container(repos, "Repositories", "InvoiceRepository, etc.", "Implements data access", $tags="infrastructure")
    Container(dbContext, "ApplicationDbContext", "EF Core DbContext", $tags="infrastructure")
    Container(migrations, "Migrations", "EF Core Migrations", $tags="infrastructure")
    ContainerDb(pgsql, "PostgreSQL", "Database", "Holds sales data")
  }

  Container_Boundary(cc, "CrossCuttingConcerns", $tags="crosscutting") {
    Container(logging, "Logging", "Serilog", $tags="crosscutting")
    Container(messaging, "Messaging", "RabbitMQ", $tags="crosscutting")
    Container(monitoring, "Monitoring", "Prometheus", $tags="crosscutting")
    Container(auth0, "Authentication", "Auth0", $tags="crosscutting")
  }
}

' Relationships
Rel(controller, cq, "Calls")
Rel(cq, handlers, "Dispatches to")
Rel(handlers, repos, "Uses")
Rel(repos, dbContext, "Reads/Writes")
Rel(dbContext, pgsql, "Stores in", "SQL")

Rel(handlers, entities, "Modifies")
Rel(handlers, domainAbstractions, "Implements logic with")
Rel(middleware, controller, "Wraps")
Rel(serviceLayer, middleware, "Used by")
Rel(controller, serviceLayer, "Depends on")

Rel(logging, middleware, "Logs via")
Rel(auth0, middleware, "Auth via", "JWT")
Rel(messaging, handlers, "Sends/Receives events")
Rel(monitoring, handlers, "Metrics via")

SHOW_LEGEND()
```


## 🧱 Layered Structure

### 🔹 Sales.Api (`Presentation Layer`)
- **Controllers**: Handle HTTP requests (e.g., `/api/invoices`)
- **Middleware**: Applies cross-cutting logic (logging, exceptions, auth)
- **Services**: Contains reusable components like:
  - `UserContextService`
  - `TokenService`

---

### 🔹 Sales.Application (`Use Case Layer`)
- **Commands / Queries**: Define use-case entry points (CQRS)
- **Handlers**: Execute business logic for each command/query
- **Features**: Modular folders like `Invoice`, `Customer`, `Company`
- **Contracts**: DTOs for API → Application → Domain flow
- **Abstractions**: Interfaces for dependency inversion
- **Behaviors**: Common logic like:
  - Validation
  - Caching
  - Logging

---

### 🔹 Sales.Domain (`Business Logic Layer`)
- **Entities**: Core business models (e.g., `Invoice`, `Customer`)
- **Authorization**: Domain permission logic
- **Abstractions**: Domain-level interfaces to enforce business rules

---

### 🔹 Sales.Persistence (`Infrastructure Layer`)
- **Repositories**: Concrete data access implementations (e.g., `InvoiceRepository`)
- **ApplicationDbContext**: EF Core context for DB operations
- **Migrations**: EF migration history and schema definitions
- **PostgreSQL**: The underlying database for persistence

---

### 🔸 CrossCuttingConcerns (Shared Services)
- **Logging**: Powered by Serilog
- **Messaging**: Event-based communication using RabbitMQ
- **Monitoring**: Exposed via Prometheus metrics
- **Authentication**: Handled externally via Auth0

---

## 🔁 Request-Response Flow

```text
HTTP Request
   ↓
[Controller]
   ↓
[Command / Query Interface]
   ↓
[Handler]
   ↓
[Repository]
   ↓
[DbContext]
   ↓
[PostgreSQL]
```

## 🔗 Supporting Flows

- `Middleware` wraps all requests → handles exceptions, auth, and logging.

- `Handlers` may:
  - Emit messages → via RabbitMQ
  - Log events → via Serilog
  - Update metrics → via Prometheus

- `Services` provide reusable user/session context logic to Controllers.

---

## ✅ Key Benefits

- Separation of concerns between API, use-case, domain, and infra  
- Testable business logic (independent of DB/web)  
- Modular features allow scalability  
- Centralized monitoring, logging, and authentication  

---

This architecture aligns with DhanMan’s broader microservices strategy and adheres to clean architecture principles.

---


