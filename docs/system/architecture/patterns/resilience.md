# Resilience and Fault Tolerance Patterns

## Overview

Dhanman's microservices architecture implements comprehensive resilience patterns to ensure system reliability, fault tolerance, and graceful degradation under failure conditions. This document outlines the strategies and patterns used to build a robust, self-healing distributed system.

---

## Core Resilience Patterns

### 1. Retry Pattern

Automatically retry failed operations with exponential backoff.

**Use Cases:**
- Transient network failures
- Temporary database connection issues
- External API timeouts
- Message broker connection drops

**Implementation:**

```csharp
public class RetryPolicyConfiguration
{
    public static IAsyncPolicy<HttpResponseMessage> GetRetryPolicy()
    {
        return HttpPolicyExtensions
            .HandleTransientHttpError() // 5xx, 408, network failures
            .OrResult(msg => msg.StatusCode == System.Net.HttpStatusCode.TooManyRequests)
            .WaitAndRetryAsync(
                retryCount: 3,
                sleepDurationProvider: retryAttempt => 
                    TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)), // Exponential backoff
                onRetry: (outcome, timespan, retryCount, context) =>
                {
                    _logger.LogWarning(
                        "Retry {RetryCount} after {Delay}ms due to {Reason}",
                        retryCount,
                        timespan.TotalMilliseconds,
                        outcome.Exception?.Message ?? outcome.Result.StatusCode.ToString()
                    );
                }
            );
    }
}

// Usage in HTTP client
services.AddHttpClient<IExternalApiClient, ExternalApiClient>()
    .AddPolicyHandler(RetryPolicyConfiguration.GetRetryPolicy());
```

**RabbitMQ Message Retry:**

```csharp
public class RabbitMqConsumer
{
    private readonly IConnection _connection;
    private readonly ILogger<RabbitMqConsumer> _logger;

    public async Task<bool> ProcessMessageWithRetryAsync<T>(
        T message, 
        Func<T, CancellationToken, Task> handler,
        CancellationToken cancellationToken)
    {
        var maxRetries = 3;
        var retryDelays = new[] { 1000, 5000, 15000 }; // 1s, 5s, 15s

        for (int attempt = 0; attempt <= maxRetries; attempt++)
        {
            try
            {
                await handler(message, cancellationToken);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(
                    ex,
                    "Message processing failed (attempt {Attempt}/{MaxRetries})",
                    attempt + 1,
                    maxRetries + 1
                );

                if (attempt < maxRetries)
                {
                    await Task.Delay(retryDelays[attempt], cancellationToken);
                }
                else
                {
                    // Move to dead-letter queue after all retries exhausted
                    await MoveToDeadLetterQueueAsync(message);
                    return false;
                }
            }
        }

        return false;
    }
}
```

### 2. Circuit Breaker Pattern

Prevent cascade failures by stopping calls to failing services.

**States:**
- **Closed**: Normal operation, requests pass through
- **Open**: Failure threshold exceeded, requests fail immediately
- **Half-Open**: Testing if service recovered

**Implementation:**

```csharp
public class CircuitBreakerConfiguration
{
    public static IAsyncPolicy<HttpResponseMessage> GetCircuitBreakerPolicy()
    {
        return HttpPolicyExtensions
            .HandleTransientHttpError()
            .CircuitBreakerAsync(
                handledEventsAllowedBeforeBreaking: 5, // Open after 5 failures
                durationOfBreak: TimeSpan.FromSeconds(30), // Stay open for 30s
                onBreak: (outcome, duration) =>
                {
                    _logger.LogError(
                        "Circuit breaker opened for {Duration}s due to {Reason}",
                        duration.TotalSeconds,
                        outcome.Exception?.Message ?? outcome.Result.StatusCode.ToString()
                    );
                },
                onReset: () =>
                {
                    _logger.LogInformation("Circuit breaker reset - service recovered");
                },
                onHalfOpen: () =>
                {
                    _logger.LogInformation("Circuit breaker half-open - testing service");
                }
            );
    }
}

// Combined with retry policy
services.AddHttpClient<IPaymentGatewayClient, PaymentGatewayClient>()
    .AddPolicyHandler(RetryPolicyConfiguration.GetRetryPolicy())
    .AddPolicyHandler(CircuitBreakerConfiguration.GetCircuitBreakerPolicy());
```

