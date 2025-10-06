# Common Permissions

## Accounts Permissions
- **Accounts.Read**
  - `Accounts.Read.AccountGroups`
  - `Accounts.Read.AccountCategories`
  - `Accounts.Read.SalesAccounts`
  - `Accounts.Read.PurchaseAccounts`
  - `Accounts.Read.BankAccounts`
  - `Accounts.Read.CashAccounts`
  - `Accounts.Read.BankAndCashAccounts`
  - `Accounts.Read.ChartOfAccounts`
  - `Accounts.Read.ChildAccounts`
- **Accounts.Write**
  - `Accounts.Write.AccountGroups`
  - `Accounts.Write.AccountCategories`
  - `Accounts.Write.ChartOfAccounts`

## Address Permissions
- **Address.Read**
  - `Address.Read.Countries`
  - `Address.Read.States`
  - `Address.Read.Cities`
  - `Address.Read.Addresses`

## Company Permissions
- **Company.Read**
  - `Company.Read.Companies`
  - `Company.Read.CompanyNames`
  - `Company.Read.Company`
  - `Company.Read.CompaniesByOrganization`
  - `Company.Read.DefaultCompanyByUser`
- **Company.Write**
  - `Company.Write.Companies`

## Company Preferences Permissions
- **CompanyPreferences.Read**
  - `CompanyPreferences.Read.CompanyPreferences`
- **CompanyPreferences.Write**
  - `CompanyPreferences.Write.CompanyPreferences`

## Currency Permissions
- **Currency.Read**
  - `Currency.Read.Currencies`

## Customers Permissions
- **Customers.Write**
  - `Customers.Write.Customers`

## General Ledgers Permissions
- **GeneralLedgers.Read**
  - `GeneralLedgers.Read.GeneralLedgers`
- **GeneralLedgers.Write**
  - `GeneralLedgers.Write.GeneralLedgers`

## Journal Voucher Permissions
- **JournalVoucher.Write**
  - `JournalVoucher.Write.JournalVouchers`

## Notification Permissions
- **Notification.Read**
  - `Notification.Read.Notifications`
- **Notification.Write**
  - `Notification.Write.Notifications`

## Organization Permissions
- **Organization.Read**
  - `Organization.Read.OrganizationAccounts`
  - `Organization.Read.OrganizationAccountsByCompany`

## Payments Permissions
- **Payments.Write**
  - `Payments.Write.Payments`

## Permissions Management
- **Permissions.Read**
  - `Permissions.Read.Permissions`

## Public User Permissions
- **PublicUser.Read**
  - `PublicUser.Read.PublicUsers`

## Roles Permissions
- **Roles.Read**
  - `Roles.Read.Roles`

## Transaction Permissions
- **Transaction.Write**
  - `Transaction.Write.Transactions`

## Users Permissions
- **Users.Read**
  - `Users.Read.Users`
  - `Users.Read.UserNames`
- **Users.Write**
  - `Users.Write.Users`

## Vendors Permissions
- **Vendors.Write**
  - `Vendors.Write.Vendors`

## Warehouse Permissions
- **Warehouse.Read**
  - `Warehouse.Read.Warehouses`
  - `Warehouse.Read.WarehouseNames`
- **Warehouse.Write**
  - `Warehouse.Write.Warehouses`

## Permissions Hierarchy

## Common.Admin
- ### Accounts.Admin
    - **Accounts.Read**
        - `Accounts.Read.AccountGroups`
        - `Accounts.Read.AccountCategories`
        - `Accounts.Read.SalesAccounts`
        - `Accounts.Read.PurchaseAccounts`
        - `Accounts.Read.BankAccounts`
        - `Accounts.Read.CashAccounts`
        - `Accounts.Read.BankAndCashAccounts`
        - `Accounts.Read.ChartOfAccounts`
        - `Accounts.Read.ChildAccounts`
    - **Accounts.Write**
        - `Accounts.Write.AccountGroups`
        - `Accounts.Write.AccountCategories`
        - `Accounts.Write.ChartOfAccounts`
- ### Address.Admin
    - **Address.Read**
        - `Address.Read.Countries`
        - `Address.Read.States`
        - `Address.Read.Cities`
        - `Address.Read.Addresses`
- ### Company.Admin
    - **Company.Read**
      - `Company.Read.Companies`
      - `Company.Read.CompanyNames`
      - `Company.Read.Company`
      - `Company.Read.CompaniesByOrganization`
      - `Company.Read.DefaultCompanyByUser`
    - **Company.Write**
      - `Company.Write.Companies`
- ### CompanyPreferences.Admin
    - **CompanyPreferences.Read**
      - `CompanyPreferences.Read.CompanyPreferences`
    - **CompanyPreferences.Write**
      - `CompanyPreferences.Write.CompanyPreferences`
- ### Currency.Admin
    - **Currency.Read**
      - `Currency.Read.Currencies`
- ### Customers.Admin
    - **Customers.Write**
      - `Customers.Write.Customers`
- ### GeneralLedgers.Admin
    - **GeneralLedgers.Read**
      - `GeneralLedgers.Read.GeneralLedgers`
    - **GeneralLedgers.Write**
      - `GeneralLedgers.Write.GeneralLedgers`
- ### JournalVoucher.Admin
    - **JournalVoucher.Write**
      - `JournalVoucher.Write.JournalVouchers`
- ### Notification.Admin
    - **Notification.Read**
      - `Notification.Read.Notifications`
    - **Notification.Write**
      - `Notification.Write.Notifications`
- ### Organization.Admin**
    - **Organization.Read**
      - `Organization.Read.OrganizationAccounts`
      - `Organization.Read.OrganizationAccountsByCompany`
- ### Payments.Admin
    - **Payments.Write**
      - `Payments.Write.Payments`
  - **Permissions.Admin
    - **Permissions.Read**
      - `Permissions.Read.Permissions`
- ### PublicUser.Admin
    - **PublicUser.Read**
      - `PublicUser.Read.PublicUsers`
- ### Roles.Admin
    - **Roles.Read**
      - `Roles.Read.Roles`
- ### Transaction.Admin
    - **Transaction.Write**
      - `Transaction.Write.Transactions`
- ### Users.Admin
    - **Users.Read**
      - `Users.Read.Users`
      - `Users.Read.UserNames`
    - **Users.Write**
      - `Users.Write.Users`
- ### Vendors.Admin
    - **Vendors.Write**
      - `Vendors.Write.Vendors`
- ### Warehouse.Admin
    - **Warehouse.Read**
      - `Warehouse.Read.Warehouses`
      - `Warehouse.Read.WarehouseNames`
  - ### Warehouse.Write
      - `Warehouse.Write.Warehouses`
