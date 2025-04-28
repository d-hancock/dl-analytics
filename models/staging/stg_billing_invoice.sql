-- =================================================================================
-- Staging Layer: Billing Invoice
-- Name: stg_billing_invoice
-- Source Tables: OLTP_DB.Billing.Invoice
-- Purpose: 
--   Extract invoice-level data for revenue analysis and reporting.
-- Key Transformations:
--   • Rename primary key to `invoice_id`
--   • Extract relevant invoice attributes
-- Usage:
--   • Source for invoice-based revenue metrics
--   • Feeds into finance.fct_revenue fact table
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.billing_invoice AS
SELECT
  Id                    AS invoice_id,
  InvoiceNumber         AS invoice_number,
  Patient_Id            AS patient_id,
  BillingProvider_Id    AS billing_provider_id,
  Company_Id            AS company_id, -- Added based on source docs
  Carrier_Id            AS carrier_id, -- Added based on source docs
  ClaimType_Id          AS claim_type_id, -- Added based on source docs
  Therapy_Id            AS therapy_id, -- Added based on source docs
  TaxCode_Id            AS tax_code_id, -- Added based on source docs
  TaxPercentage         AS tax_percentage, -- Added based on source docs
  -- InvoiceDate is not directly in Billing.Invoice, using CreatedDate as proxy or ServiceFrom/ToDate
  ServiceFromDate       AS service_from_date, -- Added based on source docs
  ServiceToDate         AS service_to_date, -- Added based on source docs
  ClosedDate            AS closed_date, -- Added based on source docs
  IsPointOfSale         AS is_point_of_sale, -- Added based on source docs
  IsRevenue             AS is_revenue, -- Added based on source docs
  AccountingPeriod_Id   AS accounting_period_id, -- Added based on source docs
  -- Removed columns not found in source documentation:
  -- PatientPolicy_Id
  -- InvoiceAmount
  -- AmountPaid
  -- AmountDue
  -- DueDate
  -- BillingFrequency_Id
  -- ReadyToBillStatus_Id
  -- BillingStatus_Id
  CreatedBy             AS created_by,
  CreatedDate           AS created_date,
  ModifiedBy            AS modified_by,
  ModifiedDate          AS modified_date,
  RecStatus             AS record_status
FROM OLTP_DB.Billing.Invoice
WHERE RecStatus = 1;