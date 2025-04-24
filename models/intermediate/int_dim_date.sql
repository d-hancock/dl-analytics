-- =================================================================================
-- Intermediate Date Dimension
-- Name: int_dim_date
-- Source Tables: stg_date_dimension
-- Purpose: 
--   Enrich raw date data with fiscal period attributes and other derived fields
--   needed for time-series analysis and financial reporting periods.
-- Key Transformations:
--   • Map source calendar_date from staging table
--   • Add fiscal_period_key for standardized period management
--   • Include period_start_date and period_end_date for date range calculations
-- Usage:
--   • Core date dimension for all fact table joins
--   • Support time-series analysis and period calculations
--   • Enable MoM, QoQ, and YoY comparisons in downstream analytics
-- Grain: One row per calendar day
-- =================================================================================

SELECT 
    calendar_date,              -- Primary key, represents a specific day
    fiscal_period_key,          -- Business key for fiscal period grouping
    period_start_date,          -- First day of the period containing this date
    period_end_date             -- Last day of the period containing this date
FROM stg_date_dimension;        -- Source staging table