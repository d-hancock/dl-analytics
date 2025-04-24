-- Model: int_dim_date
-- Location: models/intermediate/
-- Materialization: view
-- Purpose: Centralized date dimension providing calendar and fiscal period information.
-- Inputs:
--   - stg_date: Staging table containing raw date information.
-- Outputs:
--   - calendar_date: Day-level date.
--   - fiscal_period_key: Surrogate key for fiscal periods.
--   - period_start_date, period_end_date: Start and end dates for the fiscal periods.

CREATE OR REPLACE VIEW int_dim_date AS
SELECT
    calendar_date,
    fiscal_period_key,
    period_start_date,
    period_end_date
FROM
    stg_date;