-- Model: int_fct_expected_revenue
-- Location: models/intermediate/
-- Materialization: view
-- Purpose: Calculate expected revenue per day within the period.
-- Inputs:
--   - stg_revenue: Staging table for revenue data.
--   - int_dim_date: Dimension table for calendar dates.
-- Outputs:
--   - expected_revenue_per_day: Average revenue per calendar day.

CREATE OR REPLACE VIEW int_fct_expected_revenue AS
SELECT
    SUM(total_revenue) / COUNT(DISTINCT calendar_date) AS expected_revenue_per_day
FROM
    (
        SELECT
            calendar_date,
            SUM(contracted_revenue) AS total_revenue
        FROM
            stg_revenue
        GROUP BY
            calendar_date
    );