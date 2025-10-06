# RabbitMQ Setup

- Exchanges/queues per bounded context
- Durable queues; DLQs for poison messages
- Consumer idempotency; retry with backoff
- Event versioning; minimal payloads (IDs + essentials)
- Monitoring: message rates, consumer lag, DLQ depth