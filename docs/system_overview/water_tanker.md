
# Water Tanker Delivery Tracking Feature

## Summary

Many societies rely on external water tankers to supply water intermittently. To enable accurate billing and consumption tracking, this feature allows society managers to record each tanker delivery with essential details such as vendor, date, time, tanker capacity, and actual water received.

This system enables:

- Detailed tracking of tanker deliveries (multiple per day if needed).
- Calculation of total water received per period for billing.
- Reporting on tanker usage trends and vendor performance.

---

## Functional Requirements

- Capture vendor details linked to each tanker delivery.
- Record date and time of each tanker delivery.
- Log tanker capacity (expected liters) and actual liters received.
- Support multiple tanker entries in a single form submission.
- Provide monthly or custom period reports on number of tankers and total liters delivered.
- Validate actual liters ≤ tanker capacity.
- Allow editing and deletion of tanker delivery records.

---

## Database Design

### Table: `water_tanker_deliveries`

| Column                  | Type                           | Description                               |
|-------------------------|--------------------------------|------------------------------------------|
| `id`                    | SERIAL PRIMARY KEY             | Unique record identifier                  |
| `company_id`             | UUID NOT NULL                  | Society/organization identifier           |
| `vendor_id`              | UUID NOT NULL                  | Vendor providing the tanker                |
| `delivery_date`          | DATE NOT NULL                  | Date of tanker delivery                    |
| `delivery_time`          | TIME NOT NULL                  | Time of tanker delivery                    |
| `tanker_capacity_liters` | INTEGER NOT NULL               | Expected tanker capacity (liters)         |
| `actual_received_liters` | INTEGER NOT NULL               | Actual water received (liters)             |
| `created_by`             | UUID NOT NULL                  | User who created the record                 |
| `created_on_utc`         | TIMESTAMP WITH TIME ZONE DEFAULT now() | Record creation timestamp        |
| `modified_by`            | UUID                           | Last modifier user                         |
| `modified_on_utc`        | TIMESTAMP WITH TIME ZONE       | Last modification timestamp                 |

- `company_id` links tanker delivery to the society.
- `vendor_id` refers to existing vendor records.
- Date and time fields capture when the delivery occurred.
- Capacity vs actual liters allow tracking variances.

---

## UI Wireframe Concept

```
--------------------------------------------------------------
| Water Tanker Delivery Entry                                 |
--------------------------------------------------------------
| Vendor: [Dropdown with search/select]                      |
|                                                            |
| ---------------------------------------------------------  |
| | Tanker Deliveries:                                   [+] |  <-- Add new row button
| ---------------------------------------------------------  |
|  #  | Date       | Time      | Capacity (liters) | Actual Received (liters) | [x] |
| ---------------------------------------------------------  |
|  1  | [DatePicker] | [TimePicker] | [number input]   | [number input]           |    |
|  2  | [DatePicker] | [TimePicker] | [number input]   | [number input]           |    |
|  3  | [DatePicker] | [TimePicker] | [number input]   | [number input]           |    |
|  ...                                                      |
|                                                          |
| [ Save ]                                   [ Cancel ]    |
--------------------------------------------------------------
```

### UI Notes

- Vendor selected once per form (assumed one vendor per submission).
- Each delivery entry has its own date, time, capacity, and actual liters.
- Users can add multiple deliveries by clicking the **[ + ]** button.
- Rows can be removed via the delete **[ x ]** button.
- Validation enforces actual liters ≤ capacity.
- After filling, the **Save** button submits all deliveries together.

---

## Reporting & Billing Integration

- Provide reports showing tanker deliveries over a date range.
- Calculate total number of tankers and total liters received for billing cycles.
- Filter reports by vendor or date range.
- Enable export of tanker delivery data for accounting.

---

## Important SQL Queries

### 1. Create table

```sql
CREATE TABLE water_tanker_deliveries (
    id SERIAL PRIMARY KEY,
    company_id UUID NOT NULL,
    vendor_id UUID NOT NULL,
    delivery_date DATE NOT NULL,
    delivery_time TIME NOT NULL,
    tanker_capacity_liters INTEGER NOT NULL,
    actual_received_liters INTEGER NOT NULL,
    created_by UUID NOT NULL,
    created_on_utc TIMESTAMP WITH TIME ZONE DEFAULT now(),
    modified_by UUID,
    modified_on_utc TIMESTAMP WITH TIME ZONE
);
```

