# Scheduled Jobs with Hangfire

## Overview

**Hangfire** is the background job processing framework used in Dhanman to handle scheduled tasks, recurring jobs, and delayed operations. It provides reliable, persistent, and distributed background job processing for the microservices architecture.

---

## Why Hangfire?

### Key Benefits
- **Persistent Storage**: Jobs stored in PostgreSQL, survive application restarts
- **Automatic Retries**: Failed jobs automatically retried with exponential backoff
- **Dashboard**: Built-in monitoring UI for job status and performance
- **Distributed**: Multiple servers can process jobs from the same queue
- **Fire-and-Forget**: Async operations that don't block user requests
- **Recurring Jobs**: CRON-based scheduling for periodic tasks
- **Delayed Jobs**: Execute tasks after a specified delay

---

## Architecture

### Job Storage
Hangfire uses PostgreSQL as its job storage backend, with dedicated schema per microservice:

```
prod-dhanman-common
├── hangfire.job
├── hangfire.state
├── hangfire.counter
├── hangfire.jobparameter
├── hangfire.jobqueue
├── hangfire.hash
├── hangfire.list
├── hangfire.set
└── hangfire.server
```

### Job Types in Dhanman

| Job Type | Use Case | Example |
|----------|----------|---------|
| **Fire-and-Forget** | One-time background task | Send welcome email after registration |
| **Delayed** | Execute after a delay | Send reminder 24 hours before due date |
| **Recurring** | Scheduled periodic tasks | Generate monthly financial reports |
| **Continuations** | Sequential job chains | Process invoice → Update ledger → Send notification |
| **Batch Jobs** | Process multiple items | Bulk invoice generation for all residents |

---

## Configuration

### Dependency Injection Setup

**Program.cs:**
```csharp
using Hangfire;
using Hangfire.PostgreSql;

var builder = WebApplication.CreateBuilder(args);

// Add Hangfire services
builder.Services.AddHangfire(configuration => configuration
    .SetDataCompatibilityLevel(CompatibilityLevel.Version_180)
    .UseSimpleAssemblyNameTypeSerializer()
    .UseRecommendedSerializerSettings()
    .UsePostgreSqlStorage(options =>
        options.UseNpgsqlConnection(builder.Configuration.GetConnectionString("HangfireDb")))
);

// Add Hangfire server
builder.Services.AddHangfireServer(options =>
{
    options.WorkerCount = Environment.ProcessorCount * 5;
    options.Queues = new[] { "critical", "default", "low-priority" };
    options.ServerName = $"{Environment.MachineName}-{Guid.NewGuid()}";
});

var app = builder.Build();

// Configure Hangfire Dashboard
app.UseHangfireDashboard("/hangfire", new DashboardOptions
{
    Authorization = new[] { new HangfireAuthorizationFilter() },
    DashboardTitle = "Dhanman Jobs Dashboard",
    StatsPollingInterval = 2000
});

app.Run();
```

### Connection String
**appsettings.json:**
```json
{
  "ConnectionStrings": {
    "HangfireDb": "Host=localhost;Port=5432;Database=prod-dhanman-common;Username=postgres;Password=***;Include Error Detail=true"
  },
  "Hangfire": {
    "WorkerCount": 10,
    "Queues": ["critical", "default", "low-priority"],
    "JobExpirationCheckInterval": "00:30:00",
    "CountersAggregateInterval": "00:05:00"
  }
}
```

---

## Job Implementation

### 1. Fire-and-Forget Jobs

**Immediate background execution without waiting for result:**

```csharp
public class EmailService
{
    private readonly IBackgroundJobClient _backgroundJobs;
    private readonly IEmailSender _emailSender;

    public EmailService(IBackgroundJobClient backgroundJobs, IEmailSender emailSender)
    {
        _backgroundJobs = backgroundJobs;
        _emailSender = emailSender;
    }

    public void SendWelcomeEmail(string userId, string email)
    {
        // Queue job and return immediately
        _backgroundJobs.Enqueue(() => 
            SendWelcomeEmailAsync(userId, email, CancellationToken.None));
    }

    public async Task SendWelcomeEmailAsync(string userId, string email, CancellationToken cancellationToken)
    {
        var template = await _emailSender.GetTemplateAsync("welcome", cancellationToken);
        await _emailSender.SendAsync(email, "Welcome to Dhanman", template, cancellationToken);
    }
}
```

