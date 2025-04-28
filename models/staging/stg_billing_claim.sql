-- =================================================================================
-- 1. Billing Claim View
-- Name: billing_claim
-- Source Tables: OLTP_DB.Billing.Claim
-- Purpose: Extract claim-level data for revenue analysis.
-- Key Transformations:
--   • Rename primary key to `claim_id`.
--   • Extract relevant claim attributes.
-- Usage:
--   • Source for all claim-based revenue metrics.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.billing_claim AS
SELECT
  Id                          AS claim_id,
  -- Patient_Id is likely in Billing.Invoice, removed for now
  PatientPolicy_Id            AS patient_policy_id,
  Carrier_Id                  AS carrier_id, -- Added based on source docs
  Invoice_Id                  AS invoice_id, -- Added based on source docs
  -- BillingProvider_Id is not directly in Billing.Claim, removed for now
  ClaimType_Id                AS claim_type_id,
  -- ClaimStatus_Id is not directly in Billing.Claim, removed for now. Consider ClaimAssignmentStatus_Id
  ClaimAssignmentStatus_Id    AS claim_assignment_status_id, -- Added based on source docs
  ClaimNo                     AS claim_number, -- Renamed from ClaimNumber based on source docs
  BilledDate                  AS billed_date, -- Renamed from ClaimDate/LastBilledDate based on source docs
  -- ClaimAmount is not directly in Billing.Claim, removed for now
  AmountPaid                  AS amount_paid, -- Renamed from PaymentAmount based on source docs
  Biller_Id                   AS biller_id, -- Added based on source docs
  Authorization_Id            AS authorization_id, -- Added based on source docs
  ClaimLocation_Id            AS claim_location_id, -- Added based on source docs
  CreatedBy                   AS created_by,
  CreatedDate                 AS created_date,
  ModifiedBy                  AS modified_by,
  ModifiedDate                AS modified_date,
  RecStatus                   AS record_status
FROM OLTP_DB.Billing.Claim
WHERE RecStatus = 1;
