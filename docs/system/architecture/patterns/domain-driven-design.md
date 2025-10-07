# Domain-Driven Design in Dhanman

## Overview

**Domain-Driven Design (DDD)** is a strategic approach to software development that places the business domain and domain logic at the center of the system design. Dhanman's microservices architecture is built on DDD principles, ensuring that each service models its business domain accurately and maintains clear boundaries.

---

## Core DDD Concepts

### 1. Ubiquitous Language

A shared language used by both developers and domain experts to describe the business domain.

**Examples in Dhanman:**
- **Invoice**: Not just a "document" but a financial obligation with lifecycle states
- **Ledger Entry**: Double-entry accounting record (debit/credit)
- **Resident**: Not just a "user" but an apartment occupant with specific rights
- **Purchase Order**: Formal procurement request with approval workflow
- **Salary Component**: Part of payroll calculation (basic, allowances, deductions)

### 2. Bounded Contexts

Clear boundaries within which a domain model is defined and applicable. Each microservice in Dhanman represents a bounded context.

| Bounded Context | Domain Focus | Key Aggregates |
|-----------------|--------------|----------------|
| **Sales** | Revenue and invoicing | Invoice, Receipt, Customer |
| **Purchase** | Procurement and vendor management | Purchase Order, Bill, Vendor, GRN |
| **Payroll** | Employee compensation | Employee, Salary, Attendance |
| **Inventory** | Asset and stock management | Asset, Stock Item, Location |
| **Community** | Resident and facility management | Resident, Apartment, Facility |
| **Common** | Shared services and accounting | Ledger Entry, Account, Organization |

### 3. Context Mapping

Defines relationships between bounded contexts.

```
┌─────────────┐         ┌──────────────┐
│   Sales     │────────▶│   Common     │
│  (Upstream) │         │ (Downstream) │
│             │         │              │
│ Publishes:  │         │ Consumes:    │
│ - Invoice   │         │ - Invoice    │
│   Created   │         │   Created    │
└─────────────┘         └──────────────┘
      │                        ▲
      │                        │
      │                        │
      ▼                        │
┌─────────────┐         ┌──────────────┐
│   Purchase  │────────▶│              │
│  (Upstream) │         │              │
└─────────────┘         └──────────────┘
```

**Relationship Patterns:**
- **Shared Kernel**: Common library (B2aTech.CrossCuttingConcern) shared across contexts
- **Customer-Supplier**: Sales/Purchase → Common (Common adapts to upstream changes)
- **Published Language**: Dhanman.Shared.Contracts defines event schemas
- **Anti-Corruption Layer**: Each service translates external events to internal model

---

## Building Blocks

### Entities

Objects with unique identity that persists over time.

**Characteristics:**
- Have unique identifier (usually GUID)
- Identity matters more than attributes
- Lifecycle spans multiple state changes
- Can be referenced by other entities

**Example:**
```csharp
public class Invoice : Entity<Guid>
{
    public Guid CustomerId { get; private set; }
    public string InvoiceNumber { get; private set; }
    public decimal Amount { get; private set; }
    public InvoiceStatus Status { get; private set; }
    public DateTime DueDate { get; private set; }
    public DateTime CreatedAt { get; private set; }

    private readonly List<InvoiceLineItem> _lineItems = new();
    public IReadOnlyCollection<InvoiceLineItem> LineItems => _lineItems.AsReadOnly();

    // Rich domain logic
    public Result Approve(Guid approvedBy, DateTime approvalDate)
    {
        if (Status != InvoiceStatus.Draft)
            return Result.Failure("Only draft invoices can be approved");

        if (approvalDate < CreatedAt)
            return Result.Failure("Approval date cannot be before creation date");

        Status = InvoiceStatus.Approved;
        AddDomainEvent(new InvoiceApprovedEvent(Id, approvedBy, approvalDate));
        return Result.Success();
    }

    public Result AddLineItem(string description, decimal quantity, decimal unitPrice)
    {
        if (Status != InvoiceStatus.Draft)
            return Result.Failure("Cannot modify approved invoice");

        var lineItem = InvoiceLineItem.Create(description, quantity, unitPrice);
        _lineItems.Add(lineItem);
        RecalculateAmount();
        return Result.Success();
    }

    private void RecalculateAmount()
    {
        Amount = _lineItems.Sum(item => item.Quantity * item.UnitPrice);
    }
}
```

