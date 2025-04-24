-- =================================================================================
-- Finance KPI: Drug Revenue
-- Name: kpi_drug_revenue
-- Source Tables: fct_drug_revenue
-- Purpose: 
--   Pre-aggregate drug revenue at the calendar_date and product level
--   to provide a ready-to-use KPI metric for financial dashboards.
-- Key Transformations:
--   • Summarize drug revenue by calendar date and product 
--   • Calculates total drug revenue for the "Drug Revenue" KPI
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

SELECT 
    calendar_date,              -- Day-level date for time-series analysis
    product_id,                 -- Product identifier for product-level analysis
    SUM(drug_revenue) AS total_drug_revenue  -- Aggregated total drug sales revenue
FROM fct_drug_revenue
GROUP BY calendar_date, product_id;