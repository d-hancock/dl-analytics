-- Summable grain-level fact table for expected revenue
-- Provides expected revenue metrics for aggregation and slicing
-- Each row represents a unique combination of revenue date and contract

SELECT 
    revenue_date, -- Date of the expected revenue
    contract_id, -- Unique identifier for the contract
    SUM(contracted_revenue) AS expected_revenue -- Total expected revenue
FROM int_fct_expected_revenue
GROUP BY revenue_date, contract_id;