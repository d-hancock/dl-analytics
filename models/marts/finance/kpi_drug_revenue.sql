-- KPI: Drug Revenue
-- Provides the total revenue from drug sales within a given period
-- Each row represents a unique combination of calendar date and product

SELECT 
    calendar_date, -- Day-level date
    product_id, -- Drug or supply item identifier
    SUM(drug_revenue) AS total_drug_revenue -- Total revenue from drug sales
FROM fct_drug_revenue
GROUP BY calendar_date, product_id;