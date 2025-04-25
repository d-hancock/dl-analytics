-- =================================================================================
-- Intermediate Fact Table: Expected Revenue
-- Name: int_fct_expected_revenue
-- Source Tables: stg.billing_claim, stg.billing_claim_item
-- Purpose: Transform billing claims into expected revenue metrics for forecasting
-- Key Transformations:
--   • Use service date as revenue date for forecasting
--   • Include proper claim and claim item IDs for tracking
--   • Join claim with claim items to get revenue details
-- Usage:
--   • Feed into finance.fct_expected_revenue for aggregated revenue analysis
--   • Support calculation of "Expected Revenue / Day" KPI metric
-- Grain: One row per claim item revenue event
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.fct_expected_revenue AS
SELECT 
    c.claim_id,
    ci.claim_item_id,
    c.service_from_date AS revenue_date,
    c.patient_id,
    c.carrier_id AS payer_id,
    ci.inventory_item_id AS product_id,
    ci.quantity,
    ci.unit_price,
    ci.total_expected_price AS expected_revenue
FROM DEV_DB.stg.billing_claim c
JOIN DEV_DB.stg.billing_claim_item ci ON c.claim_id = ci.claim_id
WHERE c.record_status = 1
AND ci.record_status = 1;