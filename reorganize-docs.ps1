# reorganize-docs.ps1
# 🧩 Reorganizes dhanman-docs repo into a single clean MkDocs-ready structure

Write-Host "🔹 Starting reorganization..." -ForegroundColor Cyan

# Ensure mkdocs.yml exists
if (-not (Test-Path "./mkdocs.yml")) {
    Write-Host "⚙️ Creating mkdocs.yml..."
    @"
site_name: Dhanman Documentation
repo_url: https://github.com/b2atech/dhanman-docs
theme:
  name: material
  features:
    - navigation.sections
    - navigation.tabs
    - content.code.copy
    - search.suggest
nav:
  - Product:
      - Overview: docs/product/getting-started/index.md
  - System:
      - Infrastructure: docs/system/infrastructure/overview/infra-service-map.md
      - Architecture: docs/system/architecture/overview/index.md
      - Development: docs/system/development/getting-started/index.md
      - Operations: docs/system/operations/deployment/qa_deployment_guide/index.md
"@ | Out-File -Encoding UTF8 "./mkdocs.yml"
}

# Cleanup old site builds
if (Test-Path "./site") {
    Write-Host "🧹 Cleaning old site folder..."
    Remove-Item -Recurse -Force "./site"
}

# Consolidate docs into clean root
Write-Host "📁 Consolidating docs..."
New-Item -ItemType Directory -Force "./docs" | Out-Null

# Move product docs
if (Test-Path "./docs/product") {
    Write-Host "📦 Moving product docs..."
    Move-Item -Force "./docs/product" "./docs/Product" -ErrorAction SilentlyContinue
}

# Move system docs
if (Test-Path "./docs/system") {
    Write-Host "📦 Moving system (tech) docs..."
    Move-Item -Force "./docs/system" "./docs/System" -ErrorAction SilentlyContinue
}

# Create top-level index
Write-Host "📝 Creating index.md..."
@"
# 🏗 Dhanman Documentation

Welcome to the **Dhanman Documentation Portal**.

## Sections
- [Product Documentation](Product/)
- [System & Technical Documentation](System/)

---
> Maintained by **B2A Technologies Pvt. Ltd.**
"@ | Out-File -Encoding UTF8 "./docs/index.md"

# Optional cleanup of redundant assets folders
if (Test-Path "./assets") {
    Write-Host "🧹 Moving global assets into docs/assets..."
    Move-Item -Force "./assets" "./docs/assets" -ErrorAction SilentlyContinue
}

Write-Host "✅ Reorganization complete."
Write-Host "You can now run: mkdocs serve"
