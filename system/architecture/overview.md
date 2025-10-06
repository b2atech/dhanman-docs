# DhanMan Architecture

```plantuml
@startuml
!includeurl https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/v2.7.0/C4_Container.puml

SHOW_PERSON_OUTLINE()
' ✅ Ensures person icons (stick figures) are rendered
SHOW_PERSON_OUTLINE()

' Optional custom tags for better shapes/colors
AddElementTag("backend", $shape=EightSidedShape(), $bgColor="#4372C4")
AddElementTag("external", $shape=RoundedBoxShape(), $bgColor="#FDF6E3")
AddElementTag("infra", $shape=HexagonShape(), $bgColor="#B0BEC5")
AddElementTag("externalService", $bgColor="#FFD54F", $fontColor="#000", $borderColor="#FBC02D", $shape=RoundedBoxShape())
AddElementTag("infrastructure", $bgColor="#B0BEC5", $fontColor="#000", $shape=HexagonShape())
AddElementTag("database", $bgColor="#64B5F6", $fontColor="#000", $shape=DatabaseShape())



' 🧑 Actors
Person(user, "User", "Web user")
Person(admin, "Admin", "Admin with additional privileges")

System_Ext(auth0, "Auth0", "Authentication as a Service", $tags="externalService")
System_Ext(smtp, "Brevo / Zoho SMTP", "Transactional Email Provider", $tags="externalService")
System_Ext(sms, "SMS Gateway", "OTP/2FA and alerts via SMS", $tags="externalService")

' 🖥️ OVH VPS Boundary
System_Boundary(s1, "OVH VPS") {

    Container(nginx, "NGINX Reverse Proxy", "Nginx", "Routes traffic to backend services", $tags="infra")

    Container(spa, "Web App", "React, MUI", "Single Page Application running in browser", $tags="backend")

    Container_Boundary(services, "DhanMan Microservices") {
        Container(common, "Common Service", ".NET 9", "Authentication, Notifications", $tags="backend")
        Container(community, "Community Service", ".NET 9", "Apartment & resident data", $tags="backend")
        Container(purchase, "Purchase Service", ".NET 9", "Manages procurement", $tags="backend")
        Container(sales, "Sales Service", ".NET 9", "Handles invoicing and sales", $tags="backend")
        Container(inventory, "Inventory Service", ".NET 9", "Stock and item management", $tags="backend")
        Container(payroll, "Payroll Service", ".NET 9", "Salary and HRMS", $tags="backend")
        Container(documents, "Document Service", ".NET 9", "File upload/download using MinIO", $tags="backend")
    }

    ContainerDb(pgsql, "PostgreSQL", "Database per service", "Isolated DB per microservice",$tags="database")

    Container(minio, "MinIO", "S3-Compatible Object Store", "Stores PDFs, images, and documents", $tags="infra")

    Container(prometheus, "Prometheus + Grafana", "Monitoring", "Resource and service monitoring", $tags="infrastructure")
    Container(loki, "Loki + Promtail", "Central Logging", "Service log aggregation", $tags="infrastructure")
}

' 🔗 Relationships
Rel(user, spa, "Uses", "HTTPS")
Rel(admin, spa, "Manages", "HTTPS")
Rel(spa, nginx, "Routes API calls", "HTTPS")

Rel(nginx, common, "Routes to")
Rel(nginx, community, "Routes to")
Rel(nginx, purchase, "Routes to")
Rel(nginx, sales, "Routes to")
Rel(nginx, inventory, "Routes to")
Rel(nginx, payroll, "Routes to")
Rel(nginx, documents, "Routes to")

Rel(common, auth0, "Authenticate/Authorize via", "OAuth2")
Rel(common, smtp, "Sends Emails via", "SMTP")
Rel(common, sms, "Sends OTP/Alerts via", "HTTP API")

Rel(common, pgsql, "Reads/Writes")
Rel(community, pgsql, "Reads/Writes")
Rel(purchase, pgsql, "Reads/Writes")
Rel(sales, pgsql, "Reads/Writes")
Rel(inventory, pgsql, "Reads/Writes")
Rel(payroll, pgsql, "Reads/Writes")
Rel(documents, minio, "Stores/Retrieves files via", "S3 API")
Rel(documents, pgsql, "Reads/Writes metadata")

Rel(loki, services, "Tails Logs from", "Promtail")
Rel(prometheus, services, "Monitors Metrics from", "Node Exporter / Custom Exporters")

SHOW_LEGEND()
```
