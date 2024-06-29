# Permissions Structure

## Address Permissions
- ### Address.Read
    - `Address.Read.Countries`
    - `Address.Read.States`
    - `Address.Read.Cities`

## Customer Note Permissions
- ### CustomerNote.Read
    - `CustomerNote.Read.CustomerNotes`
- ### CustomerNote.Write
    - `CustomerNote.Write.CustomerNote`
    - `CustomerNote.Write.CustomerNoteNextStatus`
    - `CustomerNote.Write.CustomerNotePreviousStatus`

## Customers Permissions
- ### Customers.Read
    - `Customers.Read.CustomerNames`
    - `Customers.Read.Customers`
    - `Customers.Read.Customer`
    - `Customers.Read.AddressByCustomerId`
- ### Customers.Write
    - `Customers.Write.Customer`
    - `Customers.Write.Customer`

## Git Permissions
- ### Git.Read
    - `Git.Read.GetAllPRs`

## Invoices Permissions
- ### Invoices.Read
    - `Invoices.Read.Invoice`
    - `Invoices.Read.Invoices`
    - `Invoices.Read.InvoiceStatus`
    - `Invoices.Read.InvoiceDetail`
    - `Invoices.Read.InvoiceHeaders`
    - `Invoices.Read.InvoiceHeader`
    - `Invoices.Read.InvoiceHeaderByCustomerId`
    - `Invoices.Read.PaidInvoiceSummary`
    - `Invoices.Read.UnpaidInvoiceSummary`
    - `Invoices.Read.OverdueInvoiceSummary`
    - `Invoices.Read.TotalAmount`
    - `Invoices.Read.InvoiceTotalAmount`
    - `Invoices.Read.InvoiceStatusesByCompany`
    - `Invoices.Read.InvoiceDefaultStatus`
    - `Invoices.Read.InvoiceHeaderIds`
    - `Invoices.Read.InvoiceHeaderId`
- ### Invoices.Write
    - `Invoices.Write.Invoice`
    - `Invoices.Write.Invoice`
    - `Invoices.Write.InvoiceNextStatuses`
    - `Invoices.Write.InvoicePreviousStatuses`
    - `Invoices.Write.InvoiceHeaderIds`
    - `Invoices.Write.InvoiceHeaderId`

## Ledger Permissions
- ### Ledger.Read
    - `Ledger.Read.CustomerLedger`

## MyHome Permissions
- ### MyHome.Read
    - `MyHome.Read.MyHomeBatchedInvoices`
    - `MyHome.Read.MyHomeBatchedInvoice`
- ### MyHome.Write
    - `MyHome.Write.MyHomeInvoice`
    - `MyHome.Write.MyHomeBatchedInvoices`

## Payments Permissions
- ### Payments.Read
    - `Payments.Read.InvoicePayments`
- ### Payments.Write
    - `Payments.Write.PayInvoices`

## WareHouse Permissions
- ### WareHouse.Read
    - `WareHouse.Read.WareHouses`
    - `WareHouse.Read.WareHouseNames`
- ### WareHouse.Write
    - `WareHouse.Write.WareHouse`
    - `WareHouse.Write.WareHouse`

## Permissions Hierarchy
## Sales.Admin
- ### Address.Admin
    - **Address.Read**
        - `Address.Read.Countries`
        - `Address.Read.States`
        - `Address.Read.Cities`
- ### CustomerNote.Admin
    - **CustomerNote.Read**
        - `CustomerNote.Read.CustomerNotes`
    - **CustomerNote.Write**
        - `CustomerNote.Write.CustomerNote`
        - `CustomerNote.Write.CustomerNoteNextStatus`
        - `CustomerNote.Write.CustomerNotePreviousStatus`
- ### Customers.Admin
    - **Customers.Read**
        - `Customers.Read.CustomerNames`
        - `Customers.Read.Customers`
        - `Customers.Read.Customer`
        - `Customers.Read.AddressByCustomerId`
    - **Customers.Write**
        - `Customers.Write.Customer`
        - `Customers.Write.Customer`
- ### Git.Admin
    - **Git.Read**
        - `Git.Read.GetAllPRs`
- ### Invoices.Admin
    - **Invoices.Read**
        - `Invoices.Read.Invoice`
        - `Invoices.Read.Invoices`
        - `Invoices.Read.InvoiceStatus`
        - `Invoices.Read.InvoiceDetail`
        - `Invoices.Read.InvoiceHeaders`
        - `Invoices.Read.InvoiceHeader`
        - `Invoices.Read.InvoiceHeaderByCustomerId`
        - `Invoices.Read.PaidInvoiceSummary`
        - `Invoices.Read.UnpaidInvoiceSummary`
        - `Invoices.Read.OverdueInvoiceSummary`
        - `Invoices.Read.TotalAmount`
        - `Invoices.Read.InvoiceTotalAmount`
        - `Invoices.Read.InvoiceStatusesByCompany`
        - `Invoices.Read.InvoiceDefaultStatus`
        - `Invoices.Read.InvoiceHeaderIds`
        - `Invoices.Read.InvoiceHeaderId`
    - **Invoices.Write**
        - `Invoices.Write.Invoice`
        - `Invoices.Write.Invoice`
        - `Invoices.Write.InvoiceNextStatuses`
        - `Invoices.Write.InvoicePreviousStatuses`
        - `Invoices.Write.InvoiceHeaderIds`
        - `Invoices.Write.InvoiceHeaderId`
- ### Ledger.Admin
    - **Ledger.Read**
        - `Ledger.Read.CustomerLedger`
- ### MyHome.Admin
    - **MyHome.Read**
        - `MyHome.Read.MyHomeBatchedInvoices`
        - `MyHome.Read.MyHomeBatchedInvoice`
    - **MyHome.Write**
        - `MyHome.Write.MyHomeInvoice`
        - `MyHome.Write.MyHomeBatchedInvoices`
- ### Payments.Admin
    - **Payments.Read**
        - `Payments.Read.InvoicePayments`
    - **Payments.Write**
        - `Payments.Write.PayInvoices`
- ### WareHouse.Admin
    - **WareHouse.Read**
        - `WareHouse.Read.WareHouses`
        - `WareHouse.Read.WareHouseNames`
    - **WareHouse.Write**
        - `WareHouse.Write.WareHouse`
        - `WareHouse.Write.WareHouse`
