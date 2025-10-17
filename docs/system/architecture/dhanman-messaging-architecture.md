# 🧩 Dhanman Messaging Architecture — RabbitMQ + MassTransit (Detailed)

**Version:** 2.0  
**Last Updated:** 2025-10-17 (IST)  
**Maintainer:** Dhanman Engineering Team (B2A Technologies Pvt. Ltd.)

---

## 0) At-a-glance

- **Broker:** RabbitMQ
- **Library:** MassTransit (.NET)
- **Message Types:** **Commands** (one-to-one, `direct`) and **Events** (broadcast, `fanout`)
- **Participants:** Common (financial core), Sales, Purchase, Payroll, Inventory, Community _(active)_; Payment (no DB) & Document (own DB) _(currently passive for messaging)_
- **Error Handling:** MassTransit `_skipped`, `_error`, `_delay` queues; DLX/DLQ policies; retries & scheduled redelivery
- **Environments:** prod / qa per **virtual host** (`/prod`, `/qa`) with separate credentials and permissions

---

## 1) Services & Ownership

| #   | Service                     | Owns                                                                             | Messaging Role                                                                                                                                           |
| --- | --------------------------- | -------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | **Common** (Financial Core) | Organizations, Companies, Users, Chart of Accounts, Ledger/Transactions, Reports | **Publishes events** (Org/Company/User created/updated/deleted), **Consumes commands** (CreateTransaction, CreateCustomer, CreateVendor, CreateEmployee) |
| 2   | **Sales**                   | Customers, Invoices, Receipts, Credit/Debit Notes                                | **Publishes commands** to Common (CreateTransaction, CreateCustomer); **Consumes events** from Common and Community                                      |
| 3   | **Purchase**                | Vendors, Bills, Payments, Credit/Debit Notes                                     | **Publishes commands** to Common (CreateTransaction, CreateVendor); **Consumes events** from Common                                                      |
| 4   | **Payroll**                 | Employees, Salaries (posting & payment)                                          | **Publishes commands** to Common (CreateTransaction, CreateEmployee, CreateUser); **Consumes events** from Common                                        |
| 5   | **Inventory**               | Items/Stock (valuation future)                                                   | **Consumes events** from Common (and Purchase vendor if needed)                                                                                          |
| 6   | **Community**               | Units, Members                                                                   | **Publishes commands** to Sales/Common (CreateCustomer, CreateUser); **Consumes events** from Common                                                     |
| 7   | Payment _(no DB)_           | Gateway orchestration                                                            | (future) publish `PaymentVerifiedEvent`                                                                                                                  |
| 8   | Document _(own DB)_         | Documents/Blobs                                                                  | (future) publish `DocumentUploadedEvent`                                                                                                                 |

---

## 2) Commands vs Events (recap)

| Aspect    | **Command**                         | **Event**                                 |
| --------- | ----------------------------------- | ----------------------------------------- |
| Meaning   | “Do X” (imperative)                 | “X happened” (fact)                       |
| Direction | One-to-one                          | One-to-many                               |
| Exchange  | `direct`                            | `fanout`                                  |
| Coupling  | Higher (explicit target)            | Lower (broadcast)                         |
| Example   | `CreateTransactionCommand` → Common | `OrganizationCreatedEvent` → all services |

---

## 3) RabbitMQ Primer (with Dhanman conventions)

### 3.1 Virtual Hosts (vhosts)

A **virtual host** is a namespaced RabbitMQ instance: its own users/permissions, exchanges, queues, and bindings.  
**Why:** strict isolation between **environments** and/or **tenants**.

- **Recommended:**
  - `/prod` for production
  - `/qa` for QA
- Create per-vhost users with minimum permissions.
- MassTransit/clients connect to the right vhost via connection string (e.g., `amqp://user:pass@host:5672/qa`).

### 3.2 Exchanges, Queues, Bindings, Routing Keys

