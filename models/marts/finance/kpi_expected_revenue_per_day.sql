-- =================================================================================
-- Finance KPI: Expected Revenue Per Day
-- Name: kpi_expected_revenue_per_day
-- Source Tables: dim_date, fct_expected_revenue
-- Purpose: 
--   Calculate daily expected revenue averages for financial forecasting and 
--   daily revenue target tracking with a complete time series.
-- Key Transformations:
--   • Start with the date spine to ensure complete time series
--   • Left join to expected revenue fact data
--   • Use COALESCE to handle zero-value days
--   • Group by calendar date and contract
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

-- Get all contracts to ensure complete dimensional coverage
WITH contracts AS (
    SELECT DISTINCT contract_id 
    FROM fct_expected_revenue
)

SELECT 
    d.calendar_date,              -- Day-level date for time-series analysis
    c.contract_id,                -- Contract identifier for contract-level analysis
    COALESCE(SUM(e.expected_revenue) / 
             NULLIF(COUNT(DISTINCT d.calendar_date), 0), 0) AS expected_revenue_per_day
                                  -- Average expected revenue per calendar day
FROM dim_date d
CROSS JOIN contracts c
LEFT JOIN fct_expected_revenue e
    ON d.calendar_date = e.revenue_date
    AND c.contract_id = e.contract_id
GROUP BY 
    d.calendar_date,
    c.contract_id;