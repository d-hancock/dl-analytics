-- =================================================================================
-- 10. Billing Claim View
-- Name: billing_claim
-- Source Tables: OLTP_DB.Billing.Claim
-- Purpose: Represent raw claim headers for AR analysis.
-- Key Transformations:
--   • Rename primary key to `claim_id`.
--   • Expose claim status for downstream reporting.
-- Usage:
--   • Analyze claim-level revenue and AR performance.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.billing_claim AS
SELECT
  ClaimKey              AS claim_id,
  ClaimStatusCode       AS claim_status
FROM OLTP_DB.Billing.Claim;
