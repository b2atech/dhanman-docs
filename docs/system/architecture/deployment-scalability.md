# Deployment Architecture and Scalability

## Overview

This document describes Dhanman's deployment architecture, infrastructure topology, scalability strategies, and operational procedures for managing the system across different environments.

---

## Environment Overview

### Current Deployment Topology

```
┌──────────────────────────────────────────────────────────────────┐
│                         PRODUCTION                                │
│                    OVH VPS Singapore                              │
│                    51.79.156.217                                  │
│                                                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐            │
│  │   NGINX     │  │  Microservices │ │  PostgreSQL  │            │
│  │   Reverse   │─▶│  (6 services)  │─│      18      │            │
│  │   Proxy     │  │  Ports: 5001-  │ │              │            │
│  │   :80, :443 │  │        5006    │ │              │            │
│  └─────────────┘  └─────────────┘  └──────────────┘            │
│                                                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐            │
│  │   RabbitMQ  │  │    MinIO    │  │   Grafana    │            │
│  │   :5672     │  │    :9000    │  │   + Loki     │            │
│  └─────────────┘  └─────────────┘  └──────────────┘            │
│                                                                   │
│  ┌─────────────┐  ┌─────────────┐                               │
│  │   Hangfire  │  │   Netdata   │                               │
│  │  Dashboard  │  │   Metrics   │                               │
│  └─────────────┘  └─────────────┘                               │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                             QA                                    │
│                    OVH VPS France                                 │
│                    54.37.159.71                                   │
│                                                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐            │
│  │   NGINX     │  │  Microservices │ │  PostgreSQL  │            │
│  │   Reverse   │─▶│  (6 services)  │─│      18      │            │
│  │   Proxy     │  │  Ports: 5101-  │ │              │            │
│  │   :80, :443 │  │        5106    │ │              │            │
│  └─────────────┘  └─────────────┘  └──────────────┘            │
│                                                                   │
│  ┌─────────────┐  ┌─────────────┐                               │
│  │   RabbitMQ  │  │    MinIO    │                               │
│  │   :5672     │  │    :9000    │                               │
│  └─────────────┘  └─────────────┘                               │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                       EXTERNAL SERVICES                           │
│                                                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐            │
│  │    Auth0    │  │    Brevo    │  │   Backblaze  │            │
│  │     SaaS    │  │    SMTP     │  │   B2 Backup  │            │
│  └─────────────┘  └─────────────┘  └──────────────┘            │
└──────────────────────────────────────────────────────────────────┘
```

---

## Service Deployment

### Port Allocation

| Service | Production Port | QA Port | Domain |
|---------|----------------|---------|---------|
| **dhanman-common** | 5001 | 5101 | `common.dhanman.com` / `qa.common.dhanman.com` |
| **dhanman-community** | 5002 | 5102 | `community.dhanman.com` / `qa.community.dhanman.com` |
| **dhanman-inventory** | 5003 | 5103 | `inventory.dhanman.com` / `qa.inventory.dhanman.com` |
| **dhanman-payroll** | 5004 | 5104 | `payroll.dhanman.com` / `qa.payroll.dhanman.com` |
| **dhanman-purchase** | 5005 | 5105 | `purchase.dhanman.com` / `qa.purchase.dhanman.com` |
| **dhanman-sales** | 5006 | 5106 | `sales.dhanman.com` / `qa.sales.dhanman.com` |

### Service Configuration

Each service runs as a systemd service with the following structure:

**Systemd Service File** (`/etc/systemd/system/dhanman-{service}-{env}.service`):

