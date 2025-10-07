# CQRS Pattern in Dhanman

## Overview

**Command Query Responsibility Segregation (CQRS)** is a fundamental architectural pattern used throughout the Dhanman ERP system. CQRS separates read operations (queries) from write operations (commands), enabling better scalability, performance, and maintainability.

---

## Core Concepts

### Commands
Commands represent **write operations** that change system state. They are imperative in nature and capture user intent.

**Characteristics:**
- Modify application state
- Return success/failure (void or Result<T>)
- Validate business rules before execution
- May trigger domain events
- Execute within a transaction boundary

**Example Commands:**
```csharp
public class CreateInvoiceCommand : IRequest<Result<Guid>>
{
    public Guid CustomerId { get; set; }
    public decimal Amount { get; set; }
    public DateTime DueDate { get; set; }
    public List<InvoiceLineItem> LineItems { get; set; }
}

public class ApprovePaymentCommand : IRequest<Result>
{
    public Guid PaymentId { get; set; }
    public Guid ApprovedBy { get; set; }
    public string Comments { get; set; }
}
```

### Queries
Queries represent **read operations** that retrieve data without side effects. They are declarative and return DTOs optimized for presentation.

**Characteristics:**
- Do not modify state (side-effect free)
- Return data transfer objects (DTOs)
- May query read-optimized projections
- Can bypass domain model for performance
- Support pagination, filtering, and sorting

**Example Queries:**
```csharp
public class GetInvoiceByIdQuery : IRequest<Result<InvoiceDto>>
{
    public Guid InvoiceId { get; set; }
}

public class GetPendingInvoicesQuery : IRequest<Result<PagedList<InvoiceListDto>>>
{
    public int PageNumber { get; set; }
    public int PageSize { get; set; }
    public string SearchTerm { get; set; }
}
```

---

## Implementation in Dhanman

### MediatR Pattern
Dhanman uses **MediatR** library to implement CQRS, providing a mediator pattern for in-process messaging.

#### Project Structure
```
Dhanman.Sales/
├── Application/
│   ├── Commands/
│   │   ├── CreateInvoice/
│   │   │   ├── CreateInvoiceCommand.cs
│   │   │   ├── CreateInvoiceCommandHandler.cs
│   │   │   └── CreateInvoiceCommandValidator.cs
│   │   └── ApproveInvoice/
│   │       ├── ApproveInvoiceCommand.cs
│   │       └── ApproveInvoiceCommandHandler.cs
│   ├── Queries/
│   │   ├── GetInvoiceById/
│   │   │   ├── GetInvoiceByIdQuery.cs
│   │   │   └── GetInvoiceByIdQueryHandler.cs
│   │   └── GetInvoicesList/
│   │       ├── GetInvoicesListQuery.cs
│   │       └── GetInvoicesListQueryHandler.cs
│   └── DTOs/
│       ├── InvoiceDto.cs
│       └── InvoiceListDto.cs
├── Domain/
│   ├── Entities/
│   └── Events/
└── Infrastructure/
    └── Persistence/
```

### Command Handler Example
```csharp
public class CreateInvoiceCommandHandler : IRequestHandler<CreateInvoiceCommand, Result<Guid>>
{
    private readonly IApplicationDbContext _context;
    private readonly IEventPublisher _eventPublisher;
    private readonly ILogger<CreateInvoiceCommandHandler> _logger;

    public CreateInvoiceCommandHandler(
        IApplicationDbContext context,
        IEventPublisher eventPublisher,
        ILogger<CreateInvoiceCommandHandler> logger)
    {
        _context = context;
        _eventPublisher = eventPublisher;
        _logger = logger;
    }

    public async Task<Result<Guid>> Handle(
        CreateInvoiceCommand request, 
        CancellationToken cancellationToken)
    {
        try
        {
            // Create domain entity
            var invoice = Invoice.Create(
                request.CustomerId,
                request.Amount,
                request.DueDate,
                request.LineItems
            );

            // Validate business rules
            if (!invoice.IsValid())
                return Result<Guid>.Failure("Invalid invoice data");

            // Persist to database
            await _context.Invoices.AddAsync(invoice, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);

            // Publish domain event
            await _eventPublisher.PublishAsync(
                new InvoiceCreatedEvent(invoice.Id, invoice.CustomerId, invoice.Amount),
                cancellationToken
            );

            _logger.LogInformation("Invoice {InvoiceId} created successfully", invoice.Id);

            return Result<Guid>.Success(invoice.Id);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating invoice");
            return Result<Guid>.Failure("Failed to create invoice");
        }
    }
}
```

### Query Handler Example
```csharp
public class GetInvoiceByIdQueryHandler : IRequestHandler<GetInvoiceByIdQuery, Result<InvoiceDto>>
{
    private readonly IApplicationDbContext _context;
    private readonly IMapper _mapper;

    public GetInvoiceByIdQueryHandler(
        IApplicationDbContext context,
        IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    public async Task<Result<InvoiceDto>> Handle(
        GetInvoiceByIdQuery request,
        CancellationToken cancellationToken)
    {
        var invoice = await _context.Invoices
            .Include(i => i.Customer)
            .Include(i => i.LineItems)
            .FirstOrDefaultAsync(i => i.Id == request.InvoiceId, cancellationToken);

        if (invoice == null)
            return Result<InvoiceDto>.Failure("Invoice not found");

        var dto = _mapper.Map<InvoiceDto>(invoice);
        return Result<InvoiceDto>.Success(dto);
    }
}
```

