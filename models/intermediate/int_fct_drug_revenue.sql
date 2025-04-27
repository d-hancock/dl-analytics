-- =================================================================================
-- Intermediate Fact Table: Drug Revenue
-- Name: int_fct_drug_revenue
-- Source Tables: stg.billing_claim_item, stg.billing_claim
-- Purpose: Consolidate drug revenue transactions and enable downstream revenue analysis
-- Key Transformations:
--   • Use correct claim item and claim tables for revenue analysis
--   • Include proper revenue-related fields from the documented schema
-- Usage:
--   • Feed into finance.fct_drug_revenue for aggregated revenue analysis
--   • Support calculation of "Drug Revenue" KPI metric
-- Grain: One row per drug claim item
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.fct_drug_revenue AS
SELECT 
    ci.claim_item_id,
    ci.claim_id,
    ci.inventory_item_id AS product_id,
    c.patient_id,
    c.patient_policy_id, 
    c.billing_provider_id,
    ci.service_from_date AS transaction_date,
    ci.quantity,
    ci.unit_price,
    ci.total_expected_price AS total_price
FROM DEV_DB.stg.billing_claim_item ci
JOIN DEV_DB.stg.billing_claim c ON ci.claim_id = c.claim_id
WHERE ci.record_status = 1
AND c.record_status = 1;