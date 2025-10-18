#!/bin/bash
# =====================================================================
# B2A Technologies Pvt Ltd – Dhanman Disaster Recovery Extended Audit
# =====================================================================
# Collects key infra configs, compresses them, and uploads to Backblaze B2
# via rclone (remote name: backblaze:dhanman-dr-snapshots)
# ---------------------------------------------------------------------

set -euo pipefail
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTDIR="$HOME/dr-audit-$TIMESTAMP"
LATEST_LINK="$HOME/dr-audit-latest"
SUMMARY_FILE="$OUTDIR/SUMMARY.txt"

mkdir -p "$OUTDIR"
echo "🔹 Saving extended audit results to $OUTDIR"

# ---------------------------------------------------------------------
# 1. Basic System Info
# ---------------------------------------------------------------------
lsb_release -a > "$OUTDIR/os-release.txt" 2>&1 || true
uname -a > "$OUTDIR/kernel.txt" 2>&1
hostnamectl > "$OUTDIR/hostname.txt" 2>&1

# ---------------------------------------------------------------------
# 2. Installed Packages
# ---------------------------------------------------------------------
dpkg --get-selections | grep -v deinstall > "$OUTDIR/installed-packages.txt" 2>&1

# ---------------------------------------------------------------------
# 3. Enabled & Running Services
# ---------------------------------------------------------------------
systemctl list-unit-files --type=service | grep enabled > "$OUTDIR/enabled-services.txt"
systemctl list-units --type=service --state=running > "$OUTDIR/running-services.txt"

# ---------------------------------------------------------------------
# 4. NGINX Configuration
# ---------------------------------------------------------------------
if command -v nginx >/dev/null 2>&1; then
  mkdir -p "$OUTDIR/nginx"
  cp -r /etc/nginx/sites-available "$OUTDIR/nginx/" 2>/dev/null || true
  cp -r /etc/nginx/sites-enabled "$OUTDIR/nginx/" 2>/dev/null || true
  nginx -T > "$OUTDIR/nginx/full-config-dump.txt" 2>&1 || true
fi

