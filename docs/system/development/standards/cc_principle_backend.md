# Backend Principles

Coding
- Keep domain logic in domain layer; avoid anemic models
- Use MediatR for commands/queries; handlers remain thin
- Validation at boundaries; map to DTOs for API contracts
- Repositories encapsulate data access

Reliability
- Outbox pattern for publishing events
- Idempotent consumers; retries with backoff; DLQs

Performance
- Projections/read models for complex queries
- Index hot paths; avoid N+1 queries

Security
- Enforce authN/Z centrally; least privilege for DB and queues