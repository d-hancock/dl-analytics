-- =================================================================================
-- Date Dimension View
-- Name: stg_date_dimension
-- Source Tables: OLTP_DB.Utilities.Date
-- Purpose: Extract date information for time-based analysis
-- Key Transformations:
--   • Rename columns to use standard naming conventions
-- Usage:
--   • Dimensional time analysis for all metrics
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.date_dimension AS
SELECT 
    Id                     AS date_id, 
    DayDate                AS calendar_date,
    DayOfCalendarWeek      AS day_of_week,
    DayOfCalendarMonth     AS day_of_month, 
    DayOfCalendarQuarter   AS day_of_quarter, 
    DayOfCalendarYear      AS day_of_year, 
    DayNameShort           AS day_name_short,
    DayNameLong            AS day_name_long,
    WeekdayNameShort       AS weekday_name_short,
    WeekdayNameLong        AS weekday_name_long,
    DayWeekdayInd          AS day_weekday_ind,
    CalendarWeekId         AS week_id, 
    CalendarWeekStartDate  AS week_start_date,
    CalendarWeekEndDate    AS week_end_date,
    CalendarMonthId        AS month_id,
    CalendarMonthStartDate AS month_start_date,
    CalendarMonthEndDate   AS month_end_date,
    MonthOfCalendarQuarter AS month_of_quarter,
    MonthOfCalendarYear    AS month_of_year,
    MonthNameShort         AS month_name_short,
    MonthNameLong          AS month_name_long,
    CalendarMonthDayCount  AS month_day_count,
    CalendarQuarterId      AS quarter_id,
    CalendarQuarterStartDate AS quarter_start_date
FROM OLTP_DB.Utilities.Date;