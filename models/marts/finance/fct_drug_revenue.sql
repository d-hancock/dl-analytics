-- =================================================================================
-- Finance Fact Table: Drug Revenue
-- Name: fct_drug_revenue
-- Source Tables: int_fct_drug_revenue
-- Purpose: 
--   Aggregate drug revenue data at transaction date and product grain,
--   providing metrics for financial reporting and revenue analysis.
-- Key Transformations:
--   • Group by transaction_date, product_id, and location_id
--   • Calculate gross_revenue (before discounts/taxes)
--   • Calculate total_discounts for discount analysis
--   • Calculate total_taxes for tax reporting
--   • Calculate final drug_revenue (gross less discounts plus taxes)
-- Usage:
--   • Feed revenue metrics to mart_revenue_analysis
--   • Support the "Drug Revenue" KPI in financial dashboards
--   • Enable revenue trend analysis by product and location
-- Grain: One row per transaction_date × product_id × location_id
-- =================================================================================

SELECT 
    transaction_date,          -- Date of the transaction for time-series analysis
    product_id,                -- Product identifier for product-level revenue analysis
    location_id,               -- Location identifier for facility-level revenue analysis
    SUM(quantity * unit_price) AS gross_revenue,  -- Total revenue before adjustments
    SUM(discount_amt) AS total_discounts,         -- Total discounts applied
    SUM(tax_amt) AS total_taxes,                  -- Total taxes collected
    SUM(quantity * unit_price - discount_amt + tax_amt) AS drug_revenue  -- Final adjusted revenue
FROM int_fct_drug_revenue      -- Source intermediate fact table
GROUP BY 
    transaction_date, 
    product_id,
    location_id;