# ---------------------------------------------------------------------
# 5. PostgreSQL Configuration & Databases
# ---------------------------------------------------------------------
if command -v psql >/dev/null 2>&1; then
  mkdir -p "$OUTDIR/postgres"
  sudo -u postgres psql -c "\l" > "$OUTDIR/postgres/databases.txt" 2>&1 || true
  sudo -u postgres psql -c "SHOW config_file;" > "$OUTDIR/postgres/config-path.txt" 2>&1 || true
  cp /etc/postgresql/*/main/postgresql.conf "$OUTDIR/postgres/" 2>/dev/null || true
  psql --version > "$OUTDIR/postgres/version.txt" 2>&1 || true
fi

# ---------------------------------------------------------------------
# 6. Docker Information
# ---------------------------------------------------------------------
if command -v docker >/dev/null 2>&1; then
  mkdir -p "$OUTDIR/docker"
  docker ps -a > "$OUTDIR/docker/containers.txt" 2>&1 || true
  docker images > "$OUTDIR/docker/images.txt" 2>&1 || true
  docker network ls > "$OUTDIR/docker/networks.txt" 2>&1 || true
  docker volume ls > "$OUTDIR/docker/volumes.txt" 2>&1 || true
  docker inspect $(docker ps -aq) > "$OUTDIR/docker/inspect.json" 2>/dev/null || true
fi

# ---------------------------------------------------------------------
# 7. Prometheus, Exporters & Monitoring Configs
# ---------------------------------------------------------------------
mkdir -p "$OUTDIR/prometheus" "$OUTDIR/postgres_exporter"
cp -r /etc/prometheus/* "$OUTDIR/prometheus/" 2>/dev/null || true
cp -r /etc/postgres_exporter/* "$OUTDIR/postgres_exporter/" 2>/dev/null || true

# ---------------------------------------------------------------------
# 8. Grafana & Loki Stack
# ---------------------------------------------------------------------
mkdir -p "$OUTDIR/grafana" "$OUTDIR/loki-stack"
cp -r /etc/grafana/* "$OUTDIR/grafana/" 2>/dev/null || true
cp -r /home/ubuntu/loki-stack/* "$OUTDIR/loki-stack/" 2>/dev/null || true

# ---------------------------------------------------------------------
# 9. Systemd & Custom Scripts
# ---------------------------------------------------------------------
mkdir -p "$OUTDIR/systemd" "$OUTDIR/opt-scripts"
cp -r /etc/systemd/system/* "$OUTDIR/systemd/" 2>/dev/null || true
cp -r /opt/scripts/* "$OUTDIR/opt-scripts/" 2>/dev/null || true

# ---------------------------------------------------------------------
# 10. Cron Jobs & SSL Certificates
# ---------------------------------------------------------------------
crontab -l > "$OUTDIR/crontab-root.txt" 2>&1 || true
sudo ls /etc/cron.d/ > "$OUTDIR/cron.d-list.txt" 2>&1 || true
if command -v certbot >/dev/null 2>&1; then
  sudo certbot certificates > "$OUTDIR/certbot-certs.txt" 2>&1 || true
fi

# ---------------------------------------------------------------------
# 11. System Users, Network, and Disk
# ---------------------------------------------------------------------
cut -d: -f1 /etc/passwd > "$OUTDIR/users.txt"
ss -tulnp > "$OUTDIR/listening-ports.txt" 2>&1 || true
df -h > "$OUTDIR/disk-usage.txt" 2>&1

# ---------------------------------------------------------------------
# 12. App Directories
# ---------------------------------------------------------------------
ls -l /var/www > "$OUTDIR/var-www.txt" 2>&1 || true
ls -l /var/www/prod > "$OUTDIR/var-www-prod.txt" 2>&1 || true
ls -l /var/www/qa > "$OUTDIR/var-www-qa.txt" 2>&1 || true

# ---------------------------------------------------------------------
# 13. Summary Manifest
# ---------------------------------------------------------------------
{
  echo "📦 Dhanman Infra Snapshot Summary"
  echo "----------------------------------"
  echo "Host: $(hostname)"
  echo "Date: $(date)"
  echo "Archive: $OUTDIR.tar.gz"
  echo "NGINX: $(nginx -v 2>&1 || echo 'Not installed')"
  echo "PostgreSQL: $(psql --version 2>&1 || echo 'Not installed')"
  echo "Prometheus config: $(ls /etc/prometheus/prometheus.yml 2>/dev/null || echo 'N/A')"
  echo "Grafana config: $(ls /etc/grafana/grafana.ini 2>/dev/null || echo 'N/A')"
  echo "Exporter config: $(ls /etc/postgres_exporter/queries_pg_stat_statements.yaml 2>/dev/null || echo 'N/A')"
  echo ""
  echo "Included directories:"
  echo "  - /etc/nginx/"
  echo "  - /etc/postgresql/"
  echo "  - /etc/prometheus/"
  echo "  - /etc/postgres_exporter/"
  echo "  - /etc/grafana/"
  echo "  - /home/ubuntu/loki-stack/"
  echo "  - /etc/systemd/system/"
  echo "  - /opt/scripts/"
} > "$SUMMARY_FILE"

# ---------------------------------------------------------------------
# 14. Compress Everything
# ---------------------------------------------------------------------
tar -czf "$OUTDIR.tar.gz" -C "$(dirname "$OUTDIR")" "$(basename "$OUTDIR")"
ln -sfn "$OUTDIR" "$LATEST_LINK"

# ---------------------------------------------------------------------
# 15. Upload Snapshot to Backblaze via rclone
# ---------------------------------------------------------------------
if command -v rclone >/dev/null 2>&1; then
  if rclone copy "$OUTDIR.tar.gz" backblaze:dhanman-dr-snapshots; then
    echo "☁️  Uploaded snapshot successfully" | tee -a "$SUMMARY_FILE"
  else
    echo "⚠️  Upload failed, check rclone configuration" | tee -a "$SUMMARY_FILE"
  fi
else
  echo "⚠️ rclone not found, skipping upload" | tee -a "$SUMMARY_FILE"
fi

# ---------------------------------------------------------------------
# 16. Local Retention (cleanup older than 7 days)
# ---------------------------------------------------------------------
find "$HOME" -maxdepth 1 -type d -name "dr-audit-20*" -mtime +7 -exec rm -rf {} \;
find "$HOME" -maxdepth 1 -type f -name "dr-audit-20*.tar.gz" -mtime +7 -exec rm -f {} \;

echo "🧹 Cleaned old snapshots" | tee -a "$SUMMARY_FILE"
echo "✅ Audit complete → $OUTDIR.tar.gz"
