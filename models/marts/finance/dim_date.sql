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
    calendar_date,              -- Primary key, represents a specific day
    fiscal_period_key,          -- Business key for fiscal period grouping
    period_start_date,          -- First day of the period containing this date
    period_end_date             -- Last day of the period containing this date
FROM int_dim_date;              -- Source intermediate dimension table