# Dhanman Microservices Messaging Architecture

## Overview

Dhanman uses **RabbitMQ** as the primary message broker to enable asynchronous, event-driven communication between microservices. The messaging infrastructure is built on top of **B2aTech.CrossCuttingConcern** library with patterns inspired by **MassTransit** for reliable, scalable inter-service communication.

This architecture enables:
- **Loose coupling** between services
- **Asynchronous processing** for better responsiveness
- **Event-driven workflows** across bounded contexts
- **Scalability** through distributed message processing
- **Resilience** with automatic retries and dead-letter handling

---

## 1. Messaging Architecture Overview

### Key Concepts

#### Exchange
The entry point for messages in RabbitMQ. Routes messages to queues based on exchange type and routing keys.

**Exchange Types:**
- **Fanout**: Broadcasts messages to all bound queues (used for events)
- **Direct**: Routes to specific queues based on routing keys (used for commands)
- **Topic**: Routes based on routing key patterns (future use)
- **Headers**: Routes based on message headers (not currently used)

#### Queue
Holds messages until consumed by a service. Each microservice has dedicated queues for commands and events.

**Queue Properties:**
- **Durable**: Survives broker restarts
- **Auto-delete**: Removed when no consumers
- **Exclusive**: Used by single connection only
- **TTL**: Time-to-live for messages

#### Routing Key
String used by exchanges to determine message routing. Format: `{service}.{message-type}.{action}`

**Examples:**
- `sales.command.create-invoice`
- `sales.event.invoice-created`
- `common.command.send-notification`

#### Publisher
Service that sends messages to exchanges. Uses `IEventPublisher` or `ICommandPublisher` interfaces.

#### Consumer
Service that receives and processes messages from queues. Implements `IMessageHandler<T>` interface.

### MassTransit-Inspired Patterns

While Dhanman uses a custom implementation built on RabbitMQ.Client, it adopts proven patterns from MassTransit:

1. **Message Conventions**: Clear separation of commands, events, and queries
2. **Retry Policies**: Exponential backoff for transient failures
3. **Circuit Breaker**: Prevent cascade failures
4. **Outbox Pattern**: Ensure exactly-once delivery
5. **Saga Pattern**: Long-running distributed transactions
6. **Consumer Configuration**: Concurrent message processing with prefetch limits

---

## 2. Our Exchanges

We have two main exchanges configured:

| Exchange Name    | Type   | Purpose                                            |
|------------------|--------|---------------------------------------------------|
| dhanman.events   | Fanout | Broadcast event messages to all subscribed queues |
| dhanman.commands | Direct | Route commands to specific service queues based on routing keys |

---

## 3. Queues

Each microservice has dedicated queues to consume commands and events:

| Microservice | Command Queue       | Event Queue        |
|--------------|---------------------|--------------------|
| Sales        | sales.commands      | sales.events       |
| Purchase     | purchase.commands   | purchase.events    |
| Common       | common.commands     | common.events      |
| Community    | community.commands  | community.events   |
| Payroll      | payroll.commands    | payroll.events     |
| Inventory    | inventory.commands  | inventory.events   |

---

## 4. Types of Messages

- **Events**:  
  Represent something that has happened (e.g., `UserCreatedEvent`, `InvoiceCreatedEvent`). Published typically with fanout exchange to notify all interested services.

- **Commands**:  
  Represent instructions for something to be done (e.g., `CreateInvoiceCommand`). Routed with direct exchange using routing keys targeting specific service queues.

---

## 5. Publishers & Consumers

### Publishers

- `IEventPublisher` (in **B2aTech.CrossCuttingConcern**):  
  Publishes events to `dhanman.events` fanout exchange using contracts from **Dhanman.Shared.Contracts**.

- `ICommandPublisher` (in **B2aTech.CrossCuttingConcern**):  
  Publishes commands to `dhanman.commands` direct exchange with routing keys.

### Consumers

- `IEventConsumer` (in **B2aTech.CrossCuttingConcern**):  
  Consumes from event queues subscribed to the fanout exchange.

- `ICommandConsumer` (in **B2aTech.CrossCuttingConcern**):  
  Consumes from command queues directly routed by the command exchange.

---

## 6. Common Service Role

The Common microservice primarily consumes events like:

- `InvoiceCreatedEvent`  
- `PaymentMadeEvent`  
- `PaymentReceivedEvent`  
- `BillCreatedEvent`  
- `SalaryPostedEvent`  
- `SalaryCreatedEvent`  

which originate in Sales, Purchase, Payroll, etc. Common processes these to update ledger entries and maintain core accounting records.

---

## 7. What Has Been Done

- RabbitMQ instances deployed with Docker for QA and Production.
- Exchanges and queues declared programmatically at startup for idempotency.
- Messaging infrastructure abstracted in **B2aTech.CrossCuttingConcern** reusable package.
- Shared contracts for events and commands defined in **Dhanman.Shared.Contracts**.
- Each microservice (Sales, Purchase, Common, etc.) has a background hosted service that listens to its respective queues.
- Basic event and command handlers implemented (e.g., `UserCreatedEventHandler`).
- Dependency injection and service registration set up for messaging components.

---

## 8. Developer Responsibilities Going Forward

### Defining New Events/Commands
- Add DTOs to **Dhanman.Shared.Contracts** for new messages.

### Publishing Messages
- Use `IEventPublisher` or `ICommandPublisher` in your microservice (e.g., Sales) to publish messages upon domain events or actions.

### Consuming Messages
- Implement `IMessageHandler<T>` for relevant events/commands in consuming microservices (e.g., Common listens to Sales events).

### Queue & Exchange Management
- Declare any new queues or bindings in `RabbitMqInitializer` or ensure they are declared via consumers’ startup code.

### Hosted Service Registration
- Register `RabbitMqListenerHostedService` in your microservice’s `Program.cs` to start consuming messages.

### Handle Idempotency
- Make your handlers resilient to repeated or duplicate messages.

---

## 9. Useful RabbitMQ Management Tips

- Use the RabbitMQ Management UI ([rabbitmq.dhanman.com](https://rabbitmq.dhanman.com)) to monitor queues, exchanges, message rates.
- View ready/unacknowledged message counts to monitor health.
- Inspect logs and dead-letter queues for errors.

---

## Summary

This messaging architecture, built on **B2aTech.CrossCuttingConcern** and **Dhanman.Shared.Contracts**, establishes a consistent, scalable foundation for inter-service communication across the Dhanman ecosystem. Developers extending any microservice should align with these patterns to ensure reliability and maintainability.

---

## Architecture Diagram

![Messaging Image](../assets/messaging.png)

---