**Usage in Controller:**
```csharp
[HttpPost("register")]
public async Task<IActionResult> Register([FromBody] RegisterRequest request)
{
    var user = await _userService.CreateUserAsync(request);
    
    // Fire-and-forget: doesn't block response
    _emailService.SendWelcomeEmail(user.Id, user.Email);
    
    return Ok(new { userId = user.Id });
}
```

### 2. Delayed Jobs

**Execute job after a specified time delay:**

```csharp
public class ReminderService
{
    private readonly IBackgroundJobClient _backgroundJobs;

    public void ScheduleInvoiceReminder(Guid invoiceId, DateTime dueDate)
    {
        // Send reminder 24 hours before due date
        var reminderTime = dueDate.AddHours(-24) - DateTime.UtcNow;
        
        _backgroundJobs.Schedule(() => 
            SendInvoiceReminder(invoiceId, CancellationToken.None),
            reminderTime);
    }

    public async Task SendInvoiceReminder(Guid invoiceId, CancellationToken cancellationToken)
    {
        var invoice = await _invoiceRepository.GetByIdAsync(invoiceId, cancellationToken);
        if (invoice.IsPaid) return; // Skip if already paid

        await _notificationService.SendAsync(
            invoice.CustomerId,
            "Invoice Due Tomorrow",
            $"Your invoice #{invoice.Number} is due tomorrow. Amount: {invoice.Amount:C}",
            cancellationToken
        );
    }
}
```

### 3. Recurring Jobs

**CRON-based periodic execution:**

```csharp
public class RecurringJobsConfiguration
{
    public static void ConfigureRecurringJobs()
    {
        // Daily report generation at 2 AM
        RecurringJob.AddOrUpdate<ReportService>(
            "generate-daily-reports",
            service => service.GenerateDailyReports(CancellationToken.None),
            Cron.Daily(2)
        );

        // Monthly invoice generation on 1st of each month at 6 AM
        RecurringJob.AddOrUpdate<InvoiceService>(
            "generate-monthly-invoices",
            service => service.GenerateMonthlyInvoices(CancellationToken.None),
            Cron.Monthly(1, 6)
        );

        // Check for overdue invoices every hour
        RecurringJob.AddOrUpdate<InvoiceService>(
            "check-overdue-invoices",
            service => service.CheckOverdueInvoices(CancellationToken.None),
            Cron.Hourly()
        );

        // Cleanup old logs every Sunday at midnight
        RecurringJob.AddOrUpdate<MaintenanceService>(
            "cleanup-old-logs",
            service => service.CleanupOldLogs(CancellationToken.None),
            Cron.Weekly(DayOfWeek.Sunday, 0)
        );

        // Database backup every 6 hours
        RecurringJob.AddOrUpdate<BackupService>(
            "database-backup",
            service => service.BackupDatabase(CancellationToken.None),
            "0 */6 * * *" // CRON: Every 6 hours
        );
    }
}

public class ReportService
{
    private readonly IReportGenerator _reportGenerator;
    private readonly IEmailSender _emailSender;
    private readonly ILogger<ReportService> _logger;

    public async Task GenerateDailyReports(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Starting daily report generation");

        try
        {
            var reports = await _reportGenerator.GenerateAsync(
                DateTime.UtcNow.Date.AddDays(-1),
                cancellationToken
            );

            foreach (var report in reports)
            {
                await _emailSender.SendReportAsync(report, cancellationToken);
            }

            _logger.LogInformation("Daily reports generated successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating daily reports");
            throw; // Hangfire will retry automatically
        }
    }
}
```

### 4. Continuation Jobs

**Chain jobs to execute sequentially:**

