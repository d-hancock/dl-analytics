# SQL File Metadata

| File Name | Purpose | Description | Usage | Example Data | Data Grain |
|-----------|---------|-------------|-------|--------------|------------|
| stg_utilities_date.sql | Provides a clean calendar dimension spanning 1900-01-01 to 2099-12-31. | Exposes key date attributes for time-series analyses and joins. | Drive time-series joins, fill missing dates, and implement custom fiscal logic. | N/A | Day-level date |
| stg_common_party_address.sql | Consolidates party address details into a single view. | Normalizes field names, filters only active addresses. | Join to invoices, payments, and carrier tables for master data. | N/A | Party-level data |
| stg_common_facility.sql | Standardizes facility (site) master data for reporting. | Includes location metadata and geographic attributes. | Join to inventory and billing data for location-based reporting. | N/A | Facility-level data |
| stg_inventory_item.sql | Cleans and standardizes inventory master records. | Includes pricing base cost and categorization. | Feed into inventory consumption and COGS calculations. | N/A | Product-level data |
| stg_billing_invoice.sql | Base invoice header info for linking to invoice items and payments. | Filters only finalized invoices for revenue reporting. | Analyze invoice-level revenue and AR performance. | N/A | Invoice-level data |
| stg_billing_invoice_item.sql | Invoice line items for detailed revenue, discount, and tax analyses. | Compute net_line_amount in downstream layers, not here. | Analyze service-level revenue and AR performance. | N/A | Invoice item-level data |
| stg_encounter_patient_encounter.sql | Raw encounter events used for discharge and new-start metrics. | Discharge date null means ongoing encounter. | Analyze patient encounters for operational metrics. | N/A | Encounter-level data |
| stg_encounter_discharge_summary.sql | Summarized discharge records, capturing final outcome by encounter. | Use discharge_date for period assignment in fact tables. | Analyze discharge outcomes for operational and clinical metrics. | N/A | Discharge-level data |
| stg_encounter_patient_order.sql | Raw patient orders used to identify referrals and first starts. | OrderDate drives the "new start" logic in fact layers. | Analyze patient orders for referral and new-start metrics. | N/A | Order-level data |
| stg_billing_carrier.sql | Payer master list for AR & revenue slicing. | Only include carriers with active coverage periods covering invoice dates. | Join to claims and invoices for payer-level revenue analysis. | N/A | Payer-level data |