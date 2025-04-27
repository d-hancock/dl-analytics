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
  Id                    AS claim_id,
  Patient_Id            AS patient_id,
  PatientPolicy_Id      AS patient_policy_id,
  BillingProvider_Id    AS billing_provider_id,
  ClaimType_Id          AS claim_type_id,
  ClaimStatus_Id        AS claim_status_id,
  ClaimNumber           AS claim_number,
  ClaimDate             AS claim_date,
  ClaimAmount           AS claim_amount,
  PaymentAmount         AS payment_amount,
  LastBilledDate        AS last_billed_date,
  CreatedBy             AS created_by,
  CreatedDate           AS created_date,
  ModifiedBy            AS modified_by,
  ModifiedDate          AS modified_date,
  RecStatus             AS record_status
FROM OLTP_DB.Billing.Claim
WHERE RecStatus = 1;