### Value Objects

Objects without identity, defined by their attributes.

**Characteristics:**
- No unique identifier
- Immutable
- Compared by value, not reference
- Can be shared safely

**Example:**
```csharp
public class Money : ValueObject
{
    public decimal Amount { get; }
    public string Currency { get; }

    public Money(decimal amount, string currency)
    {
        if (amount < 0)
            throw new ArgumentException("Amount cannot be negative");
        if (string.IsNullOrWhiteSpace(currency))
            throw new ArgumentException("Currency is required");

        Amount = amount;
        Currency = currency.ToUpper();
    }

    public Money Add(Money other)
    {
        if (Currency != other.Currency)
            throw new InvalidOperationException("Cannot add different currencies");

        return new Money(Amount + other.Amount, Currency);
    }

    public Money Multiply(decimal multiplier)
    {
        return new Money(Amount * multiplier, Currency);
    }

    protected override IEnumerable<object> GetEqualityComponents()
    {
        yield return Amount;
        yield return Currency;
    }
}

public class Address : ValueObject
{
    public string Street { get; }
    public string City { get; }
    public string State { get; }
    public string ZipCode { get; }
    public string Country { get; }

    public Address(string street, string city, string state, string zipCode, string country)
    {
        Street = street ?? throw new ArgumentNullException(nameof(street));
        City = city ?? throw new ArgumentNullException(nameof(city));
        State = state ?? throw new ArgumentNullException(nameof(state));
        ZipCode = zipCode ?? throw new ArgumentNullException(nameof(zipCode));
        Country = country ?? throw new ArgumentNullException(nameof(country));
    }

    protected override IEnumerable<object> GetEqualityComponents()
    {
        yield return Street;
        yield return City;
        yield return State;
        yield return ZipCode;
        yield return Country;
    }
}
```

### Aggregates

Cluster of entities and value objects with defined boundaries and a single root entity.

**Characteristics:**
- One entity is the Aggregate Root
- External references only to root
- Root enforces invariants
- Transaction boundary
- Loaded and saved as a unit

**Example:**
```csharp
// Aggregate Root
public class PurchaseOrder : AggregateRoot<Guid>
{
    public string OrderNumber { get; private set; }
    public Guid VendorId { get; private set; }
    public POStatus Status { get; private set; }
    public DateTime OrderDate { get; private set; }
    public DateTime? ApprovalDate { get; private set; }
    public Guid? ApprovedBy { get; private set; }

    private readonly List<PurchaseOrderItem> _items = new();
    public IReadOnlyCollection<PurchaseOrderItem> Items => _items.AsReadOnly();

    private readonly List<POApproval> _approvals = new();
    public IReadOnlyCollection<POApproval> Approvals => _approvals.AsReadOnly();

    // Factory method
    public static PurchaseOrder Create(Guid vendorId, string orderNumber)
    {
        var po = new PurchaseOrder
        {
            Id = Guid.NewGuid(),
            VendorId = vendorId,
            OrderNumber = orderNumber,
            Status = POStatus.Draft,
            OrderDate = DateTime.UtcNow
        };

        po.AddDomainEvent(new PurchaseOrderCreatedEvent(po.Id, vendorId, orderNumber));
        return po;
    }

    // Business logic encapsulated in aggregate
    public Result AddItem(string itemName, decimal quantity, decimal unitPrice)
    {
        if (Status != POStatus.Draft)
            return Result.Failure("Cannot add items to non-draft PO");

        var item = new PurchaseOrderItem(Id, itemName, quantity, unitPrice);
        _items.Add(item);
        
        return Result.Success();
    }

    public Result Submit()
    {
        if (Status != POStatus.Draft)
            return Result.Failure("Only draft POs can be submitted");

        if (!_items.Any())
            return Result.Failure("Cannot submit PO without items");

        Status = POStatus.PendingApproval;
        AddDomainEvent(new PurchaseOrderSubmittedEvent(Id, OrderNumber, GetTotalAmount()));
        
        return Result.Success();
    }

    public Result Approve(Guid approverId, string comments)
    {
        if (Status != POStatus.PendingApproval)
            return Result.Failure("Only pending POs can be approved");

        var approval = new POApproval(approverId, DateTime.UtcNow, comments);
        _approvals.Add(approval);

        // Business rule: requires 2 approvals for amount > 50000
        if (GetTotalAmount() > 50000 && _approvals.Count < 2)
        {
            return Result.Success("Approval recorded, awaiting second approval");
        }

        Status = POStatus.Approved;
        ApprovalDate = DateTime.UtcNow;
        ApprovedBy = approverId;
        
        AddDomainEvent(new PurchaseOrderApprovedEvent(Id, approverId));
        return Result.Success();
    }

    private decimal GetTotalAmount()
    {
        return _items.Sum(i => i.Quantity * i.UnitPrice);
    }
}

// Entity within aggregate (not aggregate root)
public class PurchaseOrderItem : Entity<Guid>
{
    public Guid PurchaseOrderId { get; private set; }
    public string ItemName { get; private set; }
    public decimal Quantity { get; private set; }
    public decimal UnitPrice { get; private set; }
    public decimal TotalAmount => Quantity * UnitPrice;

    internal PurchaseOrderItem(Guid purchaseOrderId, string itemName, decimal quantity, decimal unitPrice)
    {
        Id = Guid.NewGuid();
        PurchaseOrderId = purchaseOrderId;
        ItemName = itemName;
        Quantity = quantity;
        UnitPrice = unitPrice;
    }
}

// Value object within aggregate
public class POApproval : ValueObject
{
    public Guid ApproverId { get; }
    public DateTime ApprovalDate { get; }
    public string Comments { get; }

    public POApproval(Guid approverId, DateTime approvalDate, string comments)
    {
        ApproverId = approverId;
        ApprovalDate = approvalDate;
        Comments = comments;
    }

    protected override IEnumerable<object> GetEqualityComponents()
    {
        yield return ApproverId;
        yield return ApprovalDate;
    }
}
```

