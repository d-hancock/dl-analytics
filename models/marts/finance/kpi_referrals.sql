-- =================================================================================
-- Finance KPI: Referrals
-- Name: kpi_referrals
-- Source Tables: dim_date, fct_referrals
-- Purpose: 
--   Pre-aggregate referral counts at calendar_date level to provide a
--   ready-to-use KPI metric for operational dashboards with complete time series.
-- Key Transformations:
--   • Start with the date spine to ensure complete time series
--   • Left join to referral fact data for accurate day-level counts
--   • Use COALESCE for zero-value dates
-- Usage:
--   • Direct source for "Referrals" KPI in patient flow dashboards
--   • Support analysis of referral patterns over time
--   • Enable comparison of referral volumes
-- Business Definition:
--   "Referrals" represents the total number of patient referrals received.
--   This is a high-priority patient demographics KPI.
-- Grain: One row per calendar_date
-- =================================================================================

SELECT 
    d.calendar_date,               -- Day-level date for time-series analysis
    COALESCE(SUM(r.referral_count), 0) AS referrals  -- Count of referrals, zero if none
FROM dim_date d
LEFT JOIN fct_referrals r
    ON d.calendar_date = r.referral_date
GROUP BY d.calendar_date;