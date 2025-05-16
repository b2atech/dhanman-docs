# Dhanman MinIO Production + QA Setup Documentation

This document provides the complete setup process for running dual MinIO instances (Production + QA) on a single VPS server for Dhanman.

---

## ✅ Prerequisites

* Ubuntu 22.04 VPS (OVH or similar)
* Domain names: `files.dhanman.com`, `qa.files.dhanman.com`
* Public server IP: `51.79.156.217`
* Ubuntu user with `sudo` rights

---

## ✅ Step 1: Prepare folders

```bash
sudo mkdir -p /opt/minio
sudo mkdir -p /opt/minio-data-prod
sudo mkdir -p /opt/minio-data-qa
sudo chown -R ubuntu:ubuntu /opt/minio-data-prod
sudo chown -R ubuntu:ubuntu /opt/minio-data-qa
```

---

## ✅ Step 2: Download MinIO

```bash
cd /opt/minio
wget https://dl.min.io/server/minio/release/linux-amd64/minio
chmod +x minio
```

---

## ✅ Step 3: Create MinIO systemd services

### 🎯 minio-prod.service

```bash
sudo nano /etc/systemd/system/minio-prod.service
```

Content:

```ini
[Unit]
Description=MinIO Production Instance
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/opt/minio/minio server /opt/minio-data-prod --console-address ":9001"
Environment="MINIO_ROOT_USER=prodadmin"
Environment="MINIO_ROOT_PASSWORD=YourProdStrongPassword"
User=ubuntu
Group=ubuntu
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

### 🎯 minio-qa.service

```bash
sudo nano /etc/systemd/system/minio-qa.service
```

Content:

```ini
[Unit]
Description=MinIO QA Instance
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/opt/minio/minio server /opt/minio-data-qa --console-address ":9003"
Environment="MINIO_ROOT_USER=qaadmin"
Environment="MINIO_ROOT_PASSWORD=YourQaStrongPassword"
User=ubuntu
Group=ubuntu
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

---

## ✅ Step 4: Enable and start services

```bash
sudo systemctl daemon-reload
sudo systemctl enable minio-prod
sudo systemctl enable minio-qa
sudo systemctl start minio-prod
sudo systemctl start minio-qa
```

Check:

```bash
sudo systemctl status minio-prod
sudo systemctl status minio-qa
```

---

## ✅ Step 5: Setup DNS

In DNS panel:

```
A record → files.dhanman.com → 51.79.156.217
A record → qa.files.dhanman.com → 51.79.156.217
```

---

## ✅ Step 6: Install NGINX + Certbot

```bash
sudo apt update
sudo apt install nginx certbot python3-certbot-nginx -y
```

---

## ✅ Step 7: NGINX reverse proxy configuration

### 🎯 Production

```bash
sudo nano /etc/nginx/sites-available/files.dhanman.com
```

```nginx
server {
    listen 80;
    server_name files.dhanman.com;

    location / {
        proxy_pass http://127.0.0.1:9001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        client_max_body_size 100M;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/files.dhanman.com /etc/nginx/sites-enabled/
```

### 🎯 QA

```bash
sudo nano /etc/nginx/sites-available/qa.files.dhanman.com
```

```nginx
server {
    listen 80;
    server_name qa.files.dhanman.com;

    location / {
        proxy_pass http://127.0.0.1:9003;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        client_max_body_size 100M;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/qa.files.dhanman.com /etc/nginx/sites-enabled/
```

Reload NGINX:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## ✅ Step 8: SSL Certificates

```bash
sudo certbot --nginx -d files.dhanman.com -d qa.files.dhanman.com
```

Check auto-renewal:

```bash
sudo systemctl status certbot.timer
```

---

## ✅ Final Result

| Subdomain            | Port | Instance         |
| -------------------- | ---- | ---------------- |
| files.dhanman.com    | 9001 | Production MinIO |
| qa.files.dhanman.com | 9003 | QA MinIO         |

---

This completes the full MinIO dual-instance infrastructure for Dhanman.
