-- =================================================================================
-- Billing Claim View
-- Name: stg_billing_claim
-- Source Tables: OLTP_DB.Billing.Claim
-- Purpose: Extract claim information for revenue analysis
-- Key Transformations:
--   • Rename columns to use standard naming conventions
--   • Filter for active records only
-- Usage:
--   • Base table for claim analysis and revenue metrics
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.billing_claim AS
SELECT
    Id                   AS claim_id,
    Invoice_Id           AS invoice_id,
    Carrier_Id           AS carrier_id,
    Patient_Id           AS patient_id,
    ClaimType_Id         AS claim_type_id,
    ServiceFromDate      AS service_from_date,
    Record_Status_Id     AS record_status
FROM OLTP_DB.Billing.Claim
WHERE Record_Status_Id = 1;
