-- =====================================================================================
-- DIMENSION: Date Spine
-- Purpose: Serve as the core time axis for all reporting and KPI models
-- Features: Includes calendar logic, weekday flags, and fiscal scaffolding placeholders
-- =====================================================================================

-- Note: Add fiscal mappings (e.g., fiscal year, period, quarter) using joins to AccountingPeriod if available
create or replace table int_dim_date as
with date_spine as (
    -- Generate a date range spanning 10 years: 5 in the past, 5 in the future
    select dateadd(day, seq4(), dateadd(year, -5, current_date())) as date_day
    from table(generator(rowcount => 3650))
)
select
    date_day as date_id,                            -- Unique identifier for each day (same as date)
    date_day,                                       -- Raw calendar date

    -- Day/Week attributes
    dayname(date_day) as day_name,                  -- 'Monday', 'Tuesday', etc.
    day(date_day) as day_of_month,                  -- 1-31
    dayofweek(date_day) as day_of_week,             -- 0 = Sunday, 1 = Monday, etc.
    dayofyear(date_day) as day_of_year,             -- 1-365/366
    weekofyear(date_day) as week_of_year,           -- ISO week number

    -- Month/Quarter/Year attributes
    month(date_day) as month_number,
    monthname(date_day) as month_name,
    quarter(date_day) as quarter_number,
    year(date_day) as year_number,

    -- Booleans for easy filtering in dashboards or KPIs
    case when date_day = current_date() then true else false end as is_current_day,
    case when date_day >= date_trunc('month', current_date())
              and date_day < dateadd(month, 1, date_trunc('month', current_date()))
         then true else false end as is_current_month,
    case when dayofweek(date_day) in (0, 6) then false else true end as is_weekday,

    -- Placeholders for future joins with accounting or fiscal periods
    null as fiscal_period_key,                      -- Join from AccountingPeriod table if needed
    null as fiscal_year,                            -- Derived from mapped accounting calendar
    null as is_fiscal_period_end                    -- Can be flagged if needed

from date_spine;