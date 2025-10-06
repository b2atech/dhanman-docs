# Dhanman Deployment Setup Guide (QA and PROD)

This document outlines the **complete step-by-step deployment process** used to deploy Dhanman microservices to **DigitalOcean**, using **GitHub Actions**, **environment-specific secrets**, **NGINX**, and **SSL via Certbot**.

---

## 1. GitHub Environment Setup

### 1.1 Create Environments

- Go to your GitHub repository.
- Click on **Settings > Environments**.
- Create two environments:
  - `qa`
  - `prod`

### 1.2 Define Environment Secrets (per environment)

Go to **Settings > Environments > qa/prod > Add Secret**:

- `COMMUNITY_DB_CONNECTION` – Full PostgreSQL connection string
- `PERMISSIONS_DB_CONNECTION` – Full PostgreSQL connection string
- `DO_HOST` – Droplet IP or DNS
- `DO_USER` – Droplet SSH user (`root` or other)
- `DO_SSH_KEY` – Private SSH key content

---

## 2. GitHub Actions Workflow

### 2.1 QA Auto Deployment (triggered on merge to main)

Create the file `.github/workflows/deploy-qa.yml` with:

```yaml
name: Deploy to QA

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: qa

    env:
      ConnectionStrings__CommunityDb: ${{ secrets.COMMUNITY_DB_CONNECTION }}
      ConnectionStrings__PermissionsDb: ${{ secrets.PERMISSIONS_DB_CONNECTION }}
      DOTNET_ENVIRONMENT: qa

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Set up .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '8.0.x'

      - name: Publish App
        run: |
          dotnet publish src/Dhanman.MyHome.Api/Dhanman.MyHome.Api.csproj -c Release -r linux-x64 --self-contained false -o publish

      - name: Upload to QA Droplet
        uses: appleboy/scp-action@v0.1.4
        with:
          host: ${{ secrets.DO_HOST }}
          username: ${{ secrets.DO_USER }}
          key: ${{ secrets.DO_SSH_KEY }}
          source: "publish/*"
          target: "/var/www/qa/dhanman-community"

      - name: Restart QA App
        uses: appleboy/ssh-action@v0.1.10
        with:
          host: ${{ secrets.DO_HOST }}
          username: ${{ secrets.DO_USER }}
          key: ${{ secrets.DO_SSH_KEY }}
          script: |
            export ConnectionStrings__CommunityDb="${{ secrets.COMMUNITY_DB_CONNECTION }}"
            export ConnectionStrings__PermissionsDb="${{ secrets.PERMISSIONS_DB_CONNECTION }}"
            export DOTNET_ENVIRONMENT=qa
            sudo systemctl restart dhanman-community-qa
            sudo systemctl status dhanman-community-qa --no-pager
```

### 2.2 PROD Manual Deployment

Create the file `.github/workflows/deploy-prod.yml` with:

```yaml
name: Deploy to PROD

on:
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: prod

    env:
      ConnectionStrings__CommunityDb: ${{ secrets.COMMUNITY_DB_CONNECTION }}
      ConnectionStrings__PermissionsDb: ${{ secrets.PERMISSIONS_DB_CONNECTION }}
      DOTNET_ENVIRONMENT: production

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Set up .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '8.0.x'

      - name: Publish App
        run: |
          dotnet publish src/Dhanman.MyHome.Api/Dhanman.MyHome.Api.csproj -c Release -r linux-x64 --self-contained false -o publish

      - name: Upload to PROD Droplet
        uses: appleboy/scp-action@v0.1.4
        with:
          host: ${{ secrets.DO_HOST }}
          username: ${{ secrets.DO_USER }}
          key: ${{ secrets.DO_SSH_KEY }}
          source: "publish/*"
          target: "/var/www/prod/dhanman-community"

      - name: Restart PROD App
        uses: appleboy/ssh-action@v0.1.10
        with:
          host: ${{ secrets.DO_HOST }}
          username: ${{ secrets.DO_USER }}
          key: ${{ secrets.DO_SSH_KEY }}
          script: |
            export ConnectionStrings__CommunityDb="${{ secrets.COMMUNITY_DB_CONNECTION }}"
            export ConnectionStrings__PermissionsDb="${{ secrets.PERMISSIONS_DB_CONNECTION }}"
            export DOTNET_ENVIRONMENT=production
            sudo systemctl restart dhanman-community-prod
            sudo systemctl status dhanman-community-prod --no-pager
```
---

## 3. DigitalOcean Setup

### 3.1 SSH Key Generation
```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
cat ~/.ssh/id_rsa.pub
```

### 📁 3.2 Create Folder Structure and .env Files

> ✅ Run these **on your DigitalOcean droplet** via SSH

#### Step 1: Create QA & PROD Directories
```bash
sudo mkdir -p /var/www/qa/dhanman-community
sudo mkdir -p /var/www/prod/dhanman-community
```

#### Step 2: Add `.env` Files

##### QA (Linux):
```bash
echo "DOTNET_ENVIRONMENT=qa" | sudo tee /var/www/qa/dhanman-community/.env
sudo tee -a /var/www/qa/dhanman-community/.env > /dev/null <<EOL
ASPNETCORE_URLS=http://127.0.0.1:5205
ConnectionStrings__CommunityDb=<QA_COMMUNITY_DB_CONNECTION>
ConnectionStrings__PermissionsDb=<QA_PERMISSIONS_DB_CONNECTION>
EOL
```

