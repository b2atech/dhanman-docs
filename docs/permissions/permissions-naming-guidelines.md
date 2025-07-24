
# 📜 Dhanman Permission Naming Guidelines

This document defines the standard naming convention for all permissions used across the Dhanman platform. Consistent naming improves readability, manageability, and security of permission-driven access control.

---

## 🧩 Naming Structure

Use the following pattern for every permission:

```
Dhanman.{Module}.{Entity}.{Action}[.SubAction]
```

### 🔹 Components

| Part        | Description                                                   | Example                        |
|-------------|---------------------------------------------------------------|--------------------------------|
| `Module`    | The bounded context or domain (e.g., `Sales`, `Purchase`)     | `Sales`, `Payroll`             |
| `Entity`    | The target resource (always in **singular** form)             | `Invoice`, `Bill`, `Customer` |
| `Action`    | The operation allowed on the entity (verb, in PascalCase)     | `Read`, `Write`, `Delete`     |
| `SubAction` | *(Optional)* for workflow-specific variations                 | `Approve.Level1`, `SendForApproval` |

---

## ✅ Examples

| Good Permission Name                              | Meaning                                                                 |
|---------------------------------------------------|-------------------------------------------------------------------------|
| `Dhanman.Sales.Invoice.Read`                      | Can view a single or multiple invoices                                 |
| `Dhanman.Purchase.Bill.Delete`                    | Can delete one or more bills                                           |
| `Dhanman.Payroll.Employee.Write`                 | Can create or update employee records                                  |
| `Dhanman.Sales.Invoice.Approve.Level2`           | Can approve an invoice at Level 2                                      |
| `Dhanman.MyHome.ResidentRequest.Approve`         | Can approve resident requests in MyHome module                         |

---

## 🚫 What to Avoid

| Bad Permission Name            | Why it's bad                                        | Suggested Fix                        |
|-------------------------------|-----------------------------------------------------|--------------------------------------|
| `Dhanman.Approve`             | Missing context — approve *what*?                   | `Dhanman.Sales.Invoice.Approve`      |
| `Dhanman.Write`               | Too broad and ambiguous                             | `Dhanman.Payroll.Employee.Write`     |
| `Dhanman.Sales.Approve`       | Vague — what in sales is being approved?            | `Dhanman.Sales.Invoice.Approve`      |
| `Dhanman.MyHome.Approve`      | Too generic — unclear which entity                  | `Dhanman.MyHome.ResidentRequest.Approve` |
| `Dhanman.Invoices.Delete`     | Entity should be singular                           | `Dhanman.Sales.Invoice.Delete`       |

---

## 🔐 Global Permissions

Global permissions grant access across **all modules and entities** for a specific action. These should be clearly distinguished using the following pattern:

```
Dhanman.Global.{Action}
```

### ✅ Examples

| Global Permission               | Meaning                                                   |
|--------------------------------|-----------------------------------------------------------|
| `Dhanman.Global.Read`          | Can read/view everything                                  |
| `Dhanman.Global.Write`         | Can write/update across all modules/entities              |
| `Dhanman.Global.Delete`        | Can delete any entity                                     |
| `Dhanman.Global.Approve`       | Can approve anything (across modules/workflows)           |

Use these **only for superusers or system administrators**.

---

## 📌 Best Practices

- ✅ Use **singular nouns** for entities
- ✅ Use **PascalCase** for each component
- ✅ Prefer **specific, scoped permissions** over vague/global ones
- ✅ Use `SubAction` only for meaningful variants like approval levels
- ✅ Use `Dhanman.Global.{Action}` for cross-module admin powers
- ✅ Enforce consistent entity names using a controlled ResourceType list

---

## 🧾 Canonical ResourceTypes

To maintain consistency, use only the following singular-form resource types:

### Common
- Company
- CompanyWarehouse
- CompanyPreference
- User
- Permission
- Organization
- Vendor
- Customer
- Ledger
- COA

### Purchase
- Bill
- Payment
- Note
- VendorWarehouse

### Sales
- Invoice
- Payment
- Note
- MyHomeInvoice

### MyHome
- Resident
- ResidentRequest
- Visitor
- Event
- ServiceProvider
- Building
- Unit
- Floor
- Gate
- Delivery
- Apartment

### Inventory
- Product

### Payroll
- Employee
- Leave
- Holiday
- Task
- Project
- PayrollComponent
- Payroll

### Developer
- Token
- Id

---

## 📎 Appendix

### Common Actions

| Action             | Description                                |
|--------------------|--------------------------------------------|
| `Read`             | View resource(s)                           |
| `Write`            | Create or update resource                  |
| `Delete`           | Remove resource                            |
| `Approve`          | Approve workflow item                      |
| `Reject`           | Reject workflow item                       |
| `SendForApproval`  | Submit for approval                        |
| `Copy`             | Clone an item                              |
| `Pay`              | Mark as paid                               |
| `Cancel`           | Cancel action or item                      |

---

> Keep your permissions clean, contextual, consistent, and scalable.
