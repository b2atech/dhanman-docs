# B2A.DbTula CLI – DB Objects Extractor

This section provides ready-to-use, **single-line** commands to extract **functions, procedures, views, triggers, and tables** from each service’s PostgreSQL database into its respective Persistence project folder.

---

## 🔹 Generic Command

**Copy:**

```sh
B2A.DbTula.Cli --extract --extract-type postgres --extract-conn "Server=db.qa.dhanman.com;Port=5432;Database=<DB_NAME>;User Id=dhanmanqa;Password=<DB_PASSWORD>;" --objects functions,procedures,views,triggers,tables --outputDir "src/<ServiceName>.Persistence/DBObjects" --overwrite
```

---

## 🔹 Service-wise Commands (QA)

### 1) Common Service

**Copy:**

```sh
B2A.DbTula.Cli --extract --extract-type postgres --extract-conn "Server=db.qa.dhanman.com;Port=5432;Database=qa-dhanman-common;User Id=dhanmanqa;Password=<DB_PASSWORD>;" --objects functions,procedures,views,triggers,tables --outputDir "src/Dhanman.Common.Persistence/DBObjects" --overwrite
```

### 2) Community Service

**Copy:**

```sh
B2A.DbTula.Cli --extract --extract-type postgres --extract-conn "Server=db.qa.dhanman.com;Port=5432;Database=qa-dhanman-community;User Id=dhanmanqa;Password=<DB_PASSWORD>;" --objects functions,procedures,views,triggers,tables --outputDir "src/Dhanman.Community.Persistence/DBObjects" --overwrite
```

### 3) Inventory Service

**Copy:**

```sh
B2A.DbTula.Cli --extract --extract-type postgres --extract-conn "Server=db.qa.dhanman.com;Port=5432;Database=qa-dhanman-inventory;User Id=dhanmanqa;Password=<DB_PASSWORD>;" --objects functions,procedures,views,triggers,tables --outputDir "src/Dhanman.Inventory.Persistence/DBObjects" --overwrite
```

### 4) Payroll Service

**Copy:**

```sh
B2A.DbTula.Cli --extract --extract-type postgres --extract-conn "Server=db.qa.dhanman.com;Port=5432;Database=qa-dhanman-payroll;User Id=dhanmanqa;Password=<DB_PASSWORD>;" --objects functions,procedures,views,triggers,tables --outputDir "src/Dhanman.Payroll.Persistence/DBObjects" --overwrite
```

### 5) Purchase Service

**Copy:**

```sh
B2A.DbTula.Cli --extract --extract-type postgres --extract-conn "Server=db.qa.dhanman.com;Port=5432;Database=qa-dhanman-purchase;User Id=dhanmanqa;Password=<DB_PASSWORD>;" --objects functions,procedures,views,triggers,tables --outputDir "src/Dhanman.Purchase.Persistence/DBObjects" --overwrite
```

### 6) Sales Service

**Copy:**

```sh
B2A.DbTula.Cli --extract --extract-type postgres --extract-conn "Server=db.qa.dhanman.com;Port=5432;Database=qa-dhanman-sales;User Id=dhanmanqa;Password=<DB_PASSWORD>;" --objects functions,procedures,views,triggers,tables --outputDir "src/Dhanman.Sales.Persistence/DBObjects" --overwrite
```

### 7) Document Service

**Copy:**

```sh
B2A.DbTula.Cli --extract --extract-type postgres --extract-conn "Server=db.qa.dhanman.com;Port=5432;Database=qa-dhanman-document;User Id=dhanmanqa;Password=<DB_PASSWORD>;" --objects functions,procedures,views,triggers,tables --outputDir "src/Dhanman.Document.Persistence/DBObjects" --overwrite
```

---

## 💡 Notes

- Replace `<DB_PASSWORD>` with the actual QA password.
- All commands are **single line** and **copy-ready** (GitHub will show a copy icon per block).
- Output target: `src/<ServiceName>.Persistence/DBObjects`.
- For Prod, change server/port/db to your Prod connection values and adjust `<ServiceName>` if needed.
