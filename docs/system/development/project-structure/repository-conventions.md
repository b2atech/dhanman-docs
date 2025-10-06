#  Repository Conventions

- Each service: Dhanman.{Module}.Api
- Root folders: Application, Domain, Infrastructure
- Testing: Tests/{Module}.IntegrationTests
"@

# --- OPERATIONS ---
New-MarkdownFile "system\operations\deployment\production-deployment.md" @"
#  Production Deployment

1. SSH into production (51.79.156.217)
2. Pull latest images and restart containers:
   `ash
   docker compose pull && docker compose up -d
   `
3. NGINX reverse proxies with SSL via Let's Encrypt.
