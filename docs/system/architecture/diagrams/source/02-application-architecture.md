# Application Architecture – Dhanman Microservices

```mermaid
graph TB
    subgraph Shared["Shared Components"]
        RabbitMQ["🐇 RabbitMQ<br/>Events / Commands"]
        MinIO["📦 MinIO<br/>Document Storage"]
        PG["🗄️ PostgreSQL 18<br/>Databases"]
    end

    subgraph Services["Microservices"]
        Common["🧩 Dhanman.Common<br/>Auth, Multitenancy"]
        Community["🏘️ Dhanman.Community<br/>MyHome, Visitors"]
        Inventory["📦 Dhanman.Inventory<br/>Assets, Stock"]
        Payroll["💰 Dhanman.Payroll<br/>Salaries, Employees"]
        Purchase["🛒 Dhanman.Purchase<br/>Vendors, Orders"]
        Sales["📈 Dhanman.Sales<br/>Invoices, Receipts"]
    end

    subgraph Clients["Clients"]
        WebApp["💻 dhanman-react-ts"]
        Mobile["📱 Resident / Guard Apps"]
    end

    WebApp -->|REST APIs| Services
    Mobile -->|API + Auth0| Common
    Common --> RabbitMQ
    Services --> RabbitMQ
    Services --> MinIO
    Services --> PG
    RabbitMQ --> Common