```csharp
public class InvoiceProcessingService
{
    private readonly IBackgroundJobClient _backgroundJobs;

    public void ProcessInvoiceWorkflow(Guid invoiceId)
    {
        // Step 1: Create invoice
        var createJobId = _backgroundJobs.Enqueue(() => 
            CreateInvoice(invoiceId, CancellationToken.None));

        // Step 2: Update ledger (after invoice created)
        var ledgerJobId = _backgroundJobs.ContinueJobWith(createJobId, () =>
            UpdateLedger(invoiceId, CancellationToken.None));

        // Step 3: Send notification (after ledger updated)
        _backgroundJobs.ContinueJobWith(ledgerJobId, () =>
            SendInvoiceNotification(invoiceId, CancellationToken.None));
    }

    public async Task CreateInvoice(Guid invoiceId, CancellationToken cancellationToken)
    {
        // Create invoice logic
    }

    public async Task UpdateLedger(Guid invoiceId, CancellationToken cancellationToken)
    {
        // Update ledger entries
    }

    public async Task SendInvoiceNotification(Guid invoiceId, CancellationToken cancellationToken)
    {
        // Send email/SMS notification
    }
}
```

### 5. Batch Jobs

**Process multiple items with progress tracking:**

```csharp
public class BulkInvoiceService
{
    private readonly IBackgroundJobClient _backgroundJobs;

    public string GenerateBulkInvoices(List<Guid> residentIds)
    {
        var batchId = BatchJob.StartNew(batch =>
        {
            foreach (var residentId in residentIds)
            {
                batch.Enqueue(() => GenerateInvoiceForResident(residentId, CancellationToken.None));
            }
        });

        // Continuation: Send summary email when all invoices are generated
        BatchJob.ContinueBatchWith(batchId, () =>
            SendBulkGenerationSummary(batchId, CancellationToken.None));

        return batchId;
    }

    public async Task GenerateInvoiceForResident(Guid residentId, CancellationToken cancellationToken)
    {
        // Generate individual invoice
    }

    public async Task SendBulkGenerationSummary(string batchId, CancellationToken cancellationToken)
    {
        // Send summary of bulk operation
    }
}
```

---

## Common Scheduled Jobs in Dhanman

### Common Service

| Job Name | Schedule | Purpose |
|----------|----------|---------|
| `sync-auth0-users` | Every 6 hours | Sync user data from Auth0 |
| `cleanup-expired-tokens` | Daily at 3 AM | Remove expired refresh tokens |
| `generate-system-health-report` | Daily at 8 AM | System health metrics report |

### Sales Service

| Job Name | Schedule | Purpose |
|----------|----------|---------|
| `generate-monthly-invoices` | 1st of month, 6 AM | Auto-generate recurring invoices |
| `send-payment-reminders` | Daily at 10 AM | Remind customers of due payments |
| `check-overdue-invoices` | Hourly | Mark invoices as overdue |
| `calculate-late-fees` | Daily at midnight | Apply late fees to overdue invoices |

### Purchase Service

| Job Name | Schedule | Purpose |
|----------|----------|---------|
| `send-po-approvals` | Every 2 hours | Notify pending PO approvals |
| `check-grn-matching` | Daily at 9 AM | Match GRNs with POs |
| `vendor-payment-reminders` | Weekly on Monday | Remind of vendor payment schedules |

### Payroll Service

| Job Name | Schedule | Purpose |
|----------|----------|---------|
| `process-monthly-salaries` | Last day of month, 11 PM | Calculate and process salaries |
| `generate-payslips` | 1st of month, 12 AM | Generate PDF payslips |
| `statutory-compliance-report` | Monthly, 2nd at 6 AM | Generate compliance reports |
| `attendance-summary` | Daily at 6 PM | Calculate daily attendance |

### Community Service

| Job Name | Schedule | Purpose |
|----------|----------|---------|
| `send-event-reminders` | Daily at 8 AM | Remind residents of upcoming events |
| `expire-visitor-passes` | Every 30 minutes | Expire one-time visitor passes |
| `maintenance-request-escalation` | Every 4 hours | Escalate pending maintenance requests |

### Inventory Service

| Job Name | Schedule | Purpose |
|----------|----------|---------|
| `check-low-stock-alerts` | Daily at 9 AM | Alert for items below reorder level |
| `generate-stock-report` | Weekly on Friday, 5 PM | Weekly inventory report |
| `expire-items-check` | Daily at midnight | Mark expired inventory items |

