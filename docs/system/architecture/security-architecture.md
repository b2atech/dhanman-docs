# Security Architecture

## Overview

This document describes Dhanman's security architecture, authentication and authorization mechanisms, data protection strategies, and security best practices implemented across the system.

---

## Security Principles

### Core Tenets

1. **Defense in Depth**: Multiple layers of security controls
2. **Least Privilege**: Minimum necessary permissions
3. **Zero Trust**: Verify every request, trust nothing
4. **Security by Design**: Build security into architecture
5. **Fail Secure**: Default to denying access on errors
6. **Audit Everything**: Log all security-relevant events

---

## Authentication

### Auth0 Integration

Dhanman uses **Auth0** as the identity provider for centralized authentication.

**Architecture:**

```
┌─────────────┐                    ┌──────────────┐
│   Frontend  │                    │    Auth0     │
│   (React)   │────── Login ──────▶│   Tenant     │
│             │                    │              │
└──────┬──────┘                    └──────┬───────┘
       │                                  │
       │ ◀────── JWT Token ───────────────┘
       │
       │ API Request + JWT
       │
┌──────▼──────┐                    ┌──────────────┐
│   Backend   │─── Validate JWT ──▶│   Auth0      │
│  Services   │                    │   JWKS       │
└─────────────┘                    └──────────────┘
```

### Auth0 Configuration

**Tenants:**
- **Production**: `prod-dhanman.auth0.com`
- **QA**: `qa-dhanman.auth0.com`

**Applications:**
- **Web Application** (SPA): React frontend
- **Machine-to-Machine**: Service-to-service communication
- **Management API**: Administrative operations

**Features Enabled:**
- Multi-factor Authentication (MFA)
- Email verification
- Password reset
- Social login (Google, Microsoft)
- Passwordless (SMS/Email OTP)

### JWT Token Structure

```json
{
  "header": {
    "alg": "RS256",
    "typ": "JWT",
    "kid": "abc123..."
  },
  "payload": {
    "iss": "https://prod-dhanman.auth0.com/",
    "sub": "auth0|60a1234567890",
    "aud": [
      "https://api.dhanman.com",
      "https://prod-dhanman.auth0.com/userinfo"
    ],
    "iat": 1704067200,
    "exp": 1704153600,
    "azp": "client_id_here",
    "scope": "openid profile email",
    
    // Custom claims (added via Auth0 Actions)
    "org_id": "org_12345",
    "customer_id": "cust_67890",
    "roles": ["admin", "accountant"],
    "permissions": [
      "invoice:create",
      "invoice:read",
      "invoice:update",
      "report:generate"
    ]
  }
}
```

### Auth0 Actions (Custom Logic)

**Login Flow Action:**

```javascript
exports.onExecutePostLogin = async (event, api) => {
  const namespace = 'https://dhanman.com';
  
  if (event.authorization) {
    // Get user metadata from app_metadata
    const orgId = event.user.app_metadata.org_id;
    const customerId = event.user.app_metadata.customer_id;
    const roles = event.authorization.roles;
    
    // Add custom claims to token
    api.idToken.setCustomClaim(`${namespace}/org_id`, orgId);
    api.idToken.setCustomClaim(`${namespace}/customer_id`, customerId);
    api.idToken.setCustomClaim(`${namespace}/roles`, roles);
    
    api.accessToken.setCustomClaim(`${namespace}/org_id`, orgId);
    api.accessToken.setCustomClaim(`${namespace}/customer_id`, customerId);
    api.accessToken.setCustomClaim(`${namespace}/roles`, roles);
  }
};
```

### Backend JWT Validation

**.NET Configuration:**