```ini
[Unit]
Description=Dhanman {Service} - {Environment}
After=network.target postgresql.service rabbitmq-server.service

[Service]
WorkingDirectory=/var/www/{env}/dhanman-{service}
ExecStart=/usr/bin/dotnet /var/www/{env}/dhanman-{service}/Dhanman.{Service}.dll --urls "http://localhost:{port}"
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=dhanman-{service}-{env}
User=www-data
Group=www-data

# Environment variables
Environment=ASPNETCORE_ENVIRONMENT={Environment}
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

# Logging
StandardOutput=append:/var/log/dhanman/{env}/{service}.log
StandardError=append:/var/log/dhanman/{env}/{service}.error.log

# Resource limits
LimitNOFILE=65536
MemoryMax=2G
CPUQuota=200%

[Install]
WantedBy=multi-user.target
```

### Folder Structure on Server

```
/var/www/
├── prod/
│   ├── dhanman-common/
│   │   ├── Dhanman.Common.dll
│   │   ├── appsettings.json
│   │   ├── appsettings.Production.json
│   │   └── logs/
│   ├── dhanman-sales/
│   ├── dhanman-purchase/
│   ├── dhanman-payroll/
│   ├── dhanman-community/
│   └── dhanman-inventory/
├── qa/
│   ├── dhanman-common/
│   ├── ... (same structure)
└── frontend/
    ├── prod/
    │   └── build/ (React static files)
    └── qa/
        └── build/
```

---

## NGINX Configuration

### Reverse Proxy Setup

**Main Configuration** (`/etc/nginx/sites-available/dhanman-prod`):

```nginx
# Upstream definitions for production services
upstream dhanman-common-prod {
    server localhost:5001;
    keepalive 32;
}

upstream dhanman-sales-prod {
    server localhost:5006;
    keepalive 32;
}

# SSL Configuration
server {
    listen 443 ssl http2;
    server_name common.dhanman.com;

    ssl_certificate /etc/letsencrypt/live/common.dhanman.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/common.dhanman.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Logging
    access_log /var/log/nginx/dhanman-common-prod-access.log;
    error_log /var/log/nginx/dhanman-common-prod-error.log;

    # Proxy settings
    location / {
        proxy_pass http://dhanman-common-prod;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
    }

    # Health check endpoint (no auth)
    location /health {
        proxy_pass http://dhanman-common-prod;
        access_log off;
    }

    # Hangfire dashboard (restricted)
    location /hangfire {
        proxy_pass http://dhanman-common-prod;
        # Add authentication if needed
        # auth_basic "Hangfire Dashboard";
        # auth_basic_user_file /etc/nginx/.htpasswd;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name common.dhanman.com;
    return 301 https://$server_name$request_uri;
}
```

### Frontend (SPA) Configuration

```nginx
server {
    listen 443 ssl http2;
    server_name app.dhanman.com;

    ssl_certificate /etc/letsencrypt/live/app.dhanman.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/app.dhanman.com/privkey.pem;

    root /var/www/frontend/prod/build;
    index index.html;

    # Caching for static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # SPA fallback (all routes to index.html)
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript 
               application/x-javascript application/xml+rss 
               application/javascript application/json;
}
```

---

## Database Configuration

### PostgreSQL Setup

**Server Configuration** (`/etc/postgresql/18/main/postgresql.conf`):

```ini
# Connection settings
max_connections = 200
shared_buffers = 4GB
effective_cache_size = 12GB
maintenance_work_mem = 1GB
work_mem = 16MB

# WAL settings
wal_level = replica
max_wal_size = 4GB
min_wal_size = 1GB
checkpoint_completion_target = 0.9

# Query tuning
random_page_cost = 1.1
effective_io_concurrency = 200

# Logging
logging_collector = on
log_directory = '/var/log/postgresql'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 100MB
log_min_duration_statement = 1000  # Log queries > 1s

# Autovacuum
autovacuum = on
autovacuum_max_workers = 4
autovacuum_naptime = 30s
```

### Database Per Service

Each microservice has its own database:

