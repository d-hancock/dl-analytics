-- Model: int_fct_drug_revenue
-- Location: models/intermediate/
-- Materialization: view
-- Purpose: Calculate total drug revenue within the period.
-- Inputs:
--   - stg_drug_sales: Staging table for drug sales data.
-- Outputs:
--   - drug_revenue: Total calculated drug revenue.

CREATE OR REPLACE VIEW int_fct_drug_revenue AS
SELECT
    SUM(quantity * unit_price) - SUM(discount_amt) + SUM(tax_amt) AS drug_revenue
FROM
    stg_drug_sales;