```csharp
// Program.cs
builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Authority = builder.Configuration["Auth0:Authority"];
        options.Audience = builder.Configuration["Auth0:Audience"];
        
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = builder.Configuration["Auth0:Authority"],
            ValidateAudience = true,
            ValidAudience = builder.Configuration["Auth0:Audience"],
            ValidateLifetime = true,
            ClockSkew = TimeSpan.Zero, // No tolerance for expired tokens
            RequireExpirationTime = true,
            RequireSignedTokens = true
        };

        options.Events = new JwtBearerEvents
        {
            OnAuthenticationFailed = context =>
            {
                _logger.LogWarning(
                    "Authentication failed: {Error}", 
                    context.Exception.Message
                );
                return Task.CompletedTask;
            },
            OnTokenValidated = context =>
            {
                var claims = context.Principal?.Claims;
                var userId = claims?.FirstOrDefault(c => c.Type == ClaimTypes.NameIdentifier)?.Value;
                _logger.LogInformation("Token validated for user {UserId}", userId);
                return Task.CompletedTask;
            }
        };
    });
```

**Configuration File:**

```json
{
  "Auth0": {
    "Authority": "https://prod-dhanman.auth0.com/",
    "Audience": "https://api.dhanman.com",
    "ClientId": "your_client_id",
    "ClientSecret": "your_client_secret"
  }
}
```

---

## Authorization

### Role-Based Access Control (RBAC)

**Roles Hierarchy:**

```
System Administrator
├── Organization Admin
│   ├── Financial Manager
│   │   ├── Accountant
│   │   └── Billing Clerk
│   ├── HR Manager
│   │   ├── Payroll Admin
│   │   └── HR Assistant
│   └── Operations Manager
│       ├── Procurement Officer
│       └── Inventory Manager
├── Resident
└── Guard
```

**Role Definitions:**

| Role | Description | Typical Permissions |
|------|-------------|---------------------|
| **System Admin** | Full system access | All permissions |
| **Org Admin** | Organization owner | All within organization |
| **Financial Manager** | Manages finances | Invoice, receipt, ledger operations |
| **Accountant** | Accounting tasks | Create/approve invoices, view reports |
| **Billing Clerk** | Basic billing | Create invoices, receipts |
| **Payroll Admin** | Payroll processing | Create/approve salaries, view reports |
| **Procurement Officer** | Purchase management | Create/approve POs, manage vendors |
| **Resident** | Apartment resident | View own invoices, make payments |
| **Guard** | Security staff | Visitor check-in, gate management |

### Permission Model

**Permission Format:** `{resource}:{action}`

**Examples:**
- `invoice:create`
- `invoice:read`
- `invoice:update`
- `invoice:delete`
- `invoice:approve`
- `report:generate`
- `user:manage`

**Permission Matrix:**

| Permission | System Admin | Org Admin | Accountant | Billing Clerk | Resident |
|------------|-------------|-----------|------------|---------------|----------|
| `invoice:create` | ✅ | ✅ | ✅ | ✅ | ❌ |
| `invoice:approve` | ✅ | ✅ | ✅ | ❌ | ❌ |
| `invoice:delete` | ✅ | ✅ | ❌ | ❌ | ❌ |
| `invoice:read` | ✅ | ✅ | ✅ | ✅ | ✅ (own only) |
| `payment:create` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `report:generate` | ✅ | ✅ | ✅ | ❌ | ❌ |
| `user:manage` | ✅ | ✅ | ❌ | ❌ | ❌ |

### Authorization Implementation

**Attribute-Based Authorization:**

```csharp
[ApiController]
[Route("api/[controller]")]
[Authorize] // Requires authentication
public class InvoicesController : ControllerBase
{
    [HttpPost]
    [RequirePermission("invoice:create")] // Custom attribute
    public async Task<IActionResult> CreateInvoice([FromBody] CreateInvoiceRequest request)
    {
        var command = new CreateInvoiceCommand
        {
            CustomerId = request.CustomerId,
            Amount = request.Amount,
            // Organization ID from JWT claim
            OrganizationId = User.GetOrganizationId()
        };

        var result = await _mediator.Send(command);
        return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
    }

    [HttpGet("{id}")]
    [RequirePermission("invoice:read")]
    public async Task<IActionResult> GetInvoice(Guid id)
    {
        var query = new GetInvoiceByIdQuery { InvoiceId = id };
        var result = await _mediator.Send(query);
        
        if (result.IsFailure)
            return NotFound();

        // Check if user has access to this organization's invoice
        if (!User.HasAccessToOrganization(result.Value.OrganizationId))
            return Forbid();

        return Ok(result.Value);
    }

    [HttpDelete("{id}")]
    [RequirePermission("invoice:delete")]
    [RequireRole("SystemAdmin", "OrgAdmin")] // Multiple roles
    public async Task<IActionResult> DeleteInvoice(Guid id)
    {
        var command = new DeleteInvoiceCommand { InvoiceId = id };
        var result = await _mediator.Send(command);
        return result.IsSuccess ? NoContent() : BadRequest(result.Error);
    }
}
```

