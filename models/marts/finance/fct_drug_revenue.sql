-- Summable grain-level fact table for drug revenue
-- Provides revenue-related metrics for aggregation and slicing
-- Each row represents a unique combination of transaction date and product

SELECT 
    transaction_date, -- Date of the transaction
    product_id, -- Unique identifier for the product
    SUM(quantity * unit_price - discount_amt + tax_amt) AS drug_revenue -- Total revenue from drug sales
FROM int_fct_drug_revenue
GROUP BY transaction_date, product_id;