---

## Error Handling and Retries

### Automatic Retry Policy

```csharp
public class JobConfiguration
{
    public static void ConfigureJobFilters()
    {
        GlobalJobFilters.Filters.Add(new AutomaticRetryAttribute
        {
            Attempts = 3, // Retry up to 3 times
            DelaysInSeconds = new[] { 60, 300, 900 }, // 1 min, 5 min, 15 min
            OnAttemptsExceeded = AttemptsExceededAction.Delete
        });

        GlobalJobFilters.Filters.Add(new JobLoggerAttribute());
    }
}
```

### Custom Error Handling

```csharp
public class JobLoggerAttribute : JobFilterAttribute, IServerFilter
{
    private readonly ILogger<JobLoggerAttribute> _logger;

    public void OnPerforming(PerformingContext filterContext)
    {
        _logger.LogInformation(
            "Starting job: {JobType}.{Method}",
            filterContext.BackgroundJob.Job.Type.Name,
            filterContext.BackgroundJob.Job.Method.Name
        );
    }

    public void OnPerformed(PerformedContext filterContext)
    {
        if (filterContext.Exception != null)
        {
            _logger.LogError(
                filterContext.Exception,
                "Job failed: {JobType}.{Method}",
                filterContext.BackgroundJob.Job.Type.Name,
                filterContext.BackgroundJob.Job.Method.Name
            );
        }
        else
        {
            _logger.LogInformation(
                "Job completed: {JobType}.{Method}",
                filterContext.BackgroundJob.Job.Type.Name,
                filterContext.BackgroundJob.Job.Method.Name
            );
        }
    }
}
```

---

## Monitoring and Dashboard

### Accessing Hangfire Dashboard

**URLs by Environment:**
- Production: `https://common.dhanman.com/hangfire`
- QA: `https://qa.common.dhanman.com/hangfire`

### Dashboard Features

1. **Jobs Overview**: Real-time statistics on jobs
   - Succeeded jobs
   - Failed jobs
   - Processing jobs
   - Scheduled jobs
   - Recurring jobs

2. **Servers**: Monitor Hangfire server instances
   - Active workers
   - Server heartbeat
   - Queue processing status

3. **Recurring Jobs**: Manage scheduled jobs
   - Trigger jobs manually
   - View next execution time
   - Enable/disable jobs
   - View execution history

4. **Retries**: Track failed jobs
   - View error details
   - Manually retry jobs
   - Delete failed jobs

### Dashboard Security

```csharp
public class HangfireAuthorizationFilter : IDashboardAuthorizationFilter
{
    public bool Authorize(DashboardContext context)
    {
        var httpContext = context.GetHttpContext();
        
        // Allow only authenticated users with Admin role
        return httpContext.User.Identity?.IsAuthenticated == true
            && httpContext.User.IsInRole("Admin");
    }
}
```

---

## Performance Optimization

### Queue Prioritization

Jobs can be assigned to different queues based on priority:

```csharp
// Critical jobs (e.g., payment processing)
_backgroundJobs.Enqueue<PaymentService>(
    x => x.ProcessPayment(paymentId, CancellationToken.None),
    queue: "critical"
);

// Default priority jobs
_backgroundJobs.Enqueue<NotificationService>(
    x => x.SendNotification(userId, message, CancellationToken.None)
);

// Low priority jobs (e.g., analytics)
_backgroundJobs.Enqueue<AnalyticsService>(
    x => x.UpdateAnalytics(CancellationToken.None),
    queue: "low-priority"
);
```

### Worker Configuration

```csharp
builder.Services.AddHangfireServer(options =>
{
    // Allocate more workers for critical queue
    options.Queues = new[] { "critical", "critical", "default", "low-priority" };
    options.WorkerCount = Environment.ProcessorCount * 5;
    
    // Polling intervals
    options.SchedulePollingInterval = TimeSpan.FromSeconds(15);
    options.ServerCheckInterval = TimeSpan.FromMinutes(1);
    options.HeartbeatInterval = TimeSpan.FromSeconds(30);
});
```