- **Exchange types used:**
  - **`direct`** for **Commands** (point-to-point).
  - **`fanout`** for **Events** (broadcast).
  - _(Optionally `topic` later for routing-key-based patterns)_
- **Queues** are where consumers read messages.
- **Bindings** connect exchanges to queues (possibly with routing keys).

### 3.3 Durability & Persistence

- Set exchanges/queues to **durable**; publish messages with **delivery mode = persistent** (MassTransit does this by default in production profiles).

### 3.4 Acknowledgements & Prefetch

- Consumers **ack** on success; **nack/reject** on failure → triggers retry or DLQ.
- **Prefetch** (QoS) controls parallelism; tune per consumer (MassTransit: `PrefetchCount`).

### 3.5 Dead-Lettering (DLX/DLQ)

- Configure a **Dead Letter Exchange (DLX)** at queue level.
- On reject/expired/limit-exceeded, messages are routed to **DLQ** (dead-letter queue).
- MassTransit also creates `_error` and `_skipped` queues per endpoint.

### 3.6 Policies & HA

- Use policies for DLX/TTL on a namespace of queues.
- Consider quorum/mirrored queues for HA (depends on cluster topology and throughput).

---

## 4) Naming Conventions (clear & consistent)

> Keep names lowercase, hyphen-separated, environment-scoped by vhost. Examples below assume vhost `/qa` or `/prod`.

### 4.1 Exchanges

- **Events:** `{service}.events` (type: `fanout`)
  - e.g., `common.events`
- **Commands:** `{service}.commands` (type: `direct`)
  - e.g., `common.commands` (consumed by Common)

### 4.2 Queues

- **Per consumer endpoint:** `{service}.{endpoint}`
  - e.g., `common.create-transaction`, `common.create-customer`, `sales.org-sync`

### 4.3 Routing Keys (for `direct`/`topic`)

- Commands: `{action}` or `{aggregate}.{action}`
  - e.g., `transaction.create`, `customer.create`, `vendor.create`
- Events (`fanout`) ignore routing keys; if switching to `topic`, prefer: `{aggregate}.{event}`
  - e.g., `organization.created`, `company.updated`, `user.deleted`

> **MassTransit** will create exchanges/queues automatically based on endpoint configuration when `ConfigureEndpoints()` is used.

---

## 5) Service-wise Contracts (with suggested names)

### 5.1 Common → Events (fanout on `common.events`)

| Event                      | Example Payload (envelope)                      | Consumers                                      |
| -------------------------- | ----------------------------------------------- | ---------------------------------------------- |
| `OrganizationCreatedEvent` | `{ "id": "...", "name": "...", ... }`           | Sales, Purchase, Payroll, Inventory, Community |
| `CompanyCreatedEvent`      | `{ "id": "...", "organizationId": "...", ... }` | Same                                           |
| `UserCreatedEvent`         | `{ "id": "...", "email": "...", ... }`          | Same                                           |

**Queues (per consumer)**

- `sales.org-sync`, `purchase.org-sync`, `payroll.org-sync`, `inventory.org-sync`, `community.org-sync`  
  _(bound to `common.events`)_

### 5.2 Commands → Common (direct on `common.commands`)

| From      | Command                    | Routing Key          | Queue (endpoint)            | Description                           |
| --------- | -------------------------- | -------------------- | --------------------------- | ------------------------------------- |
| Sales     | `CreateTransactionCommand` | `transaction.create` | `common.create-transaction` | Invoice/Receipt/Reversal/Credit/Debit |
| Purchase  | `CreateTransactionCommand` | `transaction.create` | `common.create-transaction` | Bill/Payment/Reversal/Credit/Debit    |
| Payroll   | `CreateTransactionCommand` | `transaction.create` | `common.create-transaction` | Salary posting/payment                |
| Sales     | `CreateCustomerCommand`    | `customer.create`    | `common.create-customer`    | Mirror owner entity                   |
| Purchase  | `CreateVendorCommand`      | `vendor.create`      | `common.create-vendor`      | Mirror owner entity                   |
| Payroll   | `CreateEmployeeCommand`    | `employee.create`    | `common.create-employee`    | Mirror owner entity                   |
| Payroll   | `CreateUserCommand`        | `user.create`        | `common.create-user`        | Employee → User mapping               |
| Community | `CreateUserCommand`        | `user.create`        | `common.create-user`        | Member → User mapping                 |

