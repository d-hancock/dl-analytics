-- =================================================================================
-- Finance Fact Table: Expected Revenue
-- Name: fct_expected_revenue
-- Source Tables: int_fct_expected_revenue
-- Purpose: 
--   Aggregate expected revenue data at revenue_date and contract level,
--   providing metrics for financial forecasting and planning.
-- Key Transformations:
--   • Group by revenue_date and contract_id
--   • Sum contracted_revenue to calculate total expected revenue 
-- Usage:
--   • Feed expected revenue metrics to mart_revenue_analysis
--   • Support the "Expected Revenue/Day" KPI in financial dashboards
--   • Enable revenue forecasting and revenue target tracking
-- Grain: One row per revenue_date × contract_id
-- =================================================================================

SELECT 
    revenue_date,               -- Date when revenue is expected (for time-series analysis)
    contract_id,                -- Contract identifier for contract-level analysis
    location_id,                -- Location identifier for facility-level revenue analysis
    SUM(contracted_revenue) AS expected_revenue  -- Total expected revenue amount
FROM int_fct_expected_revenue   -- Source intermediate fact table
GROUP BY 
    revenue_date,
    contract_id,
    location_id;