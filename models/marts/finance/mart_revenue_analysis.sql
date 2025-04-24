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
--   metrics for financial analysis and reporting
-- Key Metrics:
--   • drug_revenue - Total revenue from drug sales in the period
--   • expected_revenue_per_day - Average expected revenue per day
-- Usage:
--   • Support financial dashboards and revenue forecasting
--   • Enable comparison of expected vs. actual revenue
--   • Feed the presentation.dashboard_financial_executive view
-- Grain: One row per calendar_date × location × product
-- =================================================================================

SELECT 
    d.calendar_date,              -- Day-level date for time series analysis
    d.fiscal_period_key,          -- Fiscal period for financial reporting
    d.period_start_date,          -- Start of fiscal period
    d.period_end_date,            -- End of fiscal period
    l.location_id,                -- Facility identifier
    l.location_name,              -- Readable facility name
    p.product_id,                 -- Drug or supply item identifier
    p.product_name,               -- Readable product name
    SUM(f.drug_revenue) AS drug_revenue,  -- Total drug sales revenue
    e.expected_revenue_per_day    -- Budgeted daily revenue target
FROM dim_date d
JOIN fct_drug_revenue f ON d.calendar_date = f.transaction_date
JOIN dim_location l ON f.location_id = l.location_id
JOIN dim_product p ON f.product_id = p.product_id
LEFT JOIN fct_expected_revenue e ON d.calendar_date = e.revenue_date 
                                 AND l.location_id = e.location_id
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