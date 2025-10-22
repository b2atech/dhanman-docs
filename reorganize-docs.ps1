# 🧹 Reorganize-Docs.ps1
# Purpose: Create clean, domain-based structure for end-user Dhanman documentation.
# It creates missing folders and .md files with "TBD" placeholders, and updates mkdocs.yml navigation.

$docsRoot = "C:\Users\bhara\source\repos\dhanman-docs\docs"
$mkdocsFile = "C:\Users\bhara\source\repos\dhanman-docs\mkdocs.yml"

Write-Host "📘 Starting Dhanman Docs Restructure..." -ForegroundColor Cyan

# ----------------------------
# 1️⃣ Define documentation modules and their pages
# ----------------------------
$navStructure = @{
    "Dashboard" = @("overview", "trends", "comparative-analysis", "yearly-comparison")
    "Organization" = @("company-setup", "branches", "locations", "users-and-roles", "permissions", "audit-logs")
    "My Community" = @(
        "buildings", "units", "residents", "member-requests", "service-providers", "visitors",
        "tickets", "committee-members", "resident-vehicles", "water-tanker-entry", "calendar"
    )
    "Account" = @(
        "chart-of-accounts", "general-ledger", "manual-journal",
        "trial-balance", "profit-loss", "balance-sheet", "cash-flow"
    )
    "Financial Management" = @(
        "ledger-reports", "customer-ledger", "vendor-ledger", "accounts-ledger",
        "customer-dues", "vendor-dues", "budget", "party-summary", "bank-statements"
    )
    "Payments" = @(
        "payments-made", "payments-received", "advance-payment", "tds-payments",
        "bank-transfers", "fixed-deposits"
    )
    "Income" = @(
        "service-invoices", "grouped-invoices", "customer-notes", "recurring-invoices",
        "customers", "customer-products", "customer-warehouses",
        "invoice-templates", "customer-account-config"
    )
    "Expense" = @(
        "expense-bills", "vendor-dues", "vendor-notes", "recurring-bills",
        "vendors", "vendor-products", "vendor-warehouses", "tds-list", "vendor-account-config"
    )
    "Payroll and HR" = @(
        "users-and-roles", "employees", "monthly-payroll",
        "holiday-calendar", "leave-requests"
    )
    "Inventory Management" = @(
        "items", "warehouses", "stock-adjustments", "transfers", "stock-alerts"
    )
    "Bulk Tools" = @(
        "import-bill-payments", "import-invoice-payments", "import-grouped-invoices",
        "import-bills-records", "import-invoices", "import-bank-statement",
        "import-invoice-template", "import-manual-journal"
    )
    "Reports" = @(
        "overview", "profit-loss", "balance-sheet", "trial-balance",
        "cash-flow-statement", "accounts-receivable-aging",
        "accounts-payable-aging", "pending-dues", "custom-reports"
    )
    "Project Management" = @("projects", "tasks", "time-tracking", "approvals")
    "Integrations" = @("payment-gateway", "email-sms", "accounting-exports", "api-access")
    "Mobile App" = @("overview", "notifications", "offline-access", "shortcuts")
}

# ----------------------------
# 2️⃣ Create folders and placeholder .md files
# ----------------------------
foreach ($module in $navStructure.Keys) {
    $folderName = ($module -replace " ", "-").ToLower()
    $folderPath = Join-Path $docsRoot $folderName

    if (-not (Test-Path $folderPath)) {
        Write-Host "📁 Creating folder: $folderPath"
        New-Item -ItemType Directory -Force -Path $folderPath | Out-Null
    }

    foreach ($page in $navStructure[$module]) {
        $filePath = Join-Path $folderPath "$page.md"

        if (-not (Test-Path $filePath)) {
            Write-Host "📝 Creating: $filePath"
            "## $($page -replace '-', ' ')`n`nTBD" | Out-File $filePath -Encoding utf8
        } else {
            Write-Host "✅ Exists: $filePath" -ForegroundColor DarkGray
        }
    }
}

# ----------------------------
# 3️⃣ Generate mkdocs.yml navigation
# ----------------------------
Write-Host "`n🧭 Generating mkdocs.yml navigation..."

$navContent = "nav:`n"
foreach ($module in $navStructure.Keys) {
    $folderName = ($module -replace " ", "-").ToLower()
    $navContent += "  - ${module}:`n"
    foreach ($page in $navStructure[$module]) {
        $title = ($page -replace '-', ' ') -replace '\b\w', { $_.Value.ToUpper() }
        $navContent += "      - ${title}: ${folderName}/${page}.md`n"
    }
}

Set-Content -Path $mkdocsFile -Value $navContent -Encoding utf8
Write-Host "`n✅ Navigation updated in mkdocs.yml"
Write-Host "✨ Documentation structure setup completed successfully!"