**Circuit Breaker with Polly:**

```csharp
public class ResilientPaymentService
{
    private readonly IPaymentGatewayClient _paymentGateway;
    private readonly IAsyncPolicy<PaymentResult> _policy;

    public ResilientPaymentService(IPaymentGatewayClient paymentGateway)
    {
        _paymentGateway = paymentGateway;
        
        var retryPolicy = Policy<PaymentResult>
            .Handle<HttpRequestException>()
            .Or<TimeoutException>()
            .WaitAndRetryAsync(3, retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)));

        var circuitBreakerPolicy = Policy<PaymentResult>
            .Handle<HttpRequestException>()
            .CircuitBreakerAsync(
                handledEventsAllowedBeforeBreaking: 5,
                durationOfBreak: TimeSpan.FromMinutes(1)
            );

        _policy = Policy.WrapAsync(retryPolicy, circuitBreakerPolicy);
    }

    public async Task<PaymentResult> ProcessPaymentAsync(PaymentRequest request)
    {
        return await _policy.ExecuteAsync(async () =>
        {
            return await _paymentGateway.ProcessAsync(request);
        });
    }
}
```

### 3. Bulkhead Pattern

Isolate resources to prevent total system failure.

**Implementation:**

```csharp
public class BulkheadConfiguration
{
    public static IAsyncPolicy GetBulkheadPolicy(int maxParallelization, int maxQueuedActions)
    {
        return Policy.BulkheadAsync(
            maxParallelization: maxParallelization,
            maxQueuingActions: maxQueuedActions,
            onBulkheadRejectedAsync: context =>
            {
                _logger.LogWarning(
                    "Bulkhead rejected execution - all {MaxParallelization} slots in use",
                    maxParallelization
                );
                return Task.CompletedTask;
            }
        );
    }
}

// Separate thread pools for different operations
services.AddHttpClient("CriticalOperations")
    .AddPolicyHandler(BulkheadConfiguration.GetBulkheadPolicy(10, 20));

services.AddHttpClient("NonCriticalOperations")
    .AddPolicyHandler(BulkheadConfiguration.GetBulkheadPolicy(5, 10));
```

**Database Connection Pooling:**

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=dhanman;Username=user;Password=pass;Maximum Pool Size=100;Minimum Pool Size=10;Connection Idle Lifetime=300"
  }
}
```

### 4. Timeout Pattern

Prevent indefinite waiting for responses.

**Implementation:**

```csharp
public class TimeoutConfiguration
{
    public static IAsyncPolicy GetTimeoutPolicy(TimeSpan timeout)
    {
        return Policy.TimeoutAsync(
            timeout,
            TimeoutStrategy.Optimistic,
            onTimeoutAsync: (context, timespan, task) =>
            {
                _logger.LogWarning(
                    "Operation timed out after {Timeout}ms",
                    timespan.TotalMilliseconds
                );
                return Task.CompletedTask;
            }
        );
    }
}

// HTTP client with timeout
services.AddHttpClient<IReportGeneratorClient>("ReportGenerator")
    .AddPolicyHandler(TimeoutConfiguration.GetTimeoutPolicy(TimeSpan.FromMinutes(5)))
    .AddPolicyHandler(RetryPolicyConfiguration.GetRetryPolicy());
```

**Database Query Timeout:**

```csharp
public class InvoiceRepository : IInvoiceRepository
{
    private readonly ApplicationDbContext _context;

    public async Task<List<Invoice>> GetOverdueInvoicesAsync(CancellationToken cancellationToken)
    {
        // Set command timeout to 30 seconds
        _context.Database.SetCommandTimeout(30);

        return await _context.Invoices
            .Where(i => i.DueDate < DateTime.UtcNow && !i.IsPaid)
            .ToListAsync(cancellationToken);
    }
}
```

### 5. Fallback Pattern

Provide alternative behavior when primary fails.

**Implementation:**

```csharp
public class FallbackConfiguration
{
    public static IAsyncPolicy<T> GetFallbackPolicy<T>(T fallbackValue)
    {
        return Policy<T>
            .Handle<Exception>()
            .FallbackAsync(
                fallbackValue,
                onFallbackAsync: (exception, context) =>
                {
                    _logger.LogWarning(
                        exception.Exception,
                        "Fallback triggered due to error"
                    );
                    return Task.CompletedTask;
                }
            );
    }
}

