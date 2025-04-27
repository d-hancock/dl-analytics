-- =================================================================================
-- Billing Claim Item View
-- Name: stg_billing_claim_item
-- Source Tables: OLTP_DB.Billing.ClaimItem
-- Purpose: Extract claim line items for revenue analysis
-- Key Transformations:
--   • Rename columns to use standard naming conventions
--   • Filter for active records only
-- Usage:
--   • Detailed claim item analysis for revenue metrics
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.billing_claim_item AS
SELECT
    Id                   AS claim_item_id,
    Claim_Id             AS claim_id,
    Invoice_Id           AS invoice_id, 
    InventoryItem_Id     AS inventory_item_id,
    Quantity             AS quantity,
    ExpectedPrice        AS unit_price,
    TotalExpectedPrice   AS total_expected_price,
    ServiceFromDate      AS service_from_date,
    ServiceToDate        AS service_to_date,
    RecStatus            AS record_status
FROM OLTP_DB.Billing.ClaimItem
WHERE RecStatus = 1;