---

## Best Practices

### Do's ✅
- Use meaningful job names for recurring jobs
- Implement proper cancellation token support
- Log job start, completion, and errors
- Use appropriate queue prioritization
- Handle idempotency (jobs may retry)
- Keep job methods small and focused
- Use batches for bulk operations
- Monitor job execution time

### Don'ts ❌
- Don't pass large objects as job parameters (use IDs)
- Don't use non-serializable parameters
- Don't rely on static state or DI scope
- Don't create infinite retry loops
- Don't skip error handling
- Don't schedule too many jobs simultaneously
- Don't ignore job performance metrics

---

## Integration with Other Components

### With RabbitMQ Events

Hangfire jobs can be triggered by RabbitMQ events:

```csharp
public class InvoiceCreatedEventHandler : IMessageHandler<InvoiceCreatedEvent>
{
    private readonly IBackgroundJobClient _backgroundJobs;

    public async Task HandleAsync(InvoiceCreatedEvent @event, CancellationToken cancellationToken)
    {
        // Schedule reminder for due date
        _backgroundJobs.Schedule<ReminderService>(
            x => x.SendInvoiceReminder(@event.InvoiceId, cancellationToken),
            @event.DueDate.AddDays(-1)
        );

        // Fire-and-forget: Send creation notification
        _backgroundJobs.Enqueue<NotificationService>(
            x => x.SendInvoiceCreatedNotification(@event.InvoiceId, cancellationToken)
        );
    }
}
```

### With CQRS Commands

Commands can trigger background jobs:

```csharp
public class ApproveInvoiceCommandHandler : IRequestHandler<ApproveInvoiceCommand, Result>
{
    private readonly IBackgroundJobClient _backgroundJobs;

    public async Task<Result> Handle(ApproveInvoiceCommand request, CancellationToken cancellationToken)
    {
        // Approve invoice immediately
        var invoice = await _repository.GetByIdAsync(request.InvoiceId);
        invoice.Approve(request.ApprovedBy);
        await _repository.SaveAsync(invoice);

        // Queue background job to update related systems
        _backgroundJobs.Enqueue(() => UpdateRelatedSystems(request.InvoiceId, cancellationToken));

        return Result.Success();
    }
}
```

---

## Troubleshooting

### Common Issues

**1. Jobs Not Processing**
- Check Hangfire server is running
- Verify database connection
- Check worker count > 0
- Review server logs

**2. Jobs Failing Repeatedly**
- Check error logs in dashboard
- Verify job parameters are serializable
- Check database connectivity
- Review retry configuration

**3. Performance Issues**
- Increase worker count
- Optimize job execution time
- Use appropriate queue prioritization
- Check database performance

**4. Dashboard Not Accessible**
- Verify authorization filter
- Check route configuration
- Ensure user has required permissions

---

## Migration from Legacy Systems

If migrating from other scheduling systems:

| Legacy System | Migration Strategy |
|---------------|-------------------|
| **Cron Jobs** | Convert to Hangfire RecurringJob with same schedule |
| **Windows Scheduler** | Wrap task logic in Hangfire job method |
| **Quartz.NET** | Map Quartz triggers to Hangfire job types |
| **Manual Background Tasks** | Convert to fire-and-forget jobs |

---

## Future Enhancements

- [ ] Job priority queue optimization
- [ ] Advanced retry strategies per job type
- [ ] Job execution SLA monitoring
- [ ] Integration with Grafana for metrics
- [ ] Job execution time predictions
- [ ] Automatic job cleanup policies
- [ ] Job dependency graph visualization

---

## Related Documentation
- [Event Sourcing](event-sourcing.md) — Event-driven architecture
- [CQRS Pattern](cqrs.md) — Command/Query separation
- [Monitoring](../../operations/monitoring/dashboards.md) — System observability

---

## Summary

Hangfire provides Dhanman with:
- Reliable background job processing
- Flexible scheduling options
- Built-in monitoring and retry logic
- Scalable distributed execution
- Easy integration with existing architecture

All microservices use Hangfire consistently for scheduled tasks, ensuring reliable and observable background operations across the entire system.