// Example: Currency conversion with fallback
public class CurrencyConverter
{
    private readonly IExchangeRateApi _externalApi;
    private readonly ICacheService _cache;

    public async Task<decimal> ConvertAsync(decimal amount, string from, string to)
    {
        var policy = Policy<decimal>
            .Handle<HttpRequestException>()
            .FallbackAsync(
                fallbackValue: await GetCachedRateAsync(from, to) ?? 1.0m,
                onFallbackAsync: async (exception, context) =>
                {
                    _logger.LogWarning("Using cached exchange rate due to API failure");
                }
            );

        return await policy.ExecuteAsync(async () =>
        {
            var rate = await _externalApi.GetExchangeRateAsync(from, to);
            await CacheRateAsync(from, to, rate);
            return amount * rate;
        });
    }
}

// Feature degradation example
public class NotificationService
{
    private readonly IEmailService _emailService;
    private readonly ISmsService _smsService;

    public async Task SendNotificationAsync(string userId, string message)
    {
        var policy = Policy
            .Handle<Exception>()
            .FallbackAsync(
                fallbackAction: async (cancellationToken) =>
                {
                    // Fallback to SMS if email fails
                    await _smsService.SendAsync(userId, message, cancellationToken);
                },
                onFallbackAsync: async (exception) =>
                {
                    _logger.LogWarning("Email failed, falling back to SMS");
                }
            );

        await policy.ExecuteAsync(async () =>
        {
            await _emailService.SendAsync(userId, message);
        });
    }
}
```

---

## Distributed System Patterns

### 6. Health Checks

Monitor service health and dependencies.

**Implementation:**

```csharp
// Program.cs
builder.Services.AddHealthChecks()
    .AddNpgSql(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        name: "database",
        timeout: TimeSpan.FromSeconds(3),
        tags: new[] { "db", "postgres" }
    )
    .AddRabbitMQ(
        rabbitConnectionString: builder.Configuration.GetConnectionString("RabbitMQ"),
        name: "rabbitmq",
        timeout: TimeSpan.FromSeconds(3),
        tags: new[] { "messaging" }
    )
    .AddUrlGroup(
        new Uri("https://api.external-service.com/health"),
        name: "external-api",
        timeout: TimeSpan.FromSeconds(5),
        tags: new[] { "external" }
    )
    .AddCheck<CustomHealthCheck>("custom-check");

app.MapHealthChecks("/health", new HealthCheckOptions
{
    ResponseWriter = async (context, report) =>
    {
        context.Response.ContentType = "application/json";
        var result = JsonSerializer.Serialize(new
        {
            status = report.Status.ToString(),
            checks = report.Entries.Select(e => new
            {
                name = e.Key,
                status = e.Value.Status.ToString(),
                description = e.Value.Description,
                duration = e.Value.Duration.TotalMilliseconds
            }),
            totalDuration = report.TotalDuration.TotalMilliseconds
        });
        await context.Response.WriteAsync(result);
    }
});

// Liveness probe (basic check)
app.MapHealthChecks("/health/live", new HealthCheckOptions
{
    Predicate = _ => false // No checks, just returns 200 if app running
});

// Readiness probe (full check)
app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready")
});
```

**Custom Health Check:**

```csharp
public class DatabaseHealthCheck : IHealthCheck
{
    private readonly IApplicationDbContext _context;

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            // Simple query to verify connection
            await _context.Database.ExecuteSqlRawAsync(
                "SELECT 1",
                cancellationToken
            );

            return HealthCheckResult.Healthy("Database connection is healthy");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy(
                "Database connection failed",
                ex
            );
        }
    }
}
```

### 7. Idempotency

Ensure operations can be safely retried.

**Implementation:**

```csharp
public class IdempotentCommandHandler : IRequestHandler<CreateInvoiceCommand, Result<Guid>>
{
    private readonly IApplicationDbContext _context;
    private readonly IIdempotencyService _idempotencyService;

