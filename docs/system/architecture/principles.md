# Architectural Principles

- Bounded Contexts: one service per business capability
- Single Ownership: each service owns its database schema
- CQRS: separate write (commands) and read (queries) flows
- Event-Driven: use RabbitMQ for cross-service coordination
- Clean Architecture: domain-centric, adapters at boundaries
- Resilience: idempotent consumers, retries, DLQs
- Security by Default: JWT, least privilege, secrets out of code
- Observability: centralized logs, dashboards, uptime checks