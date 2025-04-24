-- =================================================================================
-- 11. Billing Claim Item View
-- Name: billing_claim_item
-- Source Tables: OLTP_DB.Billing.ClaimItem
-- Purpose: Provide claim line item details for service-level AR.
-- Key Transformations:
--   • Rename primary key to `claim_item_id`.
--   • Expose billed amount for revenue calculations.
-- Usage:
--   • Analyze service-level revenue and AR performance.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.billing_claim_item AS
SELECT
  ClaimItemKey          AS claim_item_id,
  BilledAmount          AS billed_amount
FROM OLTP_DB.Billing.ClaimItem;