# 🔒 Security

This section outlines **security practices, authentication mechanisms, and secrets management** for the Dhanman system.

---

## 📘 Contents

### **Authentication & Authorization**
- [Authentication Flow](authentication-flow.md)
- [Common Security Concepts](common.md)

### **Permissions**
- [Naming Guidelines](permissions-naming-guidelines.md)
- [Sales Module Permissions](sales.md)

### **Secrets Management**
- [Managing Secrets](secrets-management.md)

### **Policies**
- [Office Etiquette Policy](office_etiquette_policy.md)

---

## 🧰 Security Highlights

| Area | Technology |
|------|-------------|
| **Authentication** | Auth0 with PostgreSQL integration |
| **2FA** | SMS-based OTP |
| **Encryption** | TLS (Certbot-managed SSL) |
| **Secrets** | `.env` files and Ansible Vault |

---

📘 **Next Step:**  
Read the [Authentication Flow](authentication-flow.md) or review [Secrets Management](secrets-management.md).