### Domain Events

Represent something significant that happened in the domain.

**Characteristics:**
- Past tense naming (something happened)
- Immutable
- Contain relevant data
- Published after successful state change
- Can trigger side effects in other aggregates/services

**Example:**
```csharp
public class InvoiceCreatedEvent : DomainEvent
{
    public Guid InvoiceId { get; }
    public Guid CustomerId { get; }
    public string InvoiceNumber { get; }
    public decimal Amount { get; }
    public DateTime DueDate { get; }
    public DateTime CreatedAt { get; }

    public InvoiceCreatedEvent(
        Guid invoiceId, 
        Guid customerId, 
        string invoiceNumber, 
        decimal amount, 
        DateTime dueDate)
    {
        InvoiceId = invoiceId;
        CustomerId = customerId;
        InvoiceNumber = invoiceNumber;
        Amount = amount;
        DueDate = dueDate;
        CreatedAt = DateTime.UtcNow;
    }
}

// Base class for domain events
public abstract class DomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTime OccurredAt { get; } = DateTime.UtcNow;
}
```

### Repositories

Provide collection-like interface for accessing aggregates.

**Characteristics:**
- One repository per aggregate root
- Abstracts persistence details
- Returns fully-formed aggregates
- Maintains aggregate boundaries

**Example:**
```csharp
public interface IInvoiceRepository
{
    Task<Invoice?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<Invoice?> GetByNumberAsync(string invoiceNumber, CancellationToken cancellationToken = default);
    Task<List<Invoice>> GetPendingInvoicesAsync(CancellationToken cancellationToken = default);
    Task AddAsync(Invoice invoice, CancellationToken cancellationToken = default);
    Task UpdateAsync(Invoice invoice, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}

// Implementation
public class InvoiceRepository : IInvoiceRepository
{
    private readonly SalesDbContext _context;

    public InvoiceRepository(SalesDbContext context)
    {
        _context = context;
    }

    public async Task<Invoice?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        // Load entire aggregate (root + children)
        return await _context.Invoices
            .Include(i => i.LineItems)
            .Include(i => i.Payments)
            .FirstOrDefaultAsync(i => i.Id == id, cancellationToken);
    }

    public async Task AddAsync(Invoice invoice, CancellationToken cancellationToken = default)
    {
        await _context.Invoices.AddAsync(invoice, cancellationToken);
        await _context.SaveChangesAsync(cancellationToken);
        
        // Publish domain events after successful save
        await PublishDomainEventsAsync(invoice, cancellationToken);
    }

    private async Task PublishDomainEventsAsync(Invoice invoice, CancellationToken cancellationToken)
    {
        var events = invoice.GetDomainEvents();
        foreach (var @event in events)
        {
            await _eventPublisher.PublishAsync(@event, cancellationToken);
        }
        invoice.ClearDomainEvents();
    }
}
```

