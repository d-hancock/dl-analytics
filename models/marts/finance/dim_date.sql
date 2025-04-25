-- =================================================================================
-- Finance Dimension: Date
-- Name: dim_date
-- Source Tables: int_dim_date
-- Purpose: 
--   Provide the final date dimension for the finance marts layer
--   with all date attributes needed for financial reporting.
-- Key Features:
--   • Includes calendar_date as primary date identifier
--   • Provides fiscal_period_key for financial period grouping
--   • Contains period_start_date and period_end_date for period range calculations
-- Usage:
--   • Core dimension for all time-based analysis in finance dashboards
--   • Used for joins to fact tables and KPI metrics
--   • Enables filtering by date periods in final presentation views
-- Grain: One row per calendar day
-- =================================================================================

SELECT 
    date_id AS calendar_date,    -- Primary key, represents a specific day
    date_day,                    -- Raw calendar date
    fiscal_period_key,           -- Business key for fiscal period grouping
    day_name,                    -- Name of the day (Monday, Tuesday, etc.)
    day_of_month,                -- Day number within month (1-31)
    day_of_week,                 -- Day number within week (0=Sunday, 1=Monday, etc.)
    day_of_year,                 -- Day number within year (1-366)
    week_of_year,                -- Week number within year
    month_number,                -- Month number (1-12)
    month_name,                  -- Month name (January, February, etc.)
    quarter_number,              -- Quarter number (1-4)
    year_number,                 -- Year number
    is_current_day,              -- Flag for current date
    is_current_month,            -- Flag for dates in current month
    is_weekday,                  -- Flag for weekday vs weekend
    -- Derived period date ranges (placeholders until fiscal periods populated)
    DATEADD(DAY, 1-day_of_month, date_day) AS period_start_date,  -- First day of month
    LAST_DAY(date_day) AS period_end_date  -- Last day of month
FROM int_dim_date;              -- Source intermediate dimension table