### 5.3 Community → Sales (direct on `sales.commands`)

| Command                 | Routing Key       | Queue                   | Description                      |
| ----------------------- | ----------------- | ----------------------- | -------------------------------- |
| `CreateCustomerCommand` | `customer.create` | `sales.create-customer` | Unit becomes a Customer in Sales |

### 5.4 Events Consumed by Sales/Purchase/Payroll/Inventory/Community

All consume from `common.events` (fanout) to maintain local master copies.

---

## 6) MassTransit Setup (C#)

### 6.1 Bus Configuration (generic)

```csharp
using MassTransit;

builder.Services.AddMassTransit(x =>
{
    x.AddConsumers(typeof(Program).Assembly); // or specific consumers

    x.UsingRabbitMq((context, cfg) =>
    {
        cfg.Host("rabbitmq-host", h =>
        {
            h.Username("user");
            h.Password("pass");
            h.VirtualHost("/qa"); // or "/prod"
        });

        // Global topology
        cfg.PrefetchCount = 16; // tune
        cfg.ConcurrentMessageLimit = 8; // optional

        // Retry policy (immediate + redelivery)
        cfg.UseMessageRetry(r =>
        {
            r.Immediate(3);
            r.Ignore<ArgumentException>(); // example
        });
        cfg.UseDelayedRedelivery(r =>
        {
            r.Intervals(TimeSpan.FromSeconds(10), TimeSpan.FromMinutes(1));
        });

        // Error/skip handling
        cfg.UseKillSwitch(options =>
        {
            options.SetActivationThreshold(10);
            options.SetTripThreshold(0.15);
            options.SetRestartTimeout(s: 30);
        });

        // Endpoint auto-bindings per consumer
        cfg.ConfigureEndpoints(context);
    });
});
```

### 6.2 Define Contracts

```csharp
public interface CreateTransactionCommand
{
    Guid CorrelationId { get; }
    Guid OrganizationId { get; }
    Guid CompanyId { get; }
    string SourceService { get; }
    DateTime Timestamp { get; }
    // domain-specific fields...
}
```

### 6.3 Producer (Sales → Common)

```csharp
public class SalesTransactionPublisher
{
    private readonly IPublishEndpoint _publish;      // for events
    private readonly ISendEndpointProvider _send;    // for commands (to a specific queue)

    public SalesTransactionPublisher(IPublishEndpoint publish, ISendEndpointProvider send)
    {
        _publish = publish;
        _send = send;
    }

    public async Task SendCreateTransactionAsync(CreateTransactionCommand cmd)
    {
        // Resolve the command queue endpoint (MassTransit builds the name as you define endpoints)
        var endpoint = await _send.GetSendEndpoint(new Uri("queue:common.create-transaction"));
        await endpoint.Send(cmd);
    }
}
```

### 6.4 Consumer (Common side)

```csharp
public class CreateTransactionConsumer : IConsumer<CreateTransactionCommand>
{
    public async Task Consume(ConsumeContext<CreateTransactionCommand> context)
    {
        var msg = context.Message;

        // Process and write ledger/journal entries...
        await Task.CompletedTask;
    }
}

// Endpoint mapping
builder.Services.AddMassTransit(x =>
{
    x.AddConsumer<CreateTransactionConsumer>();

    x.UsingRabbitMq((context, cfg) =>
    {
        cfg.Host("rabbitmq-host", h => { /* creds + vhost */ });
        cfg.ReceiveEndpoint("common.create-transaction", e =>
        {
            e.ConfigureConsumer<CreateTransactionConsumer>(context);
            e.PrefetchCount = 32;
            e.ConcurrentMessageLimit = 16;
        });
    });
});
```