```sql
-- Production databases
CREATE DATABASE "prod-dhanman-common" OWNER dhanman_user;
CREATE DATABASE "prod-dhanman-sales" OWNER dhanman_user;
CREATE DATABASE "prod-dhanman-purchase" OWNER dhanman_user;
CREATE DATABASE "prod-dhanman-payroll" OWNER dhanman_user;
CREATE DATABASE "prod-dhanman-community" OWNER dhanman_user;
CREATE DATABASE "prod-dhanman-inventory" OWNER dhanman_user;

-- QA databases (similar structure)
CREATE DATABASE "qa-dhanman-common" OWNER dhanman_user;
-- ... etc
```

### Connection Pooling

**Application Configuration** (`appsettings.Production.json`):

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=prod-dhanman-sales;Username=dhanman_user;Password=***;Maximum Pool Size=100;Minimum Pool Size=10;Connection Idle Lifetime=300;Connection Pruning Interval=10"
  }
}
```

---

## CI/CD Pipeline

### GitHub Actions Workflow

**Production Deployment** (`.github/workflows/deploy-prod.yml`):

```yaml
name: Deploy to Production

on:
  workflow_dispatch:  # Manual trigger for production
  push:
    tags:
      - 'v*.*.*'

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '9.0.x'

      - name: Restore dependencies
        run: dotnet restore

      - name: Build
        run: dotnet build --configuration Release --no-restore

      - name: Run tests
        run: dotnet test --no-build --verbosity normal

      - name: Publish
        run: dotnet publish -c Release -o ./publish

      - name: Deploy to Production
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.PROD_HOST }}
          username: ${{ secrets.PROD_USER }}
          key: ${{ secrets.PROD_SSH_KEY }}
          script: |
            # Stop service
            sudo systemctl stop dhanman-sales-prod
            
            # Backup current version
            cd /var/www/prod
            sudo cp -r dhanman-sales dhanman-sales.backup.$(date +%Y%m%d_%H%M%S)
            
            # Deploy new version
            sudo rm -rf dhanman-sales/*
            
            # Copy files (handled by rsync in separate step)
            
            # Update configuration
            cd dhanman-sales
            sudo cp appsettings.Production.json.template appsettings.Production.json
            
            # Set permissions
            sudo chown -R www-data:www-data /var/www/prod/dhanman-sales
            
            # Start service
            sudo systemctl start dhanman-sales-prod
            sudo systemctl status dhanman-sales-prod
            
            # Health check
            sleep 10
            curl -f http://localhost:5006/health || exit 1
            
            echo "Deployment successful!"

      - name: Sync files via rsync
        run: |
          rsync -avz --delete ./publish/ ${{ secrets.PROD_USER }}@${{ secrets.PROD_HOST }}:/var/www/prod/dhanman-sales/

      - name: Notify deployment
        if: always()
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          text: 'Production deployment ${{ job.status }}'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### QA Auto-Deployment

```yaml
name: Deploy to QA

on:
  push:
    branches:
      - main

jobs:
  deploy-qa:
    runs-on: ubuntu-latest
    
    steps:
      # Similar steps as production
      # but automatically deploys on merge to main
      # and targets QA server (54.37.159.71)
```

---

## Scalability Strategies

### Vertical Scaling (Current)

**Current Server Specs:**
- **CPU**: 8 vCores
- **RAM**: 16 GB
- **Storage**: 400 GB SSD
- **Network**: 1 Gbps

**Upgrade Path:**
- Step 1: 16 vCores, 32 GB RAM
- Step 2: 24 vCores, 64 GB RAM
- Step 3: Consider horizontal scaling

### Horizontal Scaling (Future)

#### Load Balancing Architecture

```
                  ┌──────────────┐
                  │   NGINX      │
                  │ Load Balancer│
                  └───────┬──────┘
                          │
         ┌────────────────┼────────────────┐
         │                │                │
    ┌────▼────┐     ┌─────▼────┐     ┌────▼────┐
    │ Sales-1 │     │ Sales-2  │     │ Sales-3 │
    │ (5006)  │     │ (5007)   │     │ (5008)  │
    └─────────┘     └──────────┘     └─────────┘
```

**NGINX Load Balancing Config:**

```nginx
upstream dhanman-sales-cluster {
    least_conn;  # Load balancing method
    
    server sales-server-1:5006 weight=1 max_fails=3 fail_timeout=30s;
    server sales-server-2:5006 weight=1 max_fails=3 fail_timeout=30s;
    server sales-server-3:5006 weight=1 max_fails=3 fail_timeout=30s;
    
    keepalive 32;
}

server {
    listen 443 ssl http2;
    server_name sales.dhanman.com;
    
    location / {
        proxy_pass http://dhanman-sales-cluster;
        # ... other proxy settings
    }
}
```

#### Database Scaling

**Read Replicas:**

```
┌─────────────────┐
│  Primary (RW)   │
│  PostgreSQL     │
└────────┬────────┘
         │
         │ Replication
         │
    ┌────┴────┬────────┐
    │         │        │
┌───▼───┐ ┌───▼───┐ ┌──▼────┐
│Replica│ │Replica│ │Replica│
│ (RO)  │ │ (RO)  │ │ (RO)  │
└───────┘ └───────┘ └───────┘
```

**Connection String Strategy:**

```json
{
  "ConnectionStrings": {
    "WriteConnection": "Host=primary.db;Database=prod-dhanman-sales;...",
    "ReadConnection": "Host=replica1.db,replica2.db,replica3.db;Database=prod-dhanman-sales;Target Session Attributes=any;Load Balance Hosts=true;..."
  }
}
```

**EF Core Configuration:**

```csharp
services.AddDbContext<SalesDbContext>(options =>
{
    var connectionType = httpContext.Request.Method == "GET" ? "Read" : "Write";
    var connectionString = configuration.GetConnectionString($"{connectionType}Connection");
    options.UseNpgsql(connectionString);
});
```

#### Caching Layer (Planned)

```
┌───────────────────────────────────────┐
│           Redis Cluster               │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ │
│  │ Master  │ │ Master  │ │ Master  │ │
│  └────┬────┘ └────┬────┘ └────┬────┘ │
│       │           │           │      │
│  ┌────▼────┐ ┌────▼────┐ ┌────▼────┐ │
│  │ Replica │ │ Replica │ │ Replica │ │
│  └─────────┘ └─────────┘ └─────────┘ │
└───────────────────────────────────────┘
```

**Usage:**

```csharp
public class CachedCustomerRepository : ICustomerRepository
{
    private readonly IDistributedCache _cache;
    private readonly CustomerRepository _repository;

    public async Task<Customer?> GetByIdAsync(Guid id)
    {
        var cacheKey = $"customer:{id}";
        var cached = await _cache.GetStringAsync(cacheKey);
        
        if (cached != null)
            return JsonSerializer.Deserialize<Customer>(cached);

        var customer = await _repository.GetByIdAsync(id);
        
        if (customer != null)
        {
            await _cache.SetStringAsync(
                cacheKey,
                JsonSerializer.Serialize(customer),
                new DistributedCacheEntryOptions
                {
                    AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(15)
                }
            );
        }

        return customer;
    }
}
```

---

## Monitoring and Health Checks

### Application Health Endpoints

Each service exposes:
- `/health` - Basic liveness check
- `/health/ready` - Readiness check (DB, RabbitMQ, dependencies)
- `/health/startup` - Startup check

### Uptime Monitoring

**Uptime Kuma Configuration:**
- Check interval: 60 seconds
- Timeout: 10 seconds
- Retry: 3 times
- Notifications: Slack, Email

### Performance Metrics

**Grafana Dashboards:**
1. **System Metrics**
   - CPU usage per service
   - Memory usage
   - Disk I/O
   - Network throughput

2. **Application Metrics**
   - Request rate
   - Response time (p50, p95, p99)
   - Error rate
   - Active connections

3. **Database Metrics**
   - Query performance
   - Connection pool usage
   - Cache hit ratio
   - Lock waits

4. **Message Queue Metrics**
   - Message rate
   - Queue depth
   - Consumer lag
   - Dead-letter queue size

---

## Backup and Disaster Recovery

### Database Backups

**Automated Backup Script** (`/usr/local/bin/backup-dhanman-db.sh`):

```bash
#!/bin/bash

BACKUP_DIR="/backups/postgresql"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Backup each database
for db in prod-dhanman-common prod-dhanman-sales prod-dhanman-purchase \
          prod-dhanman-payroll prod-dhanman-community prod-dhanman-inventory; do
    
    echo "Backing up $db..."
    pg_dump -U dhanman_user -F c -b -v -f \
        "$BACKUP_DIR/${db}_${DATE}.backup" $db
    
    # Compress
    gzip "$BACKUP_DIR/${db}_${DATE}.backup"
    
    # Upload to Backblaze B2
    b2 upload-file dhanman-backups \
        "$BACKUP_DIR/${db}_${DATE}.backup.gz" \
        "postgresql/${db}_${DATE}.backup.gz"
done

# Clean old backups
find $BACKUP_DIR -name "*.backup.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup completed"
```

**Cron Schedule:**
```cron
# Daily backup at 2 AM
0 2 * * * /usr/local/bin/backup-dhanman-db.sh >> /var/log/backup.log 2>&1
```

### Recovery Procedures

**Full Database Restore:**

```bash
# Stop application
sudo systemctl stop dhanman-sales-prod

# Download backup from B2
b2 download-file-by-name dhanman-backups \
    "postgresql/prod-dhanman-sales_20240115_020000.backup.gz" \
    ./restore.backup.gz

# Decompress
gunzip restore.backup.gz

# Drop existing database
dropdb prod-dhanman-sales

# Create new database
createdb prod-dhanman-sales

# Restore
pg_restore -U dhanman_user -d prod-dhanman-sales -v restore.backup

# Start application
sudo systemctl start dhanman-sales-prod
```

---

## Security Considerations

### SSL/TLS Configuration

- Let's Encrypt certificates with auto-renewal
- TLS 1.2 and 1.3 only
- Strong cipher suites
- HSTS headers

### Firewall Rules

```bash
# Allow only necessary ports
sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH
sudo ufw allow 22/tcp

# HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# PostgreSQL (internal only)
sudo ufw allow from 10.0.0.0/8 to any port 5432

# RabbitMQ (internal only)
sudo ufw allow from 10.0.0.0/8 to any port 5672
sudo ufw allow from 10.0.0.0/8 to any port 15672

sudo ufw enable
```

### Secrets Management

Secrets stored in:
- GitHub Secrets (CI/CD)
- Environment variables (systemd service files)
- Encrypted configuration files

Never commit secrets to repository.

---

## Best Practices

### Do's ✅
- Use systemd for service management
- Implement health checks
- Monitor all services
- Automate backups
- Use SSL/TLS everywhere
- Implement rate limiting
- Log all operations
- Use connection pooling
- Implement graceful shutdown
- Version deployments

### Don'ts ❌
- Don't run services as root
- Don't skip health checks
- Don't ignore backup verification
- Don't deploy without testing
- Don't skip database migrations
- Don't ignore resource limits
- Don't deploy during peak hours
- Don't skip rollback plans

---

## Future Enhancements

- [ ] Kubernetes orchestration
- [ ] Multi-region deployment
- [ ] CDN for static assets
- [ ] Advanced caching strategy
- [ ] Auto-scaling based on metrics
- [ ] Blue-green deployments
- [ ] Canary deployments
- [ ] Service mesh (Istio/Linkerd)

---

## Summary

Dhanman's deployment architecture provides:
- **Reliability**: Systemd services with auto-restart
- **Scalability**: Ready for horizontal scaling
- **Security**: SSL/TLS, firewalls, secrets management
- **Observability**: Comprehensive monitoring and logging
- **Maintainability**: Automated CI/CD and backups
- **Performance**: Optimized database and proxy configuration

The architecture supports current needs while providing clear paths for future growth.
