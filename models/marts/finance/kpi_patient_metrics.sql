-- =================================================================================
-- Finance Mart Layer: Patient KPI Metrics
-- Name: kpi_patient_metrics
-- Source Tables: 
--   • finance.fct_patient_activity - Detailed patient activity facts
--   • int_dim_date - Date dimension for time period calculations
-- Purpose: 
--   Provide pre-aggregated patient KPIs ready for dashboard consumption.
--   Optimized for the KPIs specified in the analytical requirements.
-- Key Features:
--   • Period-level aggregations (daily, monthly, quarterly, yearly)
--   • All patient demographic KPIs required in the analytical requirements
--   • Dimensional slices already calculated
-- Usage:
--   • Direct consumption by dashboard_financial_executive
--   • Optimized for KPI card displays and trend charts
-- =================================================================================

WITH daily_patient_activity AS (
    -- Get daily patient activity metrics with all dimension combinations
    SELECT
        pa.calendar_date,
        pa.fiscal_period_key,
        pa.fiscal_year,
        pa.fiscal_month,
        pa.fiscal_quarter,
        pa.location_id,
        pa.therapy_type_id,
        pa.referrals,
        pa.new_starts,
        pa.discharged_patients,
        pa.net_patient_change
    FROM DEV_DB.marts.finance.fct_patient_activity pa
),

-- Add period date ranges for time context
calendar_periods AS (
    SELECT
        fiscal_period_key,
        fiscal_year,
        fiscal_month,
        fiscal_quarter,
        MIN(calendar_date) AS period_start_date,
        MAX(calendar_date) AS period_end_date,
        COUNT(DISTINCT calendar_date) AS days_in_period
    FROM DEV_DB.int.dim_date
    GROUP BY 
        fiscal_period_key,
        fiscal_year,
        fiscal_month,
        fiscal_quarter
)

-- Final KPI aggregation at multiple levels
SELECT
    -- Time dimensions (grain options for dashboard)
    cp.fiscal_year,
    cp.fiscal_quarter,
    cp.fiscal_month,
    cp.fiscal_period_key,
    cp.period_start_date,
    cp.period_end_date,
    
    -- Entity dimensions
    pa.location_id,
    pa.therapy_type_id,
    
    -- Summary metrics (required KPIs from analytical requirements)
    SUM(pa.referrals) AS total_referrals,
    SUM(pa.new_starts) AS total_new_starts,
    SUM(pa.discharged_patients) AS total_discharged_patients,
    SUM(pa.net_patient_change) AS net_patient_change,
    
    -- Per-day calculations
    SUM(pa.referrals) / cp.days_in_period AS referrals_per_day,
    SUM(pa.new_starts) / cp.days_in_period AS new_starts_per_day,
    SUM(pa.discharged_patients) / cp.days_in_period AS discharges_per_day,
    
    -- Conversion metrics
    CASE 
        WHEN SUM(pa.referrals) > 0 THEN SUM(pa.new_starts) / SUM(pa.referrals) * 100 
        ELSE 0 
    END AS referral_to_start_conversion_rate,
    
    -- Comparison metrics
    LAG(SUM(pa.new_starts)) OVER (
        PARTITION BY pa.location_id, pa.therapy_type_id 
        ORDER BY cp.fiscal_period_key
    ) AS prior_period_new_starts,
    
    -- Growth calculations
    (SUM(pa.new_starts) - LAG(SUM(pa.new_starts)) OVER (
        PARTITION BY pa.location_id, pa.therapy_type_id 
        ORDER BY cp.fiscal_period_key
    )) / NULLIF(LAG(SUM(pa.new_starts)) OVER (
        PARTITION BY pa.location_id, pa.therapy_type_id 
        ORDER BY cp.fiscal_period_key
    ), 0) * 100 AS new_starts_growth_pct,
    
    -- Period context
    cp.days_in_period
    
FROM daily_patient_activity pa
JOIN calendar_periods cp ON pa.fiscal_period_key = cp.fiscal_period_key
GROUP BY
    cp.fiscal_year,
    cp.fiscal_quarter,
    cp.fiscal_month,
    cp.fiscal_period_key,
    cp.period_start_date,
    cp.period_end_date,
    pa.location_id,
    pa.therapy_type_id,
    cp.days_in_period;