# B2A.DbTula CLI – DB Objects Extractor

This document provides ready-to-use commands for extracting **functions, procedures, views, triggers, and tables** from each service’s PostgreSQL database into its respective Persistence project folder.

---

## 🔹 Generic Command

```sh
B2A.DbTula.Cli --extract --extract-type postgres --extract-conn "Server=db.qa.dhanman.com;Port=5432;Database=<DB_NAME>;User Id=dhanmanqa;Password=<DB_PASSWORD>;" --objects functions,procedures,views,triggers,tables --outputDir "src/<ServiceName>.Persistence/DBObjects" --overwrite




1. Common Service

B2A.DbTula.Cli --extract --extract-type postgres --extract-conn "Server=db.qa.dhanman.com;Port=5432;Database=qa-dhanman-common;User Id=dhanmanqa;Password=<DB_PASSWORD>;" --objects functions,procedures,views,triggers,tables --outputDir "src/Dhanman.Common.Persistence/DBObjects" --overwrite


2. Community Service

B2A.DbTula.Cli --extract --extract-type postgres --extract-conn "Server=db.qa.dhanman.com;Port=5432;Database=qa-dhanman-community;User Id=dhanmanqa;Password=<DB_PASSWORD>;" --objects functions,procedures,views,triggers,tables --outputDir "src/Dhanman.Community.Persistence/DBObjects" --overwrite


3. Inventory Service

B2A.DbTula.Cli --extract --extract-type postgres --extract-conn "Server=db.qa.dhanman.com;Port=5432;Database=qa-dhanman-inventory;User Id=dhanmanqa;Password=<DB_PASSWORD>;" --objects functions,procedures,views,triggers,tables --outputDir "src/Dhanman.Inventory.Persistence/DBObjects" --overwrite



4. Payroll Service

B2A.DbTula.Cli --extract --extract-type postgres --extract-conn "Server=db.qa.dhanman.com;Port=5432;Database=qa-dhanman-payroll;User Id=dhanmanqa;Password=<DB_PASSWORD>;" --objects functions,procedures,views,triggers,tables --outputDir "src/Dhanman.Payroll.Persistence/DBObjects" --overwrite


5. Purchase Service

  B2A.DbTula.Cli --extract --extract-type postgres --extract-conn "Server=db.qa.dhanman.com;Port=5432;Database=qa-dhanman-purchase;User Id=dhanmanqa;Password=<DB_PASSWORD>;" --objects functions,procedures,views,triggers,tables --outputDir "src/Dhanman.Purchase.Persistence/DBObjects" --overwrite


6. Sales Service

 B2A.DbTula.Cli --extract --extract-type postgres --extract-conn "Server=db.qa.dhanman.com;Port=5432;Database=qa-dhanman-sales;User Id=dhanmanqa;Password=<DB_PASSWORD>;" --objects functions,procedures,views,triggers,tables --outputDir "src/Dhanman.Sales.Persistence/DBObjects" --overwrite

```