##### QA (Windows PowerShell Equivalent):
```powershell
$envPath = "/var/www/qa/dhanman-community/.env"
$qaEnv = @"
DOTNET_ENVIRONMENT=qa
ASPNETCORE_URLS=http://127.0.0.1:5205
ConnectionStrings__CommunityDb=<QA_COMMUNITY_DB_CONNECTION>
ConnectionStrings__PermissionsDb=<QA_PERMISSIONS_DB_CONNECTION>
"@
ssh root@<droplet_ip> "echo '$qaEnv' > $envPath"
```

##### PROD (Linux):
```bash
echo "DOTNET_ENVIRONMENT=production" | sudo tee /var/www/prod/dhanman-community/.env
sudo tee -a /var/www/prod/dhanman-community/.env > /dev/null <<EOL
ASPNETCORE_URLS=http://127.0.0.1:5205
ConnectionStrings__CommunityDb=<PROD_COMMUNITY_DB_CONNECTION>
ConnectionStrings__PermissionsDb=<PROD_PERMISSIONS_DB_CONNECTION>
EOL
```

##### PROD (Windows PowerShell Equivalent):
```powershell
$envPath = "/var/www/prod/dhanman-community/.env"
$prodEnv = @"
DOTNET_ENVIRONMENT=production
ASPNETCORE_URLS=http://127.0.0.1:5205
ConnectionStrings__CommunityDb=<PROD_COMMUNITY_DB_CONNECTION>
ConnectionStrings__PermissionsDb=<PROD_PERMISSIONS_DB_CONNECTION>
"@
ssh root@<droplet_ip> "echo '$prodEnv' > $envPath"
```

---

### ⚙️ 3.3 Create `systemd` Services

> Run this **on your DigitalOcean droplet** via SSH

#### QA Service
```bash
sudo nano /etc/systemd/system/dhanman-community-qa.service
```

Paste:
```ini
[Unit]
Description=Dhanman Community QA Service
After=network.target

[Service]
WorkingDirectory=/var/www/qa/dhanman-community
ExecStart=/usr/bin/dotnet /var/www/qa/dhanman-community/Dhanman.MyHome.Api.dll
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=dhanman-community-qa
User=www-data
EnvironmentFile=/var/www/qa/dhanman-community/.env

[Install]
WantedBy=multi-user.target
```

#### PROD Service
```bash
sudo nano /etc/systemd/system/dhanman-community-prod.service
```

Repeat with path changes.

#### Enable & Start (Linux):
```bash
sudo systemctl daemon-reload
sudo systemctl enable dhanman-community-qa
sudo systemctl start dhanman-community-qa
sudo systemctl enable dhanman-community-prod
sudo systemctl start dhanman-community-prod
```

---

### 🌐 3.4 NGINX Reverse Proxy Setup

#### QA Subdomain Config (Linux)
```bash
sudo nano /etc/nginx/sites-available/qa.community.dhanman.com
```

Paste:
```nginx
server {
    listen 80;
    server_name qa.community.dhanman.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name qa.community.dhanman.com;

    ssl_certificate /etc/letsencrypt/live/qa.community.dhanman.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/qa.community.dhanman.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location / {
        proxy_pass http://127.0.0.1:5205;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

#### Enable & Test (Linux)
```bash
sudo ln -s /etc/nginx/sites-available/qa.community.dhanman.com /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

### 🔐 3.5 Certbot SSL

#### Install Certbot
```bash
sudo apt install certbot python3-certbot-nginx
```

#### Generate SSL
```bash
sudo certbot --nginx -d qa.community.dhanman.com
sudo certbot --nginx -d prod.community.dhanman.com
```

---

You're now set up to run multiple services in both QA and PROD environments with automated and manual GitHub deployments, process supervision via systemd, reverse proxy via NGINX, and SSL via Certbot.

---

## 🔧 Troubleshooting Commands & Tips

### 🔍 Check Systemd Service Logs
```bash
sudo systemctl status dhanman-community-qa.service
sudo journalctl -u dhanman-community-qa.service -n 50   # Last 50 logs
```

### 🚀 Restart or Enable Systemd Service
```bash
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl restart dhanman-community-qa.service
sudo systemctl enable dhanman-community-qa.service
```

### 🧪 Check NGINX Configuration & Reload
```bash
sudo nginx -t                       # Test config
sudo systemctl reload nginx        # Reload after changes
```

### 🌐 Test App on Localhost
```bash
curl http://127.0.0.1:<port>       # Example: curl http://127.0.0.1:5205
```

### 🔐 Check Environment Variables
```bash
echo $ConnectionStrings__CommunityDb
cat /proc/$(pgrep -f 'Dhanman.MyHome.Api')/environ | tr '\0' '\n' | grep ConnectionStrings
```

### 🔎 Check Which Port App is Running On
```bash
netstat -tuln | grep LISTEN
```

### 🔁 Check If NGINX is Listening to Domain
```bash
sudo nginx -T | grep server_name
```

### 📁 Remove Duplicate `server_name` Entries
Use `grep` to find duplicates:
```bash
grep -r "server_name" /etc/nginx/sites-available/
```
Manually remove extras from unused or backup config files.

### ❌ GitHub Push Blocked by Secrets
```bash
# Remove secrets from committed files
# OR use the GitHub UI to allow the secret push temporarily:
https://github.com/<org>/<repo>/security/secret-scanning/unblock-secret/
```

> Always ensure your `.env` file and secrets are not committed to GitHub!

---

✅ With these tools and steps, you can confidently manage QA and PROD environments hosted on DigitalOcean with secure, automated workflows.