**Custom Authorization Attributes:**

```csharp
public class RequirePermissionAttribute : TypeFilterAttribute
{
    public RequirePermissionAttribute(params string[] permissions) 
        : base(typeof(PermissionAuthorizationFilter))
    {
        Arguments = new object[] { permissions };
    }
}

public class PermissionAuthorizationFilter : IAuthorizationFilter
{
    private readonly string[] _permissions;

    public PermissionAuthorizationFilter(string[] permissions)
    {
        _permissions = permissions;
    }

    public void OnAuthorization(AuthorizationFilterContext context)
    {
        var user = context.HttpContext.User;
        
        if (!user.Identity?.IsAuthenticated ?? true)
        {
            context.Result = new UnauthorizedResult();
            return;
        }

        var userPermissions = user.Claims
            .Where(c => c.Type == "permissions")
            .Select(c => c.Value)
            .ToList();

        var hasPermission = _permissions.Any(p => userPermissions.Contains(p));

        if (!hasPermission)
        {
            context.Result = new ForbidResult();
            _logger.LogWarning(
                "User {UserId} denied access. Required permissions: {Permissions}",
                user.GetUserId(),
                string.Join(", ", _permissions)
            );
        }
    }
}
```

**User Extensions:**

```csharp
public static class UserExtensions
{
    public static Guid GetUserId(this ClaimsPrincipal user)
    {
        var claim = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return Guid.TryParse(claim, out var userId) ? userId : Guid.Empty;
    }

    public static Guid GetOrganizationId(this ClaimsPrincipal user)
    {
        var claim = user.FindFirst("https://dhanman.com/org_id")?.Value;
        return Guid.TryParse(claim, out var orgId) ? orgId : Guid.Empty;
    }

    public static List<string> GetPermissions(this ClaimsPrincipal user)
    {
        return user.Claims
            .Where(c => c.Type == "permissions")
            .Select(c => c.Value)
            .ToList();
    }

    public static bool HasPermission(this ClaimsPrincipal user, string permission)
    {
        return user.GetPermissions().Contains(permission);
    }

    public static bool HasAccessToOrganization(this ClaimsPrincipal user, Guid organizationId)
    {
        var userOrgId = user.GetOrganizationId();
        return userOrgId == organizationId || user.IsInRole("SystemAdmin");
    }
}
```

---

## Data Security

### Multi-tenancy and Data Isolation

**Row-Level Security via Global Query Filters:**

```csharp
public class SalesDbContext : DbContext
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Apply global query filter for all tenant-aware entities
        modelBuilder.Entity<Invoice>().HasQueryFilter(e => 
            e.OrganizationId == GetCurrentOrganizationId());

        modelBuilder.Entity<Receipt>().HasQueryFilter(e => 
            e.OrganizationId == GetCurrentOrganizationId());

        modelBuilder.Entity<Customer>().HasQueryFilter(e => 
            e.OrganizationId == GetCurrentOrganizationId());
    }

    private Guid GetCurrentOrganizationId()
    {
        var user = _httpContextAccessor.HttpContext?.User;
        return user?.GetOrganizationId() ?? Guid.Empty;
    }
}
```

**Bypass Filter for System Admin:**

```csharp
public async Task<List<Invoice>> GetAllInvoicesForSystemAdmin()
{
    // Bypass tenant filter for system admin
    return await _context.Invoices
        .IgnoreQueryFilters()
        .ToListAsync();
}
```

