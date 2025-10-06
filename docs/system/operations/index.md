# 🚀 Operations

This section provides **runbooks and operational guides** for deploying, monitoring, and maintaining the Dhanman system.

---

## 📘 Contents

### **Deployment**
- [QA Deployment Guide](deployment/qa_deployment_guide.md)
- [Production Deployment Guide](deployment/qa_prod_deployment_guide.md)
- [Database Dump & Restore](deployment/dump_restore_clean.md)

### **Monitoring**
- [Grafana Dashboards](monitoring/dashboards.md)

### **Runbooks**
- [QA Refresh Procedure](runbooks/qa-refresh-procedure.md)

---

## 🧠 Operational Notes

- Use **Ansible roles** for environment provisioning (`~/dhanman-infra/ansible`).
- Monitor uptime using **Uptime-Kuma**.
- Backup logs and data to **Backblaze B2** nightly.

---

📘 **Next Step:**  
Start with the [QA Deployment Guide](deployment/qa_deployment_guide.md).