### 6.5 Events (fanout)

```csharp
public interface OrganizationCreatedEvent
{
    Guid Id { get; }
    string Name { get; }
    DateTime Timestamp { get; }
}

public class CommonEventPublisher
{
    private readonly IPublishEndpoint _publish;
    public CommonEventPublisher(IPublishEndpoint publish) => _publish = publish;

    public Task PublishOrganizationAsync(OrganizationCreatedEvent evt) => _publish.Publish(evt);
}
```

> MassTransit uses **publish/subscribe** for events. Each subscriber gets its own queue bound to the exchange.

### 6.6 Outbox & Idempotency (recommended)

```csharp
// In Startup:
cfg.UseInMemoryOutbox(); // Or EFCore outbox to ensure "once" semantics

// In consumers, use CorrelationId + natural keys to de-duplicate.
```

---

## 7) Error Queues, Retries & Reprocessing

### 7.1 How errors flow

- If a consumer throws, **MassTransit** applies retry policy (immediate & delayed if configured).
- After retries are exhausted, the message goes to **`{endpoint}_error`** queue.
- Messages explicitly skipped (e.g., validation failure) go to **`{endpoint}_skipped`**.
- If RabbitMQ DLX policy exists, TTL/reject routes to **DLQ** (often same as `_error`).

### 7.2 Viewing messages (RabbitMQ Management UI)

1. Navigate to the correct **vhost** (`/qa` or `/prod`).
2. **Queues** → filter for `*_error` or `*_skipped`.
3. Click a queue → **Get messages** → choose count → **Get Message(s)**.
4. Inspect headers/body to diagnose (CorrelationId, exceptions, stack traces).

### 7.3 Reprocessing a failed message

- **Option A: Requeue from UI**
  - In the `_error` queue, **Get messages** → **Requeue** to the original queue name (`common.create-transaction`).
- **Option B: Move via script**
  - Write a small tool/consumer that reads from `_error` and republishes to the main endpoint.
- **Option C: MassTransit Scheduler**
  - Use scheduled redelivery to retry after a cool-down (Quartz or RabbitMQ delayed exchange).

> **Important:** fix the root cause (code/data) before bulk requeue to avoid loops. Consider placing a **poison message parking lot** queue.

### 7.4 Operational alerts

- Alert on growth in `_error`/DLQ and on consumer crashes.
- Grafana dashboards for queue depth, publish/consume rates, and connection health.

---

## 8) How to set up DLQ/DLX (example policy)

```bash
# Example: set DLX for all 'common.*' queues in vhost /qa
rabbitmqctl set_policy -p /qa common-dlx "^common\." \
'{"dead-letter-exchange":"common.dlx","message-ttl":604800000}' --apply-to queues

# Create a DLX exchange and bind a DLQ
# (MassTransit can also create these when endpoints are defined)
```

> Use **regex** in policy to target a family of queues (`^common\.`).  
> Set **message-ttl** (milliseconds) if you want deferred expiration behavior.

---

## 9) Security & Access

- **Per-vhost users** (e.g., `dhanman-qa`, `dhanman-prod`), least privilege.
- **TLS** if broker is exposed beyond private network.
- Credentials in **Vault**; apps fetch via AppRole.
- Disable guest access; restrict management UI to admin IPs.
- Separate **publisher vs consumer** permissions if needed.

---

## 10) Monitoring & SLOs

- **Key metrics:** queue depth, consumer count, publish/consume rate, unacked messages, connection churn, error queue size.
- **Alarms:** sustained backlog, dead consumer, error queue growth, DLQ spikes.
- **Tracing:** include `CorrelationId`, `CausationId`, `SourceService` in envelope; feed to logs/APM.

---

## 11) Message Envelope (standard proposal)

