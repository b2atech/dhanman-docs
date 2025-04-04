
# ✅ QA Deployment Setup for Dhanman Microservices (QA Environment)

This guide walks through the complete setup to deploy and serve multiple .NET microservices in the QA environment using systemd, NGINX, and HTTPS via Let's Encrypt.

---

## 📦 1. Build and Publish the .NET App

Use the following command to publish your app for Linux:

```bash
dotnet publish -c Release -r linux-x64 --self-contained false -o ./publish
```

- `-r linux-x64`: Targets Linux 64-bit
- `--self-contained false`: Uses framework-dependent deployment
- `-o ./publish`: Output folder

---

## 📁 2. Create Folder and Deploy to Server

### Create folder on the droplet:

```bash
sudo mkdir -p /var/www/qa/<service-folder>
```

### Upload files from local:

```bash
scp -r ./publish/* root@<droplet-ip>:/var/www/qa/<service-folder>
```

Replace `<service-folder>` with the service name, e.g., `dhanman-common`.

---

## ⚙️ 3. Create systemd Service

### Create service file:

```bash
sudo nano /etc/systemd/system/<service-name>-qa.service
```

### Paste this content:

```ini
[Unit]
Description=<Service Name> - QA
After=network.target

[Service]
WorkingDirectory=/var/www/qa/<service-folder>
ExecStart=/usr/bin/dotnet /var/www/qa/<service-folder>/<ServiceDll>.dll --urls "http://localhost:<port>"
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=<service-name>-qa
User=root
Environment=ASPNETCORE_ENVIRONMENT=QA

[Install]
WantedBy=multi-user.target
```

### Reload and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable <service-name>-qa
sudo systemctl start <service-name>-qa
sudo systemctl status <service-name>-qa
```

---

## 🌐 4. Configure NGINX Reverse Proxy

### Create NGINX config:

```bash
sudo nano /etc/nginx/sites-available/<service-name>
```

### Paste:

```nginx
server {
    listen 80;
    server_name <subdomain>.dhanman.com;

    location / {
        proxy_pass http://localhost:<port>;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### Enable and reload:

```bash
sudo ln -s /etc/nginx/sites-available/<service-name> /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🔐 5. Setup HTTPS with Certbot

Ensure the DNS record for `<subdomain>.dhanman.com` points to your droplet.

### Run Certbot:

```bash
sudo certbot --nginx -d <subdomain>.dhanman.com
```

Choose:
```
2: Redirect - Make all requests redirect to secure HTTPS
```

Certbot will:
- Add the HTTPS block
- Enable HTTP/2
- Set up auto-renewal

---

## 🧪 6. Verify Deployment

- ✅ Visit: `https://<subdomain>.dhanman.com`
- 🔒 Confirm HTTPS lock
- 🌀 Test auto-renew:

```bash
sudo certbot renew --dry-run
```

---

## 🔁 7. Repeat for Each Service

| Service Name       | Port  | Folder                     | Subdomain                     | systemd Service File           |
|--------------------|-------|----------------------------|--------------------------------|--------------------------------|
| dhanman-common     | 5101  | /var/www/qa/dhanman-common | qa.common.dhanman.com         | dhanman-common-qa.service      |
| dhanman-sales      | 5100  | /var/www/qa/dhanman-sales  | qa.sales.dhanman.com          | dhanman-sales-qa.service       |
| dhanman-payroll    | 5102  | /var/www/qa/dhanman-payroll| qa.payroll.dhanman.com        | dhanman-payroll-qa.service     |
| ...                | ...   | ...                        | ...                            | ...                            |

Repeat all above steps for each service with its own:
- Folder
- Port
- Subdomain
- systemd and NGINX config

---

---

## 🔢 8. Port Mapping by Environment

Here’s a reference table to manage ports across **Dev**, **QA**, and **Prod** environments:

| Service Name       | Dev Port | QA Port | Prod Port |
|--------------------|----------|---------|-----------|
| dhanman-common     | 5001     | 5101    | 5201      |
| dhanman-sales      | 5000     | 5100    | 5200      |
| dhanman-payroll    | 5002     | 5102    | 5202      |
| dhanman-purchase   | 5003     | 5103    | 5203      |
| dhanman-inventory  | 5004     | 5104    | 5204      |
| dhanman-myhome     | 5005     | 5105    | 5205      |

Make sure to update `--urls` in systemd and `proxy_pass` in NGINX accordingly for each environment.

---
