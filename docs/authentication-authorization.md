# Request ->Authentication->Authorization

## Overview

This document outlines the flow of a request from when it enters the system, how authentication and authorization are handled, and how the `IUserContextService`, `PermissionHandler`, and `PermissionService` work together.

## Summary

1.  **Incoming Request**: A request with a JWT token arrives at the API.
2.  **Authentication**: The JWT token is validated, and user claims are populated.
3.  **Dependency Injection**: `IUserContextService` is injected to provide user context.
4.  **Controller Handling**: The request is routed to a controller derived from `ApiController`.
5.  **Authorization**: The `[Authorize]` attribute triggers the `PermissionHandler`.
6.  **Permission Checking**:
    -   `PermissionHandler` uses `IServiceScopeFactory` to create a new scope and resolve `IPermissionService`.
    -   `PermissionService` checks the database and cache for the required permissions.
7.  **Action Execution**: If authorization succeeds, the controller action is executed.

## Detailed Steps

### 1. Incoming Request with Token

When a client makes a request to the API, it includes a JWT token in the `Authorization` header.

```http
GET /api/orders HTTP/1.1
Host: api.example.com
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```
### 2. Authentication

The middleware in `Startup.cs` or `Program.cs` is configured to validate JWT tokens.

```csharp
public void ConfigureServices(IServiceCollection services)
{
    services.AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options =>
    {
        options.Authority = "https://your-auth-server.com";
        options.Audience = "your-audience";
        // Other JWT validation parameters
    });

    services.AddAuthorization();
    services.AddHttpContextAccessor();
    services.AddScoped<IUserContextService, UserContextService>();
    services.AddScoped<IPermissionService, PermissionService>();
    services.AddScoped<IAuthorizationHandler, PermissionHandler>();

    services.AddDbContext<PermissionDbContext>(options =>
        options.UseNpgsql(Configuration.GetConnectionString("PermissionDbConnection"))
               .UseSnakeCaseNamingConvention());

    // Other service registrations
}
``` 

When the request arrives, the `AddJwtBearer` middleware validates the token. If the token is valid, the user is authenticated and the user's claims are populated in `HttpContext.User`.

### 3. Dependency Injection

Services like `IUserContextService` are injected into controllers and other services as needed. This is configured in the `ConfigureServices` method as shown above.

### 4. Controller Handling

The request is routed to the appropriate controller. All controllers inherit from `ApiController`, which ensures they have access to common functionality like `IUserContextService`.

```csharp

[Authorize]
public abstract class ApiController : ControllerBase
{
    protected IMediator Mediator { get; }
    protected IUserContextService UserContextService { get; }

    protected ApiController(IMediator mediator, IUserContextService userContextService)
    {
        Mediator = mediator;
        UserContextService = userContextService;
    }
}
``` 

### 5. Authorization

The `[Authorize]` attribute on `ApiController` triggers the authorization process.

### 6. Permission Checking

1.  **PermissionHandler**:
    
    -   The `PermissionHandler` is an `AuthorizationHandler` that checks if the user has the required permissions.
    
```csharp
    public class PermissionHandler : AuthorizationHandler<PermissionRequirement>
    {
        private readonly IServiceScopeFactory _serviceScopeFactory;
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly ILogger<PermissionHandler> _logger;
    
        public PermissionHandler(IServiceScopeFactory serviceScopeFactory, IHttpContextAccessor httpContextAccessor, ILogger<PermissionHandler> logger)
        {
            _serviceScopeFactory = serviceScopeFactory;
            _httpContextAccessor = httpContextAccessor;
            _logger = logger;
        }
    
        protected override async Task HandleRequirementAsync(AuthorizationHandlerContext context, PermissionRequirement requirement)
        {
            _logger.LogDebug("Starting authorization check for permission: {Permission}", requirement.Permission);
    
            var userIdClaim = _httpContextAccessor.HttpContext.User?.FindFirst("dhanman_id");
            if (userIdClaim != null && Guid.TryParse(userIdClaim.Value, out var userId))
            {
                _logger.LogInformation("User {UserId} found, checking permissions.", userId);
    
                if (await HasPermissionIterativelyAsync(userId, requirement))
                {
                    context.Succeed(requirement);
                    _logger.LogInformation("Authorization succeeded for user {UserId} on permission {Permission}.", userId, requirement.Permission);
                    return;
                }
            }
            else
            {
                _logger.LogWarning("User ID claim 'dhanman_id' not found or invalid.");
            }
    
            _logger.LogWarning("Authorization failed for user {UserId} on permission {Permission}.", userIdClaim?.Value, requirement.Permission);
            context.Fail();
        }
    
        private async Task<bool> HasPermissionIterativelyAsync(Guid userId, PermissionRequirement requirement)
        {
            _logger.LogDebug("Checking permissions iteratively for user {UserId}.", userId);
    
            var permissionsToCheck = new Stack<PermissionRequirement>();
            permissionsToCheck.Push(requirement);
    
            while (permissionsToCheck.Count > 0)
            {
                var currentPermission = permissionsToCheck.Pop();
    
                using (var scope = _serviceScopeFactory.CreateScope())
                {
                    var permissionService = scope.ServiceProvider.GetRequiredService<IPermissionService>();
    
                    // Check if the user has the current permission
                    if (await permissionService.HasPermissionAsync(userId, currentPermission.Permission))
                    {
                        _logger.LogDebug("Permission {Permission} granted for user {UserId}.", currentPermission.Permission, userId);
                        return true;
                    }
                }
    
                // Add child permissions to the stack for checking
                foreach (var childPermission in currentPermission.ChildPermissions)
                {
                    permissionsToCheck.Push(childPermission);
                }
            }
    
            _logger.LogDebug("Permission {Permission} denied for user {UserId}.", requirement.Permission, userId);
            return false;
        }
    }
``` 
    
2.  **PermissionService**:
    
    -   The `PermissionService` checks if the user has the necessary permissions by querying the database.
    
```csharp
    
    public class PermissionService : IPermissionService
    {
        private readonly PermissionDbContext _context;
        private readonly IMemoryCache _cache;
        private readonly ILogger<PermissionService> _logger;
    
        public PermissionService(PermissionDbContext context, IMemoryCache cache, ILogger<PermissionService> logger)
        {
            _context = context;
            _cache = cache;
            _logger = logger;
        }
    
        public async Task<bool> HasPermissionAsync(Guid userId, string permission)
        {
            var cacheKey = $"{userId}_{permission}";
            _logger.LogDebug("Checking permissions for user {UserId} on permission {Permission}", userId, permission);
    
            if (_cache.TryGetValue(cacheKey, out bool hasPermissionfromCache))
            {
                _logger.LogInformation("Permission {Permission} for user {UserId} found in cache.", permission, userId);
                return hasPermissionfromCache;
            }
    
            _logger.LogDebug("Permission {Permission} for user {UserId} not found in cache. Checking database.", permission, userId);
    
            bool hasPermission = await _context.UserPermissions
                .AnyAsync(up => up.UserId == userId && up.Permission.Name == permission);
    
            var cacheEntryOptions = new MemoryCacheEntryOptions()
                .SetSlidingExpiration(TimeSpan.FromMinutes(60));
    
            _cache.Set(cacheKey, hasPermission, cacheEntryOptions);
    
            _logger.LogInformation("Permission {Permission} for user {UserId} retrieved from database and cached: {HasPermission}", permission, userId, hasPermission);
    
            return hasPermission;
        }
    }
```
    

### 7. Action Execution

If the authorization succeeds, the controller action is executed. If it fails, the request is denied with a `403 Forbidden` response.