    public async Task<Result<Guid>> Handle(
        CreateInvoiceCommand request,
        CancellationToken cancellationToken)
    {
        // Check if command already processed
        var idempotencyKey = request.IdempotencyKey;
        var existingResult = await _idempotencyService.GetResultAsync<Guid>(idempotencyKey);
        
        if (existingResult != null)
        {
            _logger.LogInformation(
                "Command already processed with key {IdempotencyKey}",
                idempotencyKey
            );
            return Result<Guid>.Success(existingResult.Value);
        }

        // Process command
        var invoice = Invoice.Create(request.CustomerId, request.Amount);
        await _context.Invoices.AddAsync(invoice, cancellationToken);
        await _context.SaveChangesAsync(cancellationToken);

        // Store result for future requests
        await _idempotencyService.SaveResultAsync(
            idempotencyKey,
            invoice.Id,
            TimeSpan.FromHours(24)
        );

        return Result<Guid>.Success(invoice.Id);
    }
}

// Idempotency service
public class IdempotencyService : IIdempotencyService
{
    private readonly IDistributedCache _cache;

    public async Task<T?> GetResultAsync<T>(string key)
    {
        var cachedValue = await _cache.GetStringAsync(key);
        if (cachedValue == null)
            return default;

        return JsonSerializer.Deserialize<T>(cachedValue);
    }

    public async Task SaveResultAsync<T>(string key, T result, TimeSpan expiration)
    {
        var serialized = JsonSerializer.Serialize(result);
        await _cache.SetStringAsync(
            key,
            serialized,
            new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = expiration
            }
        );
    }
}
```

**API Idempotency Header:**

```csharp
[HttpPost]
public async Task<IActionResult> CreateInvoice(
    [FromBody] CreateInvoiceRequest request,
    [FromHeader(Name = "Idempotency-Key")] string? idempotencyKey)
{
    if (string.IsNullOrEmpty(idempotencyKey))
    {
        return BadRequest("Idempotency-Key header is required");
    }

    var command = new CreateInvoiceCommand
    {
        IdempotencyKey = idempotencyKey,
        CustomerId = request.CustomerId,
        Amount = request.Amount
    };

    var result = await _mediator.Send(command);
    return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
}
```

### 8. Dead Letter Queue (DLQ)

Handle messages that cannot be processed.

**Implementation:**

```csharp
public class RabbitMqConfiguration
{
    public static void ConfigureQueuesWithDLQ(IModel channel, string queueName)
    {
        var dlqName = $"{queueName}.dlq";
        var dlxName = $"{queueName}.dlx";

        // Declare dead-letter exchange
        channel.ExchangeDeclare(
            exchange: dlxName,
            type: ExchangeType.Direct,
            durable: true
        );

        // Declare dead-letter queue
        channel.QueueDeclare(
            queue: dlqName,
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: null
        );

        // Bind DLQ to DLX
        channel.QueueBind(
            queue: dlqName,
            exchange: dlxName,
            routingKey: queueName
        );

        // Declare main queue with DLX configuration
        var arguments = new Dictionary<string, object>
        {
            { "x-dead-letter-exchange", dlxName },
            { "x-dead-letter-routing-key", queueName },
            { "x-message-ttl", 86400000 } // 24 hours
        };

        channel.QueueDeclare(
            queue: queueName,
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: arguments
        );
    }
}

// DLQ monitoring and reprocessing
public class DeadLetterQueueService
{
    private readonly IModel _channel;
    private readonly ILogger<DeadLetterQueueService> _logger;

    public async Task<List<DeadLetterMessage>> GetDeadLetterMessagesAsync(string queueName)
    {
        var dlqName = $"{queueName}.dlq";
        var messages = new List<DeadLetterMessage>();

        var messageCount = _channel.MessageCount(dlqName);
        
        for (int i = 0; i < Math.Min(messageCount, 100); i++)
        {
            var result = _channel.BasicGet(dlqName, false);
            if (result != null)
            {
                messages.Add(new DeadLetterMessage
                {
                    DeliveryTag = result.DeliveryTag,
                    Body = Encoding.UTF8.GetString(result.Body.ToArray()),
                    Headers = result.BasicProperties.Headers,
                    Timestamp = result.BasicProperties.Timestamp.UnixTime
                });
            }
        }

        return messages;
    }

