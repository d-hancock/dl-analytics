-- =================================================================================
-- 1. Consolidated Date Dimension View
-- Name: date_dimension
-- Source Tables: OLTP_DB.Utilities.Date
-- Purpose: Canonical date dimension scaffold for time-series and fiscal calculations.
-- Key Transformations:
--   • Standardize column names to snake_case.
--   • Add boolean flags for month-end and fiscal period-end.
-- Usage:
--   • Drive time-series joins, fill missing dates, and implement custom fiscal logic.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.date_dimension AS
SELECT
  CalendarDate                 AS calendar_date,
  CalendarYear                 AS calendar_year,
  CalendarMonth                AS calendar_month,
  DayOfWeek                    AS day_of_week,
  FiscalYear                   AS fiscal_year,
  AccountingPeriodKey          AS fiscal_period_key,
  PeriodStartDate              AS period_start_date,
  PeriodEndDate                AS period_end_date,
  CASE WHEN IsMonthEnd = 'Y' THEN TRUE ELSE FALSE END AS is_month_end,
  CASE WHEN IsFiscalPeriodEnd = 'Y' THEN TRUE ELSE FALSE END AS is_fiscal_period_end
FROM OLTP_DB.Utilities.Date;