### 2. Insert multiple deliveries (example)

```sql
INSERT INTO water_tanker_deliveries
(company_id, vendor_id, delivery_date, delivery_time, tanker_capacity_liters, actual_received_liters, created_by)
VALUES
('company-uuid-1', 'vendor-uuid-1', '2025-05-20', '08:30:00', 15000, 14000, 'user-uuid-1'),
('company-uuid-1', 'vendor-uuid-1', '2025-05-20', '15:45:00', 5000, 5000, 'user-uuid-1');
```

### 3. Query total tankers and liters for a month per company

```sql
SELECT
    COUNT(*) AS total_tankers,
    SUM(actual_received_liters) AS total_liters
FROM water_tanker_deliveries
WHERE company_id = 'company-uuid-1'
  AND delivery_date BETWEEN '2025-05-01' AND '2025-05-31';
```

### 4. Query deliveries by vendor and date range

```sql
SELECT delivery_date, delivery_time, tanker_capacity_liters, actual_received_liters
FROM water_tanker_deliveries
WHERE company_id = 'company-uuid-1'
  AND vendor_id = 'vendor-uuid-1'
  AND delivery_date BETWEEN '2025-05-01' AND '2025-05-31'
ORDER BY delivery_date, delivery_time;
```

---

## Additional Considerations

- Allow editing and deleting tanker delivery records.
- Optionally capture notes or attach delivery receipts/photos.
- Support bulk import for societies that track deliveries on paper.
- Implement notifications/reminders for entering tanker data periodically.

---

## Next Steps

- Implement database migration script for `water_tanker_deliveries` table.
- Build API endpoints to create, update, list, and delete tanker delivery records.
- Develop React form component based on the wireframe with Formik and validation.
- Create reporting UI/dashboard for tanker deliveries and billing summary.

---

# Water Tanker Delivery APIs - Summary

| Action                              | HTTP Method | URL                                                                                       |
|------------------------------------|-------------|-------------------------------------------------------------------------------------------|
| Create multiple tanker deliveries  | POST        | `/api/v1/companies/{companyId}/vendors/{vendorId}/water-tanker-deliveries`                 |
| List tanker deliveries (vendor scoped) | GET         | `/api/v1/companies/{companyId}/vendors/{vendorId}/water-tanker-deliveries`                 |
| List tanker deliveries (company scoped, all vendors) | GET         | `/api/v1/companies/{companyId}/water-tanker-deliveries`                                   |
| Get tanker delivery by ID          | GET         | `/api/v1/companies/{companyId}/vendors/{vendorId}/water-tanker-deliveries/{deliveryId}`    |
| Update tanker delivery             | PUT         | `/api/v1/companies/{companyId}/vendors/{vendorId}/water-tanker-deliveries/{deliveryId}`    |
| Delete tanker delivery             | DELETE      | `/api/v1/companies/{companyId}/vendors/{vendorId}/water-tanker-deliveries/{deliveryId}`    |
| Monthly summary report             | GET         | `/api/v1/companies/{companyId}/vendors/{vendorId}/water-tanker-deliveries/summary?year=2025&month=5` |



## 5. API Specification (Dhanman-Style URLs)

| Action                              | HTTP Method | URL                                                                                       |
|------------------------------------|-------------|-------------------------------------------------------------------------------------------|
| Create multiple tanker deliveries  | POST        | `/api/v1/companies/{companyId}/vendors/{vendorId}/water-tanker-deliveries`                 |
| List tanker deliveries (vendor scoped) | GET         | `/api/v1/companies/{companyId}/vendors/{vendorId}/water-tanker-deliveries`                 |
| List tanker deliveries (company scoped, all vendors) | GET         | `/api/v1/companies/{companyId}/water-tanker-deliveries`                                   |
| Get tanker delivery by ID          | GET         | `/api/v1/companies/{companyId}/vendors/{vendorId}/water-tanker-deliveries/{deliveryId}`    |
| Update tanker delivery             | PUT         | `/api/v1/companies/{companyId}/vendors/{vendorId}/water-tanker-deliveries/{deliveryId}`    |
| Delete tanker delivery             | DELETE      | `/api/v1/companies/{companyId}/vendors/{vendorId}/water-tanker-deliveries/{deliveryId}`    |
| Monthly summary report             | GET         | `/api/v1/companies/{companyId}/vendors/{vendorId}/water-tanker-deliveries/summary?year=2025&month=5` |

