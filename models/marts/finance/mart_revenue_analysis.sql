-- =================================================================================
-- Finance Mart: Revenue Analysis
-- Name: mart_revenue_analysis
-- Source Tables: 
--   • dim_date - Date dimension for time-based analysis
--   • fct_drug_revenue - Fact table with drug revenue metrics
--   • dim_location - Location dimension for facility analysis
--   • dim_product - Product dimension for drug/item analysis
--   • fct_expected_revenue - Fact table with expected revenue metrics
-- Purpose: 
--   Provide a consolidated view of actual drug revenue and expected revenue
--   metrics for financial analysis and reporting with complete time series
-- Key Transformations:
--   • Start with the date spine to ensure complete time series
--   • Cross join with locations and products to ensure all combinations
--   • Left join to fact tables for metrics
--   • Calculate revenue metrics with COALESCE to handle missing data
-- Key Metrics:
--   • drug_revenue - Total revenue from drug sales in the period
--   • expected_revenue_per_day - Average expected revenue per day
-- Usage:
--   • Support financial dashboards and revenue forecasting
--   • Enable comparison of expected vs. actual revenue
--   • Feed the presentation.dashboard_financial_executive view
-- Grain: One row per calendar_date × location × product
-- =================================================================================

-- Get all locations and products to ensure complete dimensional coverage
WITH locations AS (
    SELECT DISTINCT location_id, location_name 
    FROM dim_location
),
products AS (
    SELECT DISTINCT product_id, product_name 
    FROM dim_product
)

SELECT 
    d.calendar_date,              -- Day-level date for time series analysis
    d.fiscal_period_key,          -- Fiscal period for financial reporting
    d.period_start_date,          -- Start of fiscal period
    d.period_end_date,            -- End of fiscal period
    l.location_id,                -- Facility identifier
    l.location_name,              -- Readable facility name
    p.product_id,                 -- Drug or supply item identifier
    p.product_name,               -- Readable product name
    COALESCE(SUM(f.drug_revenue), 0) AS drug_revenue,  -- Total drug sales revenue
    COALESCE(e.expected_revenue_per_day, 0) AS expected_revenue_per_day  -- Budgeted daily revenue target
FROM dim_date d
CROSS JOIN locations l
CROSS JOIN products p
LEFT JOIN fct_drug_revenue f 
    ON d.calendar_date = f.transaction_date
    AND l.location_id = f.location_id
    AND p.product_id = f.product_id
LEFT JOIN kpi_expected_revenue_per_day e 
    ON d.calendar_date = e.calendar_date
GROUP BY 
    d.calendar_date, 
    d.fiscal_period_key,
    d.period_start_date, 
    d.period_end_date,
    l.location_id, 
    l.location_name,
    p.product_id, 
    p.product_name,
    e.expected_revenue_per_day;