    public async Task ReprocessMessageAsync(string queueName, ulong deliveryTag)
    {
        var dlqName = $"{queueName}.dlq";
        
        // Get message from DLQ
        var result = _channel.BasicGet(dlqName, false);
        if (result == null)
        {
            throw new InvalidOperationException("Message not found");
        }

        // Publish to original queue
        _channel.BasicPublish(
            exchange: "",
            routingKey: queueName,
            basicProperties: result.BasicProperties,
            body: result.Body
        );

        // Acknowledge removal from DLQ
        _channel.BasicAck(result.DeliveryTag, false);

        _logger.LogInformation(
            "Message reprocessed from DLQ {DLQ} to {Queue}",
            dlqName,
            queueName
        );
    }
}
```

---

## Data Resilience

### 9. Database Transaction Management

Ensure data consistency with proper transaction handling.

**Implementation:**

```csharp
public class TransactionalCommandHandler : IRequestHandler<CreateInvoiceCommand, Result<Guid>>
{
    private readonly IApplicationDbContext _context;

    public async Task<Result<Guid>> Handle(
        CreateInvoiceCommand request,
        CancellationToken cancellationToken)
    {
        using var transaction = await _context.Database.BeginTransactionAsync(cancellationToken);
        
        try
        {
            // Create invoice
            var invoice = Invoice.Create(request.CustomerId, request.Amount);
            await _context.Invoices.AddAsync(invoice, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);

            // Create ledger entries
            var debitEntry = LedgerEntry.CreateDebit(invoice.Id, invoice.Amount);
            var creditEntry = LedgerEntry.CreateCredit(invoice.Id, invoice.Amount);
            
            await _context.LedgerEntries.AddRangeAsync(
                new[] { debitEntry, creditEntry },
                cancellationToken
            );
            await _context.SaveChangesAsync(cancellationToken);

            // Commit transaction
            await transaction.CommitAsync(cancellationToken);

            return Result<Guid>.Success(invoice.Id);
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync(cancellationToken);
            _logger.LogError(ex, "Transaction failed, rolling back");
            throw;
        }
    }
}
```

### 10. Saga Pattern

Manage distributed transactions across services.

**Implementation:**

```csharp
public class InvoicePaymentSaga
{
    private readonly IEventPublisher _eventPublisher;
    private readonly ICommandPublisher _commandPublisher;
    private readonly ISagaRepository _sagaRepository;

    public async Task HandleInvoiceCreatedEvent(InvoiceCreatedEvent @event)
    {
        // Step 1: Create saga instance
        var saga = new InvoicePaymentSagaData
        {
            SagaId = Guid.NewGuid(),
            InvoiceId = @event.InvoiceId,
            CustomerId = @event.CustomerId,
            Amount = @event.Amount,
            State = SagaState.Started
        };
        await _sagaRepository.SaveAsync(saga);

        try
        {
            // Step 2: Update ledger in Common service
            await _commandPublisher.PublishAsync(new UpdateLedgerCommand
            {
                InvoiceId = @event.InvoiceId,
                Amount = @event.Amount
            });

            saga.State = SagaState.LedgerUpdated;
            await _sagaRepository.SaveAsync(saga);

            // Step 3: Send notification
            await _commandPublisher.PublishAsync(new SendNotificationCommand
            {
                CustomerId = @event.CustomerId,
                Type = "InvoiceCreated",
                InvoiceId = @event.InvoiceId
            });

            saga.State = SagaState.Completed;
            await _sagaRepository.SaveAsync(saga);
        }
        catch (Exception ex)
        {
            // Compensating actions
            await CompensateAsync(saga);
        }
    }

    private async Task CompensateAsync(InvoicePaymentSagaData saga)
    {
        _logger.LogWarning("Compensating saga {SagaId}", saga.SagaId);

        if (saga.State >= SagaState.LedgerUpdated)
        {
            // Reverse ledger entries
            await _commandPublisher.PublishAsync(new ReverseLedgerCommand
            {
                InvoiceId = saga.InvoiceId
            });
        }

        saga.State = SagaState.Compensated;
        await _sagaRepository.SaveAsync(saga);
    }
}
```

---

## Monitoring and Observability

### 11. Distributed Tracing

Track requests across services.

**Implementation:**

```csharp
// Program.cs
builder.Services.AddOpenTelemetry()
    .WithTracing(tracing =>
    {
        tracing
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation()
            .AddNpgsql()
            .AddSource("Dhanman.Sales");
    });

