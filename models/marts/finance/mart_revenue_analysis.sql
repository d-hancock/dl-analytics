-- Wide table combining drug revenue and expected revenue for financial analysis
SELECT 
    d.calendar_date,
    d.fiscal_period_key,
    d.period_start_date,
    d.period_end_date,
    l.location_id,
    l.location_name,
    p.product_id,
    p.product_name,
    SUM(f.drug_revenue) AS drug_revenue,
    SUM(f.expected_revenue_per_day) AS expected_revenue_per_day
FROM dim_date d
JOIN dim_location l ON d.calendar_date = l.calendar_date
JOIN dim_product p ON l.location_id = p.location_id
JOIN fct_drug_revenue f ON p.product_id = f.product_id
GROUP BY d.calendar_date, l.location_id, p.product_id;