-- Staging Table: Date Dimension
-- Cleans and casts date data from Utilities.Date for downstream use
-- Maps OLTP DB fields to analytics naming conventions

SELECT 
    Id as date_id, -- Primary key for date dimension
    DayDate as calendar_date, -- Day-level date
    DayOfCalendarWeek as day_of_week, -- Day of the week (numeric)
    DayNameLong as day_of_week_name, -- Name of the day
    DayOfCalendarMonth as day_of_month, -- Day of the month
    DayOfCalendarYear as day_of_year, -- Day of the year
    CalendarWeekId as week_id, -- Week identifier
    CalendarMonthId as month_id, -- Month identifier 
    CalendarQuarterId as quarter_id, -- Quarter identifier
    CalendarYearId as year_id -- Year identifier
FROM Utilities.Date;