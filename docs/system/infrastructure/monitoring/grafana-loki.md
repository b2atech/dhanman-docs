#  Grafana + Loki Setup

- **Promtail** scrapes logs from:
  - /var/www/prod/logs
  - /var/www/qa/logs
- **Loki** stores data in /opt/logging/loki-data
- **Grafana** dashboards at https://logs.dhanman.com and https://qa.logs.dhanman.com
"@

New-MarkdownFile "system\infrastructure\monitoring\netdata.md" @"
#  Netdata Monitoring

- Installed via kickstart.sh on all VPS servers.
- Connected to Netdata Cloud Room: *Dhanman Infra*
- Tracks CPU, memory, disk I/O, PostgreSQL, NGINX, Docker metrics.