```json
{
  "MessageId": "9f7b9f3c-7dad-4c0b-8d62-6a8c8b7f5f54",
  "CorrelationId": "a2b3c4d5-e6f7-4890-9abc-0123456789ab",
  "CausationId": "optional-previous-id",
  "OrganizationId": "org-uuid",
  "CompanyId": "company-uuid",
  "SourceService": "sales",
  "MessageType": "CreateTransactionCommand",
  "OccurredOnUtc": "2025-10-17T10:35:00Z",
  "Payload": {
    /* domain-specific */
  }
}
```

---

## 12) End-to-end Flow Tables

### 12.1 Ledger flows

| Source   | Trigger                       | Command                     | Exchange          | Routing Key          | Target Queue                | Result                  |
| -------- | ----------------------------- | --------------------------- | ----------------- | -------------------- | --------------------------- | ----------------------- |
| Sales    | Invoice created               | CreateTransactionCommand    | `common.commands` | `transaction.create` | `common.create-transaction` | Ledger entry            |
| Sales    | Receipt posted                | CreateTransactionCommand    | `common.commands` | `transaction.create` | `common.create-transaction` | Ledger entry            |
| Sales    | Reversal (paid invoice)       | CreateTransactionCommand ×2 | `common.commands` | `transaction.create` | `common.create-transaction` | Reverse money + invoice |
| Purchase | Bill created/payment/reversal | CreateTransactionCommand    | `common.commands` | `transaction.create` | `common.create-transaction` | Ledger entry            |
| Payroll  | Salary posted/paid            | CreateTransactionCommand    | `common.commands` | `transaction.create` | `common.create-transaction` | Ledger entry            |

### 12.2 Master data replication

| Publisher | Event                    | Exchange        | Consumers (Queues)                                                                                    |
| --------- | ------------------------ | --------------- | ----------------------------------------------------------------------------------------------------- |
| Common    | OrganizationCreatedEvent | `common.events` | `sales.org-sync`, `purchase.org-sync`, `payroll.org-sync`, `inventory.org-sync`, `community.org-sync` |
| Common    | CompanyCreatedEvent      | `common.events` | Same as above                                                                                         |
| Common    | UserCreatedEvent         | `common.events` | Same as above                                                                                         |

### 12.3 Owner entity mirroring

| Owner                     | Command               | Target | Exchange          | Routing Key       | Queue                    |
| ------------------------- | --------------------- | ------ | ----------------- | ----------------- | ------------------------ |
| Sales (Customer)          | CreateCustomerCommand | Common | `common.commands` | `customer.create` | `common.create-customer` |
| Purchase (Vendor)         | CreateVendorCommand   | Common | `common.commands` | `vendor.create`   | `common.create-vendor`   |
| Payroll (Employee)        | CreateEmployeeCommand | Common | `common.commands` | `employee.create` | `common.create-employee` |
| Community (Member→User)   | CreateUserCommand     | Common | `common.commands` | `user.create`     | `common.create-user`     |
| Community (Unit→Customer) | CreateCustomerCommand | Sales  | `sales.commands`  | `customer.create` | `sales.create-customer`  |

---

## 13) Diagrams

### 13.1 High-level system

```mermaid
flowchart LR
    subgraph Common["COMMON (Financial Core)"]
        E1["Publishes: Org/Company/User Events (fanout: common.events)"]
        C1["Consumes: Commands (direct: common.commands)\nQueues: create-transaction, create-customer, create-vendor, create-employee, create-user"]
    end

    subgraph Sales["SALES"]
        S1["Publishes: CreateTransaction, CreateCustomer (to Common)"]
        S2["Consumes: Org/Company/User Events, UnitCreatedEvent"]
    end

    subgraph Purchase["PURCHASE"]
        P1["Publishes: CreateTransaction, CreateVendor (to Common)"]
        P2["Consumes: Org/Company/User Events"]
    end

    subgraph Payroll["PAYROLL"]
        Y1["Publishes: CreateTransaction, CreateEmployee, CreateUser (to Common)"]
        Y2["Consumes: Org/Company/User Events"]
    end

    subgraph Community["COMMUNITY"]
        M1["Publishes: CreateCustomer (to Sales), CreateUser (to Common)"]
        M2["Consumes: Org/Company/User Events"]
    end

    E1 --> S2 & P2 & Y2 & M2
    S1 --> C1
    P1 --> C1
    Y1 --> C1
    M1 --> S1 & C1
```

### 13.2 Command routing (direct)

```mermaid
sequenceDiagram
    participant Sales
    participant Exchange as common.commands (direct)
    participant Queue as common.create-transaction
    participant Common

    Sales->>Exchange: Send(CreateTransactionCommand) routingKey=transaction.create
    Exchange->>Queue: bind(routingKey=transaction.create)
    Queue->>Common: deliver message
    Common-->>Sales: ack (optional reply pattern out-of-band)
```

### 13.3 Event fanout (broadcast)

```mermaid
flowchart TB
    E["Exchange: common.events (fanout)"]
    Qs["Queues: sales.org-sync | purchase.org-sync | payroll.org-sync | inventory.org-sync | community.org-sync"]
    Pub["Publisher: Common"]
    Sub["Subscribers: Sales, Purchase, Payroll, Inventory, Community"]

    Pub --> E
    E --> Qs
    Qs --> Sub
```

---

## 14) Operational Runbook (daily quick-check)

1. **Brokers healthy:** all nodes up, disk free > 20%, file descriptors OK.
2. **Connections & channels:** stable counts; no runaway reconnect loops.
3. **Queues depth:** command queues empty/near-empty; event sync queues not growing.
4. **Unacked:** < threshold (e.g., 100 per queue).
5. **Error queues:** no sustained growth; investigate spikes.
6. **Consumers:** expected count matches deployments; restart failed pods/services.
7. **Alerts:** clear or acknowledged; Jira ticket for recurring patterns.

---

## 15) Glossary

- **Virtual Host (vhost):** Namespaced RabbitMQ instance for isolation (objects & permissions).
- **Exchange:** Routes messages to queues. Types: `direct`, `fanout`, `topic`, `headers`.
- **Queue:** Durable buffer from which consumers read messages.
- **Binding:** Rule tying exchange → queue (plus optional routing key).
- **DLX/DLQ:** Dead Letter Exchange/Queue for failed/expired messages.
- **Prefetch/QoS:** Concurrent delivery control per consumer.
- **MassTransit:** .NET messaging framework providing bus, consumers, retries, outbox, sagas.
- **Outbox Pattern:** Ensures once-only publish relative to DB transactions.

---

## 16) Checklists

### 16.1 Adding a new command

- [ ] Define contract interface (`ICommandName`).
- [ ] Choose exchange (`{target}.commands`) & routing key.
- [ ] Add producer (sender) code and unit tests.
- [ ] Add consumer endpoint in target service (`{target}.{action}` queue).
- [ ] Configure retries, idempotency, and outbox.
- [ ] Update docs & diagrams.

### 16.2 Adding a new event

- [ ] Define event interface (`I{Aggregate}{PastTense}Event`).
- [ ] Publish via `IPublishEndpoint`.
- [ ] Create subscriber queue per consumer service.
- [ ] Ensure consumer is idempotent (events can be replayed).
- [ ] Update docs & diagrams.

---

## 17) Appendix: Sample Policies & CLI

```bash
# List vhosts
rabbitmqctl list_vhosts

# Create vhost
rabbitmqctl add_vhost /qa

# Add user & set permissions
rabbitmqctl add_user dhanman-qa 'REDACTED_PASSWORD'
rabbitmqctl set_permissions -p /qa dhanman-qa ".*" ".*" ".*"  # tune for least-privilege

# Enable management plugin (if not already)
rabbitmq-plugins enable rabbitmq_management
```

---

**End of document.**
