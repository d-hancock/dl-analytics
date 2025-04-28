-- =================================================================================
-- Staging Layer: Patient Aggregate
-- Name: stg_patient_aggregate
-- Source Tables: OLTP_DB.Billing.PatientAggregate
-- Purpose: 
--   Extract patient-level financial summaries including expected revenue data.
-- Key Transformations:
--   • Rename primary key to `patient_agg_id` (matches the Patient.Id)
--   • Extract all financial summary fields including expected revenue totals
--   • Include patient-specific balance fields and key dates
-- Usage:
--   • Source for patient-level financial KPIs
--   • Enables analysis of expected revenue by patient
--   • Supports patient financial performance reporting
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.patient_aggregate AS
SELECT
  Id                    AS patient_agg_id,   -- This matches the Patient.Id
  BilledPrice           AS billed_price,
  ExpectedPrice         AS expected_price,
  BilledTax             AS billed_tax,
  ExpectedTax           AS expected_tax,
  TotalBilledPrice      AS total_billed_price,
  TotalExpectedPrice    AS total_expected_price,
  TotalAdjusted         AS total_adjusted,
  TotalCredits          AS total_credits,
  TotalPaid             AS total_paid,
  TotalTransfers        AS total_transfers,
  Balance               AS balance,
  TotalRevenue          AS total_revenue,
  PatientBalance        AS patient_balance,
  InsuranceBalance      AS insurance_balance,
  TotalRevenueBalance   AS total_revenue_balance,
  HeldRevenue           AS held_revenue,
  UnbilledRevenue       AS unbilled_revenue,
  LastPaymentDate       AS last_payment_date,
  LastBilledDate        AS last_billed_date
FROM OLTP_DB.Billing.PatientAggregate;