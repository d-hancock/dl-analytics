-- =================================================================================
-- Intermediate Fact Table: Expected Revenue
-- Name: int_fct_expected_revenue
-- Source Tables: stg_billing_claim
-- Purpose: Transform billing claims into expected revenue metrics for forecasting
-- Key Transformations:
--   • Map claim_date to revenue_date for consistent date dimension joining
--   • Map claim_id to contract_id for entity identification
--   • Include location_id for location-specific revenue analysis
--   • Map total_amount to contracted_revenue for clear business terminology
-- Usage:
--   • Feed into finance.fct_expected_revenue for aggregated revenue analysis
--   • Support calculation of "Expected Revenue / Day" KPI metric
-- Grain: One row per contract/claim revenue event
-- =================================================================================

SELECT 
    claim_date AS revenue_date,       -- Date when revenue is expected (for date dimension)
    claim_id AS contract_id,          -- Unique identifier for revenue source
    location_id,                      -- Facility identifier for location dimension joining
    total_amount AS contracted_revenue -- Amount expected from this contract/claim
FROM stg_billing_claim;               -- Source staging table