---

## Benefits in Dhanman Architecture

### 1. **Scalability**
- Read and write operations can be scaled independently
- Read models can be optimized without affecting write logic
- Multiple read projections for different use cases

### 2. **Performance**
- Queries bypass complex domain logic
- Read models denormalized for fast retrieval
- Caching strategies applied to queries without affecting commands

### 3. **Maintainability**
- Single Responsibility Principle enforced
- Clear separation of concerns
- Easy to locate and modify specific operations

### 4. **Testability**
- Commands and queries tested independently
- Mock dependencies easily
- Unit tests focus on specific behaviors

### 5. **Auditability**
- Commands tracked for compliance
- Clear record of state changes
- Event sourcing integration

---

## Advanced Patterns

### Validation Pipeline
FluentValidation integrated with MediatR pipeline:

```csharp
public class CreateInvoiceCommandValidator : AbstractValidator<CreateInvoiceCommand>
{
    public CreateInvoiceCommandValidator()
    {
        RuleFor(x => x.CustomerId)
            .NotEmpty().WithMessage("Customer is required");

        RuleFor(x => x.Amount)
            .GreaterThan(0).WithMessage("Amount must be positive");

        RuleFor(x => x.DueDate)
            .GreaterThan(DateTime.UtcNow).WithMessage("Due date must be in the future");

        RuleFor(x => x.LineItems)
            .NotEmpty().WithMessage("At least one line item required");
    }
}
```

### Caching Strategy
Queries can implement caching for frequently accessed data:

```csharp
public class GetCustomerListQueryHandler : IRequestHandler<GetCustomerListQuery, Result<List<CustomerDto>>>
{
    private readonly IApplicationDbContext _context;
    private readonly IDistributedCache _cache;
    private readonly IMapper _mapper;

    public async Task<Result<List<CustomerDto>>> Handle(
        GetCustomerListQuery request,
        CancellationToken cancellationToken)
    {
        var cacheKey = $"customers-{request.PageNumber}-{request.PageSize}";
        
        // Try cache first
        var cached = await _cache.GetAsync(cacheKey, cancellationToken);
        if (cached != null)
            return Result<List<CustomerDto>>.Success(
                JsonSerializer.Deserialize<List<CustomerDto>>(cached)
            );

        // Fetch from database
        var customers = await _context.Customers
            .Skip((request.PageNumber - 1) * request.PageSize)
            .Take(request.PageSize)
            .ToListAsync(cancellationToken);

        var dtos = _mapper.Map<List<CustomerDto>>(customers);

        // Cache for 5 minutes
        await _cache.SetAsync(
            cacheKey,
            JsonSerializer.SerializeToUtf8Bytes(dtos),
            new DistributedCacheEntryOptions { AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5) },
            cancellationToken
        );

        return Result<List<CustomerDto>>.Success(dtos);
    }
}
```

---

## Integration with Event-Driven Architecture

Commands often trigger domain events that are published to RabbitMQ:

```
1. User submits CreateInvoiceCommand
   ↓
2. Command handler validates and creates Invoice entity
   ↓
3. Invoice saved to PostgreSQL
   ↓
4. InvoiceCreatedEvent published to RabbitMQ (dhanman.events exchange)
   ↓
5. Common service consumes event and updates ledger
   ↓
6. Notification service sends email to customer
```

---

## Best Practices

### Do's ✅
- Keep commands and queries small and focused
- Use FluentValidation for input validation
- Return Result<T> pattern for error handling
- Log command execution for audit trails
- Publish domain events after successful commands
- Use AutoMapper for DTO projections
- Implement idempotency for commands

### Don'ts ❌
- Don't modify state in query handlers
- Don't mix command and query logic
- Don't return entities directly from queries (use DTOs)
- Don't skip validation in command handlers
- Don't forget to handle exceptions gracefully
- Don't create "god" commands with too many responsibilities

---

## Monitoring and Observability

Commands and queries are instrumented for monitoring:

```csharp
public class PerformanceMonitoringBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
{
    private readonly ILogger<PerformanceMonitoringBehavior<TRequest, TResponse>> _logger;
    private readonly Stopwatch _timer;

    public PerformanceMonitoringBehavior(ILogger<PerformanceMonitoringBehavior<TRequest, TResponse>> logger)
    {
        _logger = logger;
        _timer = new Stopwatch();
    }

    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken cancellationToken)
    {
        _timer.Start();
        var response = await next();
        _timer.Stop();

        var requestName = typeof(TRequest).Name;
        var elapsedMilliseconds = _timer.ElapsedMilliseconds;

        if (elapsedMilliseconds > 500)
        {
            _logger.LogWarning(
                "Long Running Request: {Name} ({ElapsedMilliseconds} milliseconds) {@Request}",
                requestName, elapsedMilliseconds, request);
        }

        return response;
    }
}
```

---

## Related Patterns
- [Event Sourcing](event-sourcing.md) — Event-driven communication between services
- [Domain-Driven Design](domain-driven-design.md) — Rich domain models with CQRS
- [Repository Pattern](../modules/) — Data access abstraction

---

## Summary

CQRS in Dhanman provides:
- Clear separation between reads and writes
- Better performance and scalability
- Improved code organization and maintainability
- Foundation for event-driven architecture
- Audit trail and compliance support

Each microservice (Sales, Purchase, Payroll, etc.) implements CQRS consistently, ensuring a predictable and maintainable codebase across the entire system.