---

## 6. Important SQL Queries

### Create table

```sql
CREATE TABLE water_tanker_deliveries (
    id SERIAL PRIMARY KEY,
    company_id UUID NOT NULL,
    vendor_id UUID NOT NULL,
    delivery_date DATE NOT NULL,
    delivery_time TIME NOT NULL,
    tanker_capacity_liters INTEGER NOT NULL,
    actual_received_liters INTEGER NOT NULL,
    created_by UUID NOT NULL,
    created_on_utc TIMESTAMP WITH TIME ZONE DEFAULT now(),
    modified_by UUID,
    modified_on_utc TIMESTAMP WITH TIME ZONE
);
```

### Insert example (multiple deliveries)

```sql
INSERT INTO water_tanker_deliveries
(company_id, vendor_id, delivery_date, delivery_time, tanker_capacity_liters, actual_received_liters, created_by)
VALUES
('company-uuid-1', 'vendor-uuid-1', '2025-05-20', '08:30:00', 15000, 14000, 'user-uuid-1'),
('company-uuid-1', 'vendor-uuid-1', '2025-05-20', '15:45:00', 5000, 5000, 'user-uuid-1');
```

### Query total tankers and liters for a month per company

```sql
SELECT
    COUNT(*) AS total_tankers,
    SUM(actual_received_liters) AS total_liters
FROM water_tanker_deliveries
WHERE company_id = 'company-uuid-1'
  AND delivery_date BETWEEN '2025-05-01' AND '2025-05-31';
```

### Query deliveries by vendor and date range

```sql
SELECT delivery_date, delivery_time, tanker_capacity_liters, actual_received_liters
FROM water_tanker_deliveries
WHERE company_id = 'company-uuid-1'
  AND vendor_id = 'vendor-uuid-1'
  AND delivery_date BETWEEN '2025-05-01' AND '2025-05-31'
ORDER BY delivery_date, delivery_time;
```

---

## 7. Validation & Business Rules

- Actual liters received must be ≤ tanker capacity.
- Delivery date cannot be in the future.
- Vendor and company IDs must be valid and authorized.
- Required fields: vendorId, deliveryDate, deliveryTime, tankerCapacityLiters, actualReceivedLiters.
- Prevent duplicate entries for the same vendor/date/time if needed.

---

## 8. Security & Permissions

- Only authorized users of the company can create/edit/delete tanker deliveries.
- Role-based access control to restrict sensitive operations.
- Audit trails (createdBy, modifiedBy) for accountability.

---

## 9. Testing Considerations

- Unit tests for API endpoints (create, update, delete, list).
- UI tests for form validations and multiple entry handling.
- Edge case tests: invalid liters, missing fields, unauthorized access.
- Performance tests for listing large data sets.

---

## 10. Deployment & Migration

- Include DB migration script for creating the `water_tanker_deliveries` table.
- Version APIs appropriately.
- Prepare rollback scripts for DB changes if necessary.

---

## 11. Examples & Sample Data

- Provide sample API requests and responses.
- Use dummy data in UI for demonstration.

---

## 12. FAQs & Troubleshooting

- Q: How to handle partial deliveries?  
  A: Record actual liters received, which can be less than capacity.

- Q: Can vendors be added dynamically?  
  A: Vendor management is handled separately; ensure vendors exist before assigning.

- Q: How to report total water usage?  
  A: Use the summary report API filtered by company and month.

---

## 13. Next Steps

- Develop DB migration and seed scripts.
- Implement REST APIs following the above spec.
- Build React form UI using the wireframe.
- Create reporting dashboards for management.
- Integrate billing system with delivery data.

---