-- KPI: Expected Revenue Per Day
-- Provides the average expected revenue per day within a given period
-- Each row represents a unique combination of calendar date and contract

SELECT 
    calendar_date, -- Day-level date
    contract_id, -- Unique identifier for the contract
    SUM(expected_revenue) / COUNT(DISTINCT calendar_date) AS expected_revenue_per_day -- Average expected revenue per day
FROM fct_expected_revenue
GROUP BY calendar_date, contract_id;