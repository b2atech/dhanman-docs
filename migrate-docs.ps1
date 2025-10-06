<#
    Dhanman Docs Migration Script (v2.2 - Windows Safe)
    Compatible with: Windows PowerShell 5.1+
    Purpose: Move old scattered documentation into the new MkDocs structure.
#>

Write-Host "Starting Dhanman Docs Migration..." -ForegroundColor Cyan

# -----------------------
# DEFINE TARGET PATHS
# -----------------------
$root = Get-Location
$docsRoot = Join-Path $root "docs"

$productTarget = Join-Path $docsRoot "product"
$systemTarget  = Join-Path $docsRoot "system"

# -----------------------
# ENSURE MAIN DIRECTORIES
# -----------------------
$paths = @($productTarget, $systemTarget)
foreach ($p in $paths) {
    if (-not (Test-Path $p)) {
        New-Item -ItemType Directory -Path $p -Force | Out-Null
        Write-Host "Created: $p" -ForegroundColor Green
    } else {
        Write-Host "Exists: $p" -ForegroundColor Gray
    }
}

# -----------------------
# MIGRATION MAP
# -----------------------
$migrationMap = @{
    "coding_conventions" = "system/development/standards"
    "devops"             = "system/operations/deployment"
    "financial_reports"  = "product/financial-management"
    "permissions"        = "system/security"
    "policies"           = "system/security"
    "system_overview"    = "system/architecture"
    "accounting_entries" = "product/financial-management"
    "accounting"         = "product/financial-management"
    "how-to"             = "system/development"
    "dbtula"             = "system/development/api-internal"
    "payroll"            = "product/payroll"
}

# -----------------------
# MOVE FILES
# -----------------------
foreach ($source in $migrationMap.Keys) {
    $target = Join-Path $docsRoot $migrationMap[$source]

    if (Test-Path $source) {
        if (-not (Test-Path $target)) {
            New-Item -ItemType Directory -Path $target -Force | Out-Null
        }

        Write-Host "Moving $source -> $target" -ForegroundColor Yellow
        Get-ChildItem -Path $source -Recurse -File | ForEach-Object {
            Move-Item -Path $_.FullName -Destination $target -Force
        }

        if ((Get-ChildItem -Path $source -Recurse | Measure-Object).Count -eq 0) {
            Remove-Item -Path $source -Force -Recurse
            Write-Host "Removed empty folder: $source" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "Skipped missing: $source" -ForegroundColor DarkYellow
    }
}

# -----------------------
# POST CLEANUP
# -----------------------
Write-Host "`nCleaning up leftover empty folders..." -ForegroundColor Cyan
$folders = Get-ChildItem -Recurse -Directory

foreach ($f in $folders) {
    if ((Get-ChildItem -Path $f.FullName -Recurse | Measure-Object).Count -eq 0) {
        Remove-Item -Path $f.FullName -Recurse -Force
        Write-Host "Removed empty: $($f.FullName)" -ForegroundColor Gray
    }
}

Write-Host "`nMigration complete! All files are now under docs/product and docs/system." -ForegroundColor Green