### Domain Services

Operations that don't naturally belong to an entity or value object.

**When to use:**
- Operation involves multiple aggregates
- Complex calculation or algorithm
- External system integration
- Stateless behavior

**Example:**
```csharp
public interface IInvoiceNumberGenerator
{
    Task<string> GenerateNextNumberAsync(Guid organizationId, CancellationToken cancellationToken);
}

public class InvoiceNumberGenerator : IInvoiceNumberGenerator
{
    private readonly ISalesDbContext _context;

    public async Task<string> GenerateNextNumberAsync(Guid organizationId, CancellationToken cancellationToken)
    {
        var lastInvoice = await _context.Invoices
            .Where(i => i.OrganizationId == organizationId)
            .OrderByDescending(i => i.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);

        var year = DateTime.UtcNow.Year;
        var month = DateTime.UtcNow.Month;
        
        if (lastInvoice == null)
        {
            return $"INV-{year}{month:D2}-0001";
        }

        // Parse last number and increment
        var parts = lastInvoice.InvoiceNumber.Split('-');
        var sequence = int.Parse(parts[2]) + 1;
        
        return $"INV-{year}{month:D2}-{sequence:D4}";
    }
}

public interface ILateFeeCalculator
{
    Money CalculateLateFee(Invoice invoice, DateTime currentDate);
}

public class LateFeeCalculator : ILateFeeCalculator
{
    private const decimal FeePercentage = 0.02m; // 2% per month
    private const int GracePeriodDays = 3;

    public Money CalculateLateFee(Invoice invoice, DateTime currentDate)
    {
        if (invoice.IsPaid || currentDate <= invoice.DueDate.AddDays(GracePeriodDays))
        {
            return new Money(0, "USD");
        }

        var daysOverdue = (currentDate - invoice.DueDate).Days - GracePeriodDays;
        var monthsOverdue = Math.Ceiling(daysOverdue / 30.0);
        
        var lateFee = invoice.Amount * FeePercentage * (decimal)monthsOverdue;
        return new Money(lateFee, "USD");
    }
}
```

---

## Layered Architecture

Dhanman follows a clean architecture pattern aligned with DDD:

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│      (API Controllers, SignalR)         │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│        Application Layer                │
│  (Commands, Queries, Handlers, DTOs)    │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│          Domain Layer                   │
│ (Entities, Value Objects, Aggregates,   │
│  Domain Events, Domain Services)        │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│       Infrastructure Layer              │
│ (Repositories, EF Core, RabbitMQ,       │
│  External Services)                     │
└─────────────────────────────────────────┘
```

### Layer Responsibilities

**1. Domain Layer** (Core)
- Contains business logic
- No dependencies on other layers
- Defines interfaces for repositories
- Pure C# with no framework dependencies

**2. Application Layer**
- Orchestrates domain objects
- Implements CQRS handlers
- Defines application services
- Maps between domain and DTOs
- Depends only on Domain layer

**3. Infrastructure Layer**
- Implements repository interfaces
- Database access via EF Core
- Messaging infrastructure (RabbitMQ)
- External API integrations
- Depends on Domain and Application layers

**4. Presentation Layer** (API)
- HTTP endpoints
- Request/Response models
- Authentication/Authorization
- Depends on Application layer

---

## Tactical Patterns in Practice

### Example: Creating an Invoice

**1. API Endpoint (Presentation)**
```csharp
[ApiController]
[Route("api/[controller]")]
public class InvoicesController : ControllerBase
{
    private readonly IMediator _mediator;

    [HttpPost]
    public async Task<IActionResult> CreateInvoice([FromBody] CreateInvoiceRequest request)
    {
        var command = new CreateInvoiceCommand
        {
            CustomerId = request.CustomerId,
            LineItems = request.LineItems,
            DueDate = request.DueDate
        };

        var result = await _mediator.Send(command);
        
        if (result.IsSuccess)
            return CreatedAtAction(nameof(GetInvoice), new { id = result.Value }, result.Value);
        
        return BadRequest(result.Error);
    }
}
```

**2. Command Handler (Application)**
```csharp
public class CreateInvoiceCommandHandler : IRequestHandler<CreateInvoiceCommand, Result<Guid>>
{
    private readonly IInvoiceRepository _invoiceRepository;
    private readonly IInvoiceNumberGenerator _numberGenerator;
    private readonly ICustomerRepository _customerRepository;