### Encryption

#### Data at Rest

**Database Encryption:**
- PostgreSQL Transparent Data Encryption (TDE) via pgcrypto
- Sensitive columns encrypted using AES-256

```sql
-- Encrypt sensitive data
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Store encrypted credit card info
INSERT INTO payment_methods (customer_id, card_number_encrypted)
VALUES (
    'customer_id_here',
    pgp_sym_encrypt('4111111111111111', 'encryption_key')
);

-- Retrieve and decrypt
SELECT 
    customer_id,
    pgp_sym_decrypt(card_number_encrypted::bytea, 'encryption_key') AS card_number
FROM payment_methods;
```

**File Storage Encryption:**
- MinIO server-side encryption (SSE-S3)
- Files encrypted before upload for sensitive documents

#### Data in Transit

**TLS/SSL Configuration:**
- TLS 1.2 and 1.3 only
- Strong cipher suites (AES-256-GCM)
- Perfect Forward Secrecy (PFS)
- HSTS headers enforced

**NGINX SSL Configuration:**

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
ssl_prefer_server_ciphers on;
ssl_session_timeout 10m;
ssl_session_cache shared:SSL:10m;
ssl_stapling on;
ssl_stapling_verify on;

# HSTS
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
```

### Secrets Management

**Environment Variables:**

```bash
# systemd service file
Environment=ConnectionStrings__DefaultConnection="Host=...;Password=${DB_PASSWORD}"
Environment=Auth0__ClientSecret="${AUTH0_CLIENT_SECRET}"
Environment=Brevo__ApiKey="${BREVO_API_KEY}"
```

**GitHub Secrets:**
- `DB_PASSWORD_PROD`
- `DB_PASSWORD_QA`
- `AUTH0_CLIENT_SECRET_PROD`
- `AUTH0_CLIENT_SECRET_QA`
- `BREVO_API_KEY`
- `SSH_PRIVATE_KEY`

**Best Practices:**
- Never commit secrets to repository
- Rotate secrets regularly (every 90 days)
- Use different secrets for QA and Production
- Limit secret access to necessary personnel
- Use strong, randomly generated secrets

---

## API Security

### Rate Limiting

**NGINX Configuration:**

```nginx
# Define rate limit zones
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=login_limit:10m rate=5r/m;

server {
    location /api/ {
        limit_req zone=api_limit burst=20 nodelay;
        limit_req_status 429;
        
        proxy_pass http://backend;
    }

    location /api/auth/login {
        limit_req zone=login_limit burst=3 nodelay;
        
        proxy_pass http://backend;
    }
}
```

**Application-Level Rate Limiting:**

```csharp
builder.Services.AddMemoryCache();
builder.Services.AddSingleton<IRateLimitConfiguration, RateLimitConfiguration>();

builder.Services.Configure<IpRateLimitOptions>(options =>
{
    options.EnableEndpointRateLimiting = true;
    options.StackBlockedRequests = false;
    options.HttpStatusCode = 429;
    options.RealIpHeader = "X-Real-IP";
    options.GeneralRules = new List<RateLimitRule>
    {
        new RateLimitRule
        {
            Endpoint = "*",
            Period = "1s",
            Limit = 10
        },
        new RateLimitRule
        {
            Endpoint = "*",
            Period = "1m",
            Limit = 100
        }
    };
});

app.UseIpRateLimiting();
```

### CORS Configuration

```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowedOrigins", policy =>
    {
        policy.WithOrigins(
            "https://app.dhanman.com",
            "https://qa.app.dhanman.com"
        )
        .AllowAnyMethod()
        .AllowAnyHeader()
        .AllowCredentials()
        .SetIsOriginAllowedToAllowWildcardSubdomains();
    });
});

