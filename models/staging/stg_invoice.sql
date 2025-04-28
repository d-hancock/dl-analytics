-- =================================================================================
-- Staging Layer: Invoice
-- Name: stg_invoice
-- Source Tables: OLTP_DB.Billing.Invoice
-- Purpose: 
--   Extract invoice header information to provide context for revenue analysis.
-- Key Transformations:
--   • Rename primary key to `invoice_id`
--   • Extract relevant invoice attributes including service dates and revenue flags
--   • Maintain relationships to key dimensions (patient, provider, carrier)
-- Usage:
--   • Source for revenue facts
--   • Enables time-based revenue analysis through service dates
--   • Supports revenue categorization by provider, patient, and carrier
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.invoice AS
SELECT
  Id                      AS invoice_id,
  InvoiceNumber           AS invoice_number,
  Patient_Id              AS patient_id,
  BillingProvider_Id      AS billing_provider_id,
  Company_Id              AS company_id,
  Carrier_Id              AS carrier_id,
  ClaimType_Id            AS claim_type_id,
  Therapy_Id              AS therapy_id,
  TaxCode_Id              AS tax_code_id,
  TaxPercentage           AS tax_percentage,
  ServiceFromDate         AS service_from_date,
  ServiceToDate           AS service_to_date,
  IsPointOfSale           AS is_point_of_sale,
  IsRevenue               AS is_revenue,
  ClosedDate              AS closed_date,
  AccountingPeriod_Id     AS accounting_period_id,
  CreatedBy               AS created_by,
  CreatedDate             AS created_date,
  ModifiedBy              AS modified_by,
  ModifiedDate            AS modified_date,
  RecStatus               AS record_status
FROM OLTP_DB.Billing.Invoice
WHERE RecStatus = 1;  -- Only include active records