    public async Task<Result<Guid>> Handle(CreateInvoiceCommand request, CancellationToken cancellationToken)
    {
        // Validate customer exists
        var customer = await _customerRepository.GetByIdAsync(request.CustomerId, cancellationToken);
        if (customer == null)
            return Result<Guid>.Failure("Customer not found");

        // Generate invoice number (Domain Service)
        var invoiceNumber = await _numberGenerator.GenerateNextNumberAsync(
            customer.OrganizationId, 
            cancellationToken
        );

        // Create aggregate using factory method
        var invoice = Invoice.Create(
            customer.Id,
            invoiceNumber,
            request.DueDate
        );

        // Add line items
        foreach (var item in request.LineItems)
        {
            var result = invoice.AddLineItem(item.Description, item.Quantity, item.UnitPrice);
            if (result.IsFailure)
                return Result<Guid>.Failure(result.Error);
        }

        // Persist aggregate
        await _invoiceRepository.AddAsync(invoice, cancellationToken);

        // Domain events automatically published by repository
        return Result<Guid>.Success(invoice.Id);
    }
}
```

**3. Domain Model (Domain)**
```csharp
public class Invoice : AggregateRoot<Guid>
{
    // Domain logic as shown earlier
    public static Invoice Create(Guid customerId, string invoiceNumber, DateTime dueDate)
    {
        var invoice = new Invoice
        {
            Id = Guid.NewGuid(),
            CustomerId = customerId,
            InvoiceNumber = invoiceNumber,
            DueDate = dueDate,
            Status = InvoiceStatus.Draft,
            CreatedAt = DateTime.UtcNow
        };

        invoice.AddDomainEvent(new InvoiceCreatedEvent(
            invoice.Id,
            customerId,
            invoiceNumber,
            0m, // Amount calculated when line items added
            dueDate
        ));

        return invoice;
    }
}
```

**4. Repository Implementation (Infrastructure)**
```csharp
public class InvoiceRepository : IInvoiceRepository
{
    private readonly SalesDbContext _context;
    private readonly IEventPublisher _eventPublisher;

    public async Task AddAsync(Invoice invoice, CancellationToken cancellationToken = default)
    {
        await _context.Invoices.AddAsync(invoice, cancellationToken);
        await _context.SaveChangesAsync(cancellationToken);
        
        // Publish domain events
        var events = invoice.GetDomainEvents();
        foreach (var @event in events)
        {
            await _eventPublisher.PublishAsync(@event, cancellationToken);
        }
        invoice.ClearDomainEvents();
    }
}
```

---

## Advantages in Dhanman

### 1. **Business Logic Centralization**
All business rules in domain layer, easy to locate and modify

### 2. **Testability**
Domain logic tested independently without infrastructure concerns

### 3. **Flexibility**
Swap implementations (e.g., change database) without affecting business logic

### 4. **Scalability**
Clear boundaries enable service decomposition

### 5. **Maintainability**
Ubiquitous language reduces misunderstandings

### 6. **Evolution**
Domain model evolves with business needs

---

## Best Practices

### Do's ✅
- Keep aggregates small and focused
- Enforce invariants in aggregate roots
- Use factories for complex object creation
- Make value objects immutable
- Publish domain events after state changes
- Use repositories only for aggregate roots
- Keep domain layer free of infrastructure concerns
- Use ubiquitous language consistently

### Don'ts ❌
- Don't expose aggregate internals
- Don't navigate from one aggregate to another directly
- Don't create "god" aggregates with too many responsibilities
- Don't put business logic in application layer
- Don't use domain entities in API responses (use DTOs)
- Don't forget transaction boundaries
- Don't over-engineer with unnecessary abstractions

---

## Related Documentation
- [CQRS Pattern](cqrs.md) — Separating reads and writes
- [Event Sourcing](event-sourcing.md) — Event-driven architecture
- [Repository Pattern](../modules/) — Data access abstraction

---

## Summary

Domain-Driven Design in Dhanman provides:
- Clear domain model aligned with business
- Rich behavior in domain entities
- Strong aggregate boundaries
- Event-driven communication
- Testable and maintainable codebase
- Foundation for microservices architecture

Each microservice implements DDD tactical patterns consistently, ensuring a robust and business-aligned architecture.
