-- KPI: Expected Revenue / Day
-- Purpose: Calculate the average expected revenue per day.
-- Inputs: int_fct_expected_revenue
CREATE OR REPLACE VIEW marts.finance.kpi_expected_revenue_per_day AS
SELECT
    calendar_date,
    expected_revenue_per_day
FROM
    int_fct_expected_revenue;