// Custom tracing
public class InvoiceService
{
    private readonly ActivitySource _activitySource = new("Dhanman.Sales");

    public async Task<Invoice> CreateInvoiceAsync(CreateInvoiceRequest request)
    {
        using var activity = _activitySource.StartActivity("CreateInvoice");
        
        activity?.SetTag("invoice.customer_id", request.CustomerId);
        activity?.SetTag("invoice.amount", request.Amount);

        try
        {
            var invoice = await ProcessInvoiceAsync(request);
            activity?.SetTag("invoice.id", invoice.Id);
            activity?.SetStatus(ActivityStatusCode.Ok);
            return invoice;
        }
        catch (Exception ex)
        {
            activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
            activity?.RecordException(ex);
            throw;
        }
    }
}
```

### 12. Correlation IDs

Track related operations across services.

**Implementation:**

```csharp
public class CorrelationIdMiddleware
{
    private readonly RequestDelegate _next;
    private const string CorrelationIdHeader = "X-Correlation-Id";

    public async Task InvokeAsync(HttpContext context)
    {
        var correlationId = GetCorrelationId(context);
        context.Items["CorrelationId"] = correlationId;
        context.Response.Headers.Add(CorrelationIdHeader, correlationId);

        using (LogContext.PushProperty("CorrelationId", correlationId))
        {
            await _next(context);
        }
    }

    private string GetCorrelationId(HttpContext context)
    {
        if (context.Request.Headers.TryGetValue(CorrelationIdHeader, out var correlationId))
        {
            return correlationId.ToString();
        }

        return Guid.NewGuid().ToString();
    }
}

// Usage in HTTP clients
public class CorrelationIdDelegatingHandler : DelegatingHandler
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    protected override async Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request,
        CancellationToken cancellationToken)
    {
        var correlationId = _httpContextAccessor.HttpContext?.Items["CorrelationId"]?.ToString();
        
        if (!string.IsNullOrEmpty(correlationId))
        {
            request.Headers.Add("X-Correlation-Id", correlationId);
        }

        return await base.SendAsync(request, cancellationToken);
    }
}
```

---

## Best Practices

### Do's ✅
- Implement retry with exponential backoff
- Use circuit breakers for external dependencies
- Set appropriate timeouts for all operations
- Monitor health checks continuously
- Log all retry attempts and failures
- Implement idempotency for all state-changing operations
- Use bulkheads to isolate critical resources
- Handle partial failures gracefully
- Implement proper error handling and logging
- Test failure scenarios regularly (chaos engineering)

### Don'ts ❌
- Don't retry indefinitely without backoff
- Don't ignore timeout configurations
- Don't skip health check implementations
- Don't let circuit breakers stay open forever
- Don't forget to implement fallback strategies
- Don't ignore dead-letter queues
- Don't cascade failures across services
- Don't skip distributed tracing
- Don't ignore correlation IDs in logging

---

## Testing Resilience

### Chaos Engineering

```csharp
public class ChaosMiddleware
{
    private readonly RequestDelegate _next;
    private readonly Random _random = new();
    private readonly ChaosConfiguration _config;

    public async Task InvokeAsync(HttpContext context)
    {
        if (_config.IsEnabled && ShouldInjectFailure())
        {
            context.Response.StatusCode = 500;
            await context.Response.WriteAsync("Chaos: Simulated failure");
            return;
        }

        await _next(context);
    }

    private bool ShouldInjectFailure()
    {
        return _random.NextDouble() < _config.FailureRate; // e.g., 0.1 = 10%
    }
}
```

---

## Summary

Dhanman's resilience patterns provide:
- **Fault tolerance** through retry and circuit breaker patterns
- **Resource isolation** via bulkhead pattern
- **Graceful degradation** with fallback strategies
- **System observability** through health checks and tracing
- **Data consistency** with transactions and saga patterns
- **Operational reliability** through idempotency and DLQ

These patterns work together to create a robust, self-healing distributed system that maintains availability and consistency even under failure conditions.