app.UseCors("AllowedOrigins");
```

### Security Headers

```csharp
app.Use(async (context, next) =>
{
    context.Response.Headers.Add("X-Content-Type-Options", "nosniff");
    context.Response.Headers.Add("X-Frame-Options", "SAMEORIGIN");
    context.Response.Headers.Add("X-XSS-Protection", "1; mode=block");
    context.Response.Headers.Add("Referrer-Policy", "strict-origin-when-cross-origin");
    context.Response.Headers.Add("Content-Security-Policy", 
        "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'");
    
    await next();
});
```

### Input Validation

**FluentValidation:**

```csharp
public class CreateInvoiceCommandValidator : AbstractValidator<CreateInvoiceCommand>
{
    public CreateInvoiceCommandValidator()
    {
        RuleFor(x => x.CustomerId)
            .NotEmpty().WithMessage("Customer ID is required")
            .Must(BeValidGuid).WithMessage("Invalid Customer ID format");

        RuleFor(x => x.Amount)
            .GreaterThan(0).WithMessage("Amount must be positive")
            .LessThanOrEqualTo(1000000).WithMessage("Amount exceeds maximum");

        RuleFor(x => x.InvoiceNumber)
            .NotEmpty().WithMessage("Invoice number is required")
            .Matches(@"^INV-\d{6}-\d{4}$").WithMessage("Invalid invoice number format")
            .MaximumLength(50).WithMessage("Invoice number too long");

        RuleFor(x => x.LineItems)
            .NotEmpty().WithMessage("At least one line item required")
            .Must(items => items.Count <= 100).WithMessage("Too many line items");
    }

    private bool BeValidGuid(Guid guid)
    {
        return guid != Guid.Empty;
    }
}
```

**SQL Injection Prevention:**

Always use parameterized queries via Entity Framework Core:

```csharp
// ✅ SAFE: Parameterized query
var invoices = await _context.Invoices
    .Where(i => i.CustomerId == customerId)
    .ToListAsync();

// ❌ DANGEROUS: String concatenation
// NEVER DO THIS:
// var sql = $"SELECT * FROM Invoices WHERE CustomerId = '{customerId}'";
```

---

## Audit Logging

### Audit Trail

**Audit Log Entity:**

```csharp
public class AuditLog
{
    public Guid Id { get; set; }
    public DateTime Timestamp { get; set; }
    public Guid UserId { get; set; }
    public string UserName { get; set; }
    public Guid OrganizationId { get; set; }
    public string Action { get; set; } // CREATE, UPDATE, DELETE, READ
    public string EntityType { get; set; } // Invoice, PurchaseOrder, etc.
    public Guid EntityId { get; set; }
    public string Changes { get; set; } // JSON of changes
    public string IpAddress { get; set; }
    public string UserAgent { get; set; }
}
```

**Audit Interceptor:**

```csharp
public class AuditInterceptor : SaveChangesInterceptor
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public override async ValueTask<InterceptionResult<int>> SavingChangesAsync(
        DbContextEventData eventData,
        InterceptionResult<int> result,
        CancellationToken cancellationToken = default)
    {
        var context = eventData.Context;
        if (context == null) return result;

        var entries = context.ChangeTracker.Entries()
            .Where(e => e.State == EntityState.Added || 
                       e.State == EntityState.Modified || 
                       e.State == EntityState.Deleted)
            .ToList();

        foreach (var entry in entries)
        {
            var auditLog = new AuditLog
            {
                Timestamp = DateTime.UtcNow,
                UserId = GetCurrentUserId(),
                UserName = GetCurrentUserName(),
                OrganizationId = GetCurrentOrganizationId(),
                Action = entry.State.ToString(),
                EntityType = entry.Entity.GetType().Name,
                EntityId = GetEntityId(entry),
                Changes = SerializeChanges(entry),
                IpAddress = GetClientIpAddress(),
                UserAgent = GetUserAgent()
            };

            context.Set<AuditLog>().Add(auditLog);
        }

        return await base.SavingChangesAsync(eventData, result, cancellationToken);
    }
}
```

### Security Event Logging

**Structured Logging with Serilog:**

```csharp
// Failed login attempt
_logger.LogWarning(
    "Failed login attempt for user {Username} from IP {IpAddress}",
    username,
    ipAddress
);

