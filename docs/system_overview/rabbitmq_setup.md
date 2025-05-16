# Dhanman RabbitMQ Setup (Prod + QA)

## 1. Prerequisites

* Ubuntu 21.10 / 22.04 VPS on OVH
* Docker and Docker Compose installed
* NGINX already running for other services
* Domain: dhanman.com

---

## 2. Docker RabbitMQ Containers Setup

### 2.1. Production RabbitMQ

```bash
docker run -d --hostname dhanman-rabbit-prod --name rabbitmq-prod \
  -p 5672:5672 -p 15672:15672 \
  rabbitmq:3-management
```

### 2.2. QA RabbitMQ

```bash
docker run -d --hostname dhanman-rabbit-qa --name rabbitmq-qa \
  -p 5673:5672 -p 15673:15672 \
  rabbitmq:3-management
```

---

## 3. Create Users

### 3.1. Production User

```bash
docker exec rabbitmq-prod rabbitmqctl add_user dhanman 'ProdStrongPassword'
docker exec rabbitmq-prod rabbitmqctl set_user_tags dhanman administrator
docker exec rabbitmq-prod rabbitmqctl set_permissions -p / dhanman ".*" ".*" ".*"
```

### 3.2. QA User

```bash
docker exec rabbitmq-qa rabbitmqctl add_user dhanman_qa 'QaStrongPassword'
docker exec rabbitmq-qa rabbitmqctl set_user_tags dhanman_qa administrator
docker exec rabbitmq-qa rabbitmqctl set_permissions -p / dhanman_qa ".*" ".*" ".*"
```

---

## 4. DNS Setup

| Host                    | Type | Value         |
| ----------------------- | ---- | ------------- |
| rabbitmq.dhanman.com    | A    | 51.79.156.217 |
| qa.rabbitmq.dhanman.com | A    | 51.79.156.217 |

---

## 5. NGINX Reverse Proxy Setup

### 5.1. Production NGINX Config

File: `/etc/nginx/sites-available/rabbitmq-prod.conf`

```nginx
server {
    server_name rabbitmq.dhanman.com;

    location / {
        proxy_pass http://127.0.0.1:15672/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 5.2. QA NGINX Config

File: `/etc/nginx/sites-available/rabbitmq-qa.conf`

```nginx
server {
    server_name qa.rabbitmq.dhanman.com;

    location / {
        proxy_pass http://127.0.0.1:15673/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 5.3. Enable Sites

```bash
sudo ln -s /etc/nginx/sites-available/rabbitmq-prod.conf /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/rabbitmq-qa.conf /etc/nginx/sites-enabled/
```

### 5.4. Test & Reload NGINX

```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 6. SSL Setup with Certbot

```bash
sudo apt install certbot python3-certbot-nginx -y
```

### 6.1. Production SSL

```bash
sudo certbot --nginx -d rabbitmq.dhanman.com
```

### 6.2. QA SSL

```bash
sudo certbot --nginx -d qa.rabbitmq.dhanman.com
```

---

## 7. Final Result

| URL                                                                | Environment | Ports                           |
| ------------------------------------------------------------------ | ----------- | ------------------------------- |
| [https://rabbitmq.dhanman.com](https://rabbitmq.dhanman.com)       | Production  | 5672 AMQP + 443 HTTPS (Mgmt UI) |
| [https://qa.rabbitmq.dhanman.com](https://qa.rabbitmq.dhanman.com) | QA          | 5673 AMQP + 443 HTTPS (Mgmt UI) |

---

## 8. Optional Security Enhancements

* Run `sudo ufw allow 'Nginx Full'`
* Add IP restrictions or basic auth for QA endpoint
* Add RabbitMQ Prometheus exporter for Grafana dashboards
