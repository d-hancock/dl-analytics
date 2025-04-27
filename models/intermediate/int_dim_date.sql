-- =================================================================================
-- Intermediate Date Dimension View
-- Name: int_dim_date
-- Source Tables: stg.date_dimension
-- Purpose: Standardize date dimension for all mart-level reporting.
-- Key Transformations:
--   • Use proper date dimension fields from staging view
--   • Add fiscal_* fields for reporting
-- Usage:
--   • Core time-based dimension used across all marts
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.dim_date AS
SELECT
    date_id,
    calendar_date,
    day_of_week AS day_of_week_name,
    day_of_month,
    day_of_year,
    month_id,
    quarter_id,
    YEAR(calendar_date) AS year_id,
    
    -- Derive fiscal year fields (assuming fiscal year starts in October)
    CASE
        WHEN MONTH(calendar_date) >= 10 THEN YEAR(calendar_date) + 1
        ELSE YEAR(calendar_date)
    END AS fiscal_year,
    
    CASE
        WHEN MONTH(calendar_date) >= 10 THEN MONTH(calendar_date) - 9
        ELSE MONTH(calendar_date) + 3
    END AS fiscal_month,
    
    CASE
        WHEN MONTH(calendar_date) BETWEEN 10 AND 12 THEN 1
        WHEN MONTH(calendar_date) BETWEEN 1 AND 3 THEN 2
        WHEN MONTH(calendar_date) BETWEEN 4 AND 6 THEN 3
        WHEN MONTH(calendar_date) BETWEEN 7 AND 9 THEN 4
    END AS fiscal_quarter
FROM DEV_DB.stg.date_dimension;