// Unauthorized access
_logger.LogWarning(
    "Unauthorized access attempt: User {UserId} tried to access {Resource} with insufficient permissions",
    userId,
    resourcePath
);

// Suspicious activity
_logger.LogWarning(
    "Suspicious activity detected: User {UserId} attempted {Action} {Count} times in {TimeSpan}",
    userId,
    action,
    attemptCount,
    timeSpan
);
```

---

## Security Monitoring

### Metrics to Track

1. **Authentication Failures**
   - Failed login attempts per user
   - Failed login attempts per IP
   - Account lockouts

2. **Authorization Violations**
   - Unauthorized access attempts
   - Permission denied events
   - Privilege escalation attempts

3. **Suspicious Patterns**
   - High request rates from single IP
   - Multiple failed authentications
   - Access to sensitive endpoints
   - Unusual access times

### Alerting Rules

```yaml
# Example Grafana alert rules
- name: SecurityAlerts
  rules:
    - alert: HighFailedLoginRate
      expr: rate(failed_login_attempts[5m]) > 10
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High failed login rate detected"
        description: "More than 10 failed login attempts per minute"

    - alert: SuspiciousIPActivity
      expr: count by (ip_address) (unauthorized_access) > 5
      for: 10m
      labels:
        severity: critical
      annotations:
        summary: "Suspicious IP activity"
        description: "IP {{ $labels.ip_address }} has multiple unauthorized access attempts"
```

---

## Compliance

### GDPR Considerations

- **Data minimization**: Collect only necessary data
- **Right to access**: API endpoints for users to retrieve their data
- **Right to deletion**: Soft delete with anonymization
- **Data portability**: Export user data in JSON format
- **Consent management**: Track user consent for data processing

### Audit Requirements

- **Immutable audit logs**: Cannot be modified or deleted
- **Retention**: 7 years for financial records
- **Access logs**: Who accessed what and when
- **Change tracking**: All modifications to financial data

---

## Best Practices

### Do's ✅
- Use Auth0 for authentication
- Implement role-based access control
- Validate all inputs
- Use parameterized queries
- Encrypt sensitive data
- Implement rate limiting
- Log all security events
- Use HTTPS everywhere
- Implement CORS properly
- Set security headers
- Rotate secrets regularly
- Use strong passwords/keys
- Implement MFA for admin accounts

### Don'ts ❌
- Don't store passwords in plain text
- Don't trust client input
- Don't expose sensitive data in logs
- Don't use weak encryption
- Don't skip authentication/authorization checks
- Don't ignore security updates
- Don't commit secrets to repository
- Don't use deprecated cryptographic algorithms
- Don't disable SSL certificate validation

---

## Security Checklist

### Application Security
- [ ] JWT validation implemented
- [ ] Permission-based authorization
- [ ] Input validation on all endpoints
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (output encoding)
- [ ] CSRF protection (SameSite cookies)
- [ ] Rate limiting configured
- [ ] Security headers set

### Infrastructure Security
- [ ] HTTPS/TLS enabled
- [ ] Firewall rules configured
- [ ] SSH key-based authentication only
- [ ] Regular security updates
- [ ] Database access restricted
- [ ] Backups encrypted
- [ ] Secrets managed securely

### Monitoring & Logging
- [ ] Audit logging enabled
- [ ] Security event logging
- [ ] Failed login tracking
- [ ] Unauthorized access alerts
- [ ] Regular log review

---

## Related Documentation
- [Developer Onboarding](../../onboarding/developer-onboarding.md)
- [Deployment Security](deployment-scalability.md)
- [API Guidelines](../../development/api-internal/)

---

## Summary

Dhanman's security architecture provides:
- **Strong authentication** via Auth0 with JWT tokens
- **Fine-grained authorization** with RBAC and permissions
- **Data protection** through encryption and multi-tenancy isolation
- **API security** with rate limiting and input validation
- **Comprehensive audit logging** for compliance
- **Security monitoring** and alerting

The architecture follows security best practices and industry standards to protect sensitive financial data and user information.
