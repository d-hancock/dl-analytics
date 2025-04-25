-- =================================================================================
-- Finance KPI: Drug Revenue
-- Name: kpi_drug_revenue
-- Source Tables: dim_date, fct_drug_revenue
-- Purpose: 
--   Pre-aggregate drug revenue at the calendar_date and product level
--   to provide a ready-to-use KPI metric for financial dashboards with complete time series.
-- Key Transformations:
--   • Start with the date spine to ensure complete time series
--   • Cross join with products to ensure all date-product combinations
--   • Left join to drug revenue fact data
--   • Use COALESCE to handle zero-value days
-- Usage:
--   • Direct source for "Drug Revenue" KPI in financial dashboards
--   • Support comparisons of drug revenue across products
--   • Enable time-series analysis of drug revenue trends
-- Business Definition:
--   "Drug Revenue" represents the sum of expected drug revenue from 
--   contracts and billing rules. This is one of the key high-priority
--   revenue and margin KPIs.
-- Grain: One row per calendar_date × product_id
-- =================================================================================

-- Get all products to ensure complete dimensional coverage
WITH products AS (
    SELECT DISTINCT product_id 
    FROM fct_drug_revenue
)

SELECT 
    d.calendar_date,              -- Day-level date for time-series analysis
    p.product_id,                 -- Product identifier for product-level analysis
    COALESCE(SUM(f.drug_revenue), 0) AS total_drug_revenue  -- Aggregated total drug sales revenue
FROM dim_date d
CROSS JOIN products p
LEFT JOIN fct_drug_revenue f
    ON d.calendar_date = f.transaction_date
    AND p.product_id = f.product_id
GROUP BY 
    d.calendar_date, 
    p.product_id;