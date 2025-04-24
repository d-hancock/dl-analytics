-- =================================================================================
-- Finance KPI: Expected Revenue Per Day
-- Name: kpi_expected_revenue_per_day
-- Source Tables: fct_expected_revenue
-- Purpose: 
--   Calculate daily expected revenue averages for financial forecasting and 
--   daily revenue target tracking.
-- Key Transformations:
--   • Group by calendar date and contract
--   • Calculate daily average by dividing total expected revenue by 
--     the number of distinct calendar dates
-- Usage:
--   • Direct source for "Expected Revenue / Day" KPI in financial dashboards
--   • Support daily revenue target tracking and forecasting
--   • Enable comparison of daily revenue expectations across periods
-- Business Definition:
--   "Expected Revenue / Day" represents the average daily trend of revenue 
--   divided by total days in the period. This is a high-priority revenue
--   metric used for pacing and forecasting.
-- Grain: One row per calendar_date × contract_id
-- =================================================================================

SELECT 
    calendar_date,              -- Day-level date for time-series analysis
    contract_id,                -- Contract identifier for contract-level analysis 
    SUM(expected_revenue) / COUNT(DISTINCT calendar_date) AS expected_revenue_per_day  
                                -- Average expected revenue per calendar day
FROM fct_expected_revenue
GROUP BY calendar_date, contract_id;