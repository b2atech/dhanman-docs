# Microservices Communication and Integration Patterns

## Overview

This document describes how Dhanman's microservices communicate with each other, the patterns used for inter-service communication, and the data flow across bounded contexts. Understanding these patterns is crucial for maintaining system consistency and reliability.

---

## Communication Patterns

### 1. Synchronous Communication (HTTP/REST)

Used for real-time operations that require immediate responses.

**When to Use:**
- User-facing operations requiring immediate feedback
- Read operations that need fresh data
- Operations where eventual consistency is not acceptable
- External API integrations

**Example Flow: Invoice Creation with Customer Validation**

```
┌─────────────┐      HTTP GET       ┌─────────────┐
│   Frontend  │─────────────────────▶│    Sales    │
│   (React)   │                      │   Service   │
└─────────────┘                      └──────┬──────┘
                                            │
                                            │ HTTP GET (validate)
                                            │
                                     ┌──────▼──────┐
                                     │   Common    │
                                     │   Service   │
                                     │ (Customers) │
                                     └─────────────┘
```

**Implementation:**

```csharp
// Sales Service - Synchronous call to Common Service
public class CreateInvoiceCommandHandler : IRequestHandler<CreateInvoiceCommand, Result<Guid>>
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IInvoiceRepository _invoiceRepository;

    public async Task<Result<Guid>> Handle(
        CreateInvoiceCommand request, 
        CancellationToken cancellationToken)
    {
        // 1. Validate customer exists (synchronous HTTP call)
        var customer = await ValidateCustomerAsync(request.CustomerId, cancellationToken);
        if (customer == null)
            return Result<Guid>.Failure("Customer not found");

        // 2. Create invoice
        var invoice = Invoice.Create(request.CustomerId, request.Amount);
        await _invoiceRepository.AddAsync(invoice, cancellationToken);

        // 3. Publish event for async processing
        await PublishInvoiceCreatedEventAsync(invoice);

        return Result<Guid>.Success(invoice.Id);
    }

    private async Task<CustomerDto?> ValidateCustomerAsync(
        Guid customerId, 
        CancellationToken cancellationToken)
    {
        var client = _httpClientFactory.CreateClient("CommonService");
        var response = await client.GetAsync(
            $"api/customers/{customerId}", 
            cancellationToken
        );

        if (!response.IsSuccessStatusCode)
            return null;

        return await response.Content.ReadFromJsonAsync<CustomerDto>(cancellationToken);
    }
}
```

**Resilience Pattern:**

```csharp
// HTTP Client with Polly resilience
services.AddHttpClient("CommonService", client =>
{
    client.BaseAddress = new Uri(configuration["Services:Common:Url"]);
    client.Timeout = TimeSpan.FromSeconds(10);
})
.AddPolicyHandler(Policy<HttpResponseMessage>
    .Handle<HttpRequestException>()
    .WaitAndRetryAsync(3, retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)))
)
.AddPolicyHandler(Policy<HttpResponseMessage>
    .Handle<HttpRequestException>()
    .CircuitBreakerAsync(5, TimeSpan.FromSeconds(30))
);
```

---

### 2. Asynchronous Communication (Event-Driven)

Used for operations that can be processed eventually and don't require immediate response.

**When to Use:**
- Cross-service data synchronization
- Triggering workflows in other services
- Audit logging and analytics
- Non-critical operations
- Operations that can be retried

**Example Flow: Invoice Created → Ledger Update**

```
┌─────────────┐                    ┌─────────────────┐
│    Sales    │                    │    RabbitMQ     │
│   Service   │───── Publish ─────▶│  dhanman.events │
│             │   InvoiceCreated   │   (Exchange)    │
└─────────────┘                    └────────┬────────┘
                                            │ Fan-out
                                   ┌────────┴────────┐
                                   │                 │
                        ┌──────────▼─────┐  ┌───────▼────────┐
                        │     Common     │  │  Notification  │
                        │    Service     │  │    Service     │
                        │  (Consumes)    │  │  (Consumes)    │
                        └────────────────┘  └────────────────┘
```

**Event Publishing:**

```csharp
// Sales Service - Publishing event after invoice creation
public class CreateInvoiceCommandHandler : IRequestHandler<CreateInvoiceCommand, Result<Guid>>
{
    private readonly IEventPublisher _eventPublisher;
    private readonly IInvoiceRepository _invoiceRepository;

    public async Task<Result<Guid>> Handle(
        CreateInvoiceCommand request, 
        CancellationToken cancellationToken)
    {
        // 1. Create and save invoice
        var invoice = Invoice.Create(request.CustomerId, request.Amount, request.DueDate);
        await _invoiceRepository.AddAsync(invoice, cancellationToken);

        // 2. Publish domain event
        var @event = new InvoiceCreatedEvent
        {
            InvoiceId = invoice.Id,
            CustomerId = invoice.CustomerId,
            Amount = invoice.Amount,
            DueDate = invoice.DueDate,
            CreatedAt = DateTime.UtcNow
        };

        await _eventPublisher.PublishAsync(@event, cancellationToken);

        return Result<Guid>.Success(invoice.Id);
    }
}
```

**Event Consumption:**

```csharp
// Common Service - Consuming event to update ledger
public class InvoiceCreatedEventHandler : IMessageHandler<InvoiceCreatedEvent>
{
    private readonly ILedgerService _ledgerService;
    private readonly ILogger<InvoiceCreatedEventHandler> _logger;

    public async Task HandleAsync(
        InvoiceCreatedEvent @event, 
        CancellationToken cancellationToken)
    {
        _logger.LogInformation(
            "Processing InvoiceCreatedEvent for Invoice {InvoiceId}", 
            @event.InvoiceId
        );

        try
        {
            // Create debit entry (Accounts Receivable)
            await _ledgerService.CreateEntryAsync(new LedgerEntry
            {
                AccountCode = "1200", // Accounts Receivable
                Type = EntryType.Debit,
                Amount = @event.Amount,
                ReferenceId = @event.InvoiceId,
                ReferenceType = "Invoice",
                Description = $"Invoice created for customer {@event.CustomerId}"
            });

            // Create credit entry (Revenue)
            await _ledgerService.CreateEntryAsync(new LedgerEntry
            {
                AccountCode = "4000", // Revenue
                Type = EntryType.Credit,
                Amount = @event.Amount,
                ReferenceId = @event.InvoiceId,
                ReferenceType = "Invoice",
                Description = $"Revenue from invoice {@event.InvoiceId}"
            });

            _logger.LogInformation(
                "Ledger entries created for Invoice {InvoiceId}", 
                @event.InvoiceId
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(
                ex, 
                "Error processing InvoiceCreatedEvent for Invoice {InvoiceId}", 
                @event.InvoiceId
            );
            throw; // Retry mechanism will handle
        }
    }
}
```

---

### 3. Command Pattern (Point-to-Point)

Used for directing specific actions to a particular service.

**Example Flow: Send Email Command**

```
┌─────────────┐                    ┌──────────────────┐
│    Sales    │                    │     RabbitMQ     │
│   Service   │─── Publish ───────▶│ dhanman.commands │
│             │  SendEmailCommand  │   (Exchange)     │
└─────────────┘                    └────────┬─────────┘
                                            │ Direct routing
                                            │ (notification.commands)
                                    ┌───────▼──────────┐
                                    │   Notification   │
                                    │     Service      │
                                    │   (Consumes)     │
                                    └──────────────────┘
```

**Command Publishing:**

```csharp
public class SendInvoiceEmailCommand
{
    public Guid InvoiceId { get; set; }
    public Guid CustomerId { get; set; }
    public string EmailTemplate { get; set; }
}

// Sales Service
public class InvoiceEmailService
{
    private readonly ICommandPublisher _commandPublisher;

    public async Task SendInvoiceEmailAsync(Guid invoiceId, Guid customerId)
    {
        var command = new SendInvoiceEmailCommand
        {
            InvoiceId = invoiceId,
            CustomerId = customerId,
            EmailTemplate = "invoice-created"
        };

        await _commandPublisher.PublishAsync(
            command,
            routingKey: "notification.commands"
        );
    }
}
```

---

## Communication Scenarios

### Scenario 1: Monthly Invoice Generation

**Flow:**

```
1. Hangfire Recurring Job (Sales Service)
   │
   ├─▶ 2. Query all active residents (HTTP to Community Service)
   │
   ├─▶ 3. For each resident:
   │      ├─▶ Create invoice (Local DB)
   │      ├─▶ Publish InvoiceCreatedEvent (RabbitMQ)
   │      └─▶ Schedule payment reminder (Hangfire Delayed Job)
   │
   ├─▶ 4. Common Service receives events:
   │      └─▶ Update ledger entries
   │
   └─▶ 5. Notification Service receives events:
          └─▶ Send invoice emails
```

**Implementation:**

```csharp
public class MonthlyInvoiceGenerationJob
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IInvoiceService _invoiceService;
    private readonly IBackgroundJobClient _hangfireClient;

    [AutomaticRetry(Attempts = 0)] // Don't retry, run next month
    public async Task GenerateMonthlyInvoices(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Starting monthly invoice generation");

        // 1. Get active residents from Community Service (Synchronous)
        var residents = await GetActiveResidentsAsync(cancellationToken);

        // 2. Generate invoices (with events published)
        var results = new List<(Guid ResidentId, Result<Guid> Result)>();
        
        foreach (var resident in residents)
        {
            var result = await _invoiceService.GenerateMonthlyInvoiceAsync(
                resident.Id, 
                resident.MonthlyCharges,
                cancellationToken
            );
            
            results.Add((resident.Id, result));

            if (result.IsSuccess)
            {
                // 3. Schedule reminder for 3 days before due date
                var reminderDate = DateTime.UtcNow.AddDays(27);
                _hangfireClient.Schedule<ReminderService>(
                    x => x.SendPaymentReminder(result.Value, cancellationToken),
                    reminderDate
                );
            }
        }

        // 4. Log summary
        _logger.LogInformation(
            "Monthly invoice generation completed. Success: {Success}, Failed: {Failed}",
            results.Count(r => r.Result.IsSuccess),
            results.Count(r => r.Result.IsFailure)
        );
    }

    private async Task<List<ResidentDto>> GetActiveResidentsAsync(
        CancellationToken cancellationToken)
    {
        var client = _httpClientFactory.CreateClient("CommunityService");
        var response = await client.GetAsync("api/residents/active", cancellationToken);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<List<ResidentDto>>(cancellationToken);
    }
}
```

---

### Scenario 2: Purchase Order Approval Workflow

**Flow:**

```
1. User submits PO (Frontend → Purchase Service)
   │
   ├─▶ 2. Purchase Service:
   │      ├─▶ Create PO (Local DB)
   │      └─▶ Publish POSubmittedEvent (RabbitMQ)
   │
   ├─▶ 3. Notification Service:
   │      └─▶ Send approval request emails to approvers
   │
   ├─▶ 4. Approver approves (Frontend → Purchase Service)
   │      ├─▶ Update PO status (Local DB)
   │      └─▶ Publish POApprovedEvent (RabbitMQ)
   │
   ├─▶ 5. Common Service:
   │      └─▶ Create budget reservation ledger entry
   │
   └─▶ 6. Notification Service:
          └─▶ Send approval confirmation to requester
```

**Implementation:**

```csharp
// Step 1: Submit PO
public class SubmitPurchaseOrderCommandHandler 
    : IRequestHandler<SubmitPurchaseOrderCommand, Result<Guid>>
{
    public async Task<Result<Guid>> Handle(
        SubmitPurchaseOrderCommand request, 
        CancellationToken cancellationToken)
    {
        var po = PurchaseOrder.Create(request.VendorId, request.Items);
        po.Submit();
        
        await _repository.AddAsync(po, cancellationToken);
        
        // Publish event
        await _eventPublisher.PublishAsync(new POSubmittedEvent
        {
            POId = po.Id,
            VendorId = po.VendorId,
            Amount = po.TotalAmount,
            RequiresApproval = po.TotalAmount > 50000,
            Approvers = po.TotalAmount > 50000 
                ? new[] { "manager@company.com", "cfo@company.com" }
                : new[] { "manager@company.com" }
        });

        return Result<Guid>.Success(po.Id);
    }
}

// Step 3: Notification Service consumes event
public class POSubmittedEventHandler : IMessageHandler<POSubmittedEvent>
{
    private readonly IEmailService _emailService;

    public async Task HandleAsync(
        POSubmittedEvent @event, 
        CancellationToken cancellationToken)
    {
        if (@event.RequiresApproval)
        {
            foreach (var approver in @event.Approvers)
            {
                await _emailService.SendAsync(new EmailMessage
                {
                    To = approver,
                    Subject = $"Purchase Order {event.POId} Requires Approval",
                    Template = "po-approval-required",
                    Data = new { POId = @event.POId, Amount = @event.Amount }
                });
            }
        }
    }
}

// Step 4: Approve PO
public class ApprovePurchaseOrderCommandHandler 
    : IRequestHandler<ApprovePurchaseOrderCommand, Result>
{
    public async Task<Result> Handle(
        ApprovePurchaseOrderCommand request, 
        CancellationToken cancellationToken)
    {
        var po = await _repository.GetByIdAsync(request.POId, cancellationToken);
        if (po == null)
            return Result.Failure("PO not found");

        var result = po.Approve(request.ApproverId, request.Comments);
        if (result.IsFailure)
            return result;

        await _repository.UpdateAsync(po, cancellationToken);

        // Publish approved event
        await _eventPublisher.PublishAsync(new POApprovedEvent
        {
            POId = po.Id,
            ApprovedBy = request.ApproverId,
            ApprovedAt = DateTime.UtcNow,
            Amount = po.TotalAmount
        });

        return Result.Success();
    }
}

// Step 5: Common Service creates ledger entry
public class POApprovedEventHandler : IMessageHandler<POApprovedEvent>
{
    private readonly ILedgerService _ledgerService;

    public async Task HandleAsync(
        POApprovedEvent @event, 
        CancellationToken cancellationToken)
    {
        // Create budget reservation entry
        await _ledgerService.CreateEntryAsync(new LedgerEntry
        {
            AccountCode = "2100", // Accounts Payable
            Type = EntryType.Credit,
            Amount = @event.Amount,
            ReferenceId = @event.POId,
            ReferenceType = "PurchaseOrder",
            Description = $"Budget reserved for approved PO {@event.POId}"
        });
    }
}
```

---

### Scenario 3: Payment Processing with Saga

**Flow:**

```
1. User makes payment (Frontend → Sales Service)
   │
   ├─▶ 2. Sales Service (Saga Orchestrator):
   │      ├─▶ Validate invoice exists (Local DB)
   │      ├─▶ Process payment via gateway (HTTP to Payment Gateway)
   │      └─▶ Mark invoice as paid (Local DB)
   │
   ├─▶ 3. If successful:
   │      ├─▶ Publish PaymentReceivedEvent (RabbitMQ)
   │      │   │
   │      │   ├─▶ Common Service: Update ledger
   │      │   └─▶ Notification Service: Send receipt
   │      │
   │      └─▶ Update customer balance (HTTP to Common Service)
   │
   └─▶ 4. If failed:
          └─▶ Rollback: Mark payment as failed, don't publish events
```

**Implementation:**

```csharp
public class ProcessPaymentSaga
{
    private readonly IInvoiceRepository _invoiceRepository;
    private readonly IPaymentGateway _paymentGateway;
    private readonly IEventPublisher _eventPublisher;
    private readonly IHttpClientFactory _httpClientFactory;

    public async Task<Result<Guid>> ExecuteAsync(
        ProcessPaymentCommand command,
        CancellationToken cancellationToken)
    {
        // Step 1: Get invoice
        var invoice = await _invoiceRepository.GetByIdAsync(
            command.InvoiceId, 
            cancellationToken
        );
        
        if (invoice == null)
            return Result<Guid>.Failure("Invoice not found");

        if (invoice.IsPaid)
            return Result<Guid>.Failure("Invoice already paid");

        // Step 2: Process payment via gateway
        PaymentResult paymentResult;
        try
        {
            paymentResult = await _paymentGateway.ProcessPaymentAsync(new PaymentRequest
            {
                Amount = invoice.Amount,
                Currency = "USD",
                PaymentMethodId = command.PaymentMethodId,
                IdempotencyKey = command.IdempotencyKey
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Payment gateway error for invoice {InvoiceId}", invoice.Id);
            return Result<Guid>.Failure("Payment processing failed");
        }

        if (!paymentResult.IsSuccess)
        {
            return Result<Guid>.Failure($"Payment failed: {paymentResult.ErrorMessage}");
        }

        // Step 3: Mark invoice as paid
        var payment = Payment.Create(
            invoice.Id,
            invoice.Amount,
            paymentResult.TransactionId,
            PaymentMethod.CreditCard
        );

        invoice.MarkAsPaid(payment);
        await _invoiceRepository.UpdateAsync(invoice, cancellationToken);

        // Step 4: Update customer balance (HTTP call)
        await UpdateCustomerBalanceAsync(
            invoice.CustomerId, 
            -invoice.Amount, 
            cancellationToken
        );

        // Step 5: Publish success event
        await _eventPublisher.PublishAsync(new PaymentReceivedEvent
        {
            PaymentId = payment.Id,
            InvoiceId = invoice.Id,
            CustomerId = invoice.CustomerId,
            Amount = invoice.Amount,
            TransactionId = paymentResult.TransactionId,
            ProcessedAt = DateTime.UtcNow
        });

        return Result<Guid>.Success(payment.Id);
    }

    private async Task UpdateCustomerBalanceAsync(
        Guid customerId,
        decimal amountDelta,
        CancellationToken cancellationToken)
    {
        var client = _httpClientFactory.CreateClient("CommonService");
        var response = await client.PostAsJsonAsync(
            $"api/customers/{customerId}/update-balance",
            new { AmountDelta = amountDelta },
            cancellationToken
        );

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogWarning(
                "Failed to update customer balance for {CustomerId}", 
                customerId
            );
            // Don't fail the saga, balance will sync via events eventually
        }
    }
}
```

---

## Integration Patterns Summary

### Pattern Selection Guide

| Pattern | Use Case | Consistency | Performance | Complexity |
|---------|----------|-------------|-------------|------------|
| **Synchronous HTTP** | Real-time validation | Strong | Medium | Low |
| **Async Events** | Cross-service workflows | Eventual | High | Medium |
| **Commands** | Directed actions | Eventual | High | Medium |
| **Saga** | Distributed transactions | Eventual | Medium | High |

### Event Types

| Event | Publisher | Consumers | Purpose |
|-------|-----------|-----------|---------|
| `InvoiceCreatedEvent` | Sales | Common, Notification | Ledger update, email notification |
| `PaymentReceivedEvent` | Sales | Common, Notification | Ledger update, receipt email |
| `BillCreatedEvent` | Purchase | Common | Ledger update |
| `POApprovedEvent` | Purchase | Common, Notification | Budget reservation, notifications |
| `SalaryPostedEvent` | Payroll | Common, Notification | Ledger update, payslip generation |
| `UserCreatedEvent` | Common | All services | User sync across services |

---

## Best Practices

### Do's ✅
- Use async events for cross-service workflows
- Implement idempotency for all event handlers
- Use correlation IDs for tracing
- Implement proper error handling and DLQ
- Version your events for backward compatibility
- Use HTTP for real-time validations
- Implement circuit breakers for external calls
- Monitor message queue health
- Log all cross-service communication

### Don'ts ❌
- Don't make synchronous calls in event handlers
- Don't create circular dependencies
- Don't skip retry mechanisms
- Don't ignore dead-letter queues
- Don't send large payloads in events (use IDs)
- Don't create tight coupling through synchronous calls
- Don't forget timeout configurations
- Don't skip correlation IDs

---

## Monitoring Communication

### Metrics to Track
- Message processing time
- Event publish rate
- HTTP call duration
- Circuit breaker state
- Dead-letter queue size
- Retry attempts
- Failed messages

### Grafana Dashboards
```
- Inter-service call latency
- Event processing throughput
- Failed message count
- Circuit breaker trips
- Queue depth
```

---

## Related Documentation
- [Event Sourcing](event-sourcing.md)
- [Resilience Patterns](resilience.md)
- [CQRS](cqrs.md)

---

## Summary

Dhanman's microservices communicate through:
- **Synchronous HTTP** for real-time operations
- **Asynchronous events** for cross-service workflows
- **Commands** for directed actions
- **Sagas** for distributed transactions

This combination provides flexibility, scalability, and resilience while maintaining data consistency across services.
