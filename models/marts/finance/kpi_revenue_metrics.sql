-- =================================================================================
-- Finance Mart Layer: Revenue KPI Metrics
-- Name: kpi_revenue_metrics
-- Source Tables: 
--   • finance.fct_revenue - Detailed revenue facts
--   • int_dim_date - Date dimension for time period calculations
-- Purpose: 
--   Provide pre-aggregated revenue KPIs ready for dashboard consumption.
--   Optimized for the KPIs specified in the analytical requirements.
-- Key Features:
--   • Period-level aggregations (daily, monthly, quarterly, yearly)
--   • All revenue KPIs required in the analytical requirements
--   • Dimensional slices already calculated
-- Usage:
--   • Direct consumption by dashboard_financial_executive
--   • Optimized for KPI card displays and trend charts
-- =================================================================================

WITH daily_revenue AS (
    -- Get daily revenue metrics with all dimension combinations
    SELECT
        r.calendar_date,
        r.fiscal_period_key,
        r.fiscal_year,
        r.fiscal_month,
        r.location_id,
        r.product_id,
        r.therapy_type_id,
        r.payer_id,
        r.drug_revenue,
        r.non_drug_revenue,
        r.total_revenue
    FROM DEV_DB.marts.finance.fct_revenue r
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
    dr.location_id,
    dr.product_id,
    dr.therapy_type_id,
    dr.payer_id,
    
    -- Summary metrics (required KPIs from analytical requirements)
    SUM(dr.total_revenue) AS total_expected_revenue,
    SUM(dr.drug_revenue) AS drug_revenue,
    SUM(dr.total_revenue) / cp.days_in_period AS total_expected_revenue_per_day,
    
    -- Comparison metrics
    LAG(SUM(dr.total_revenue)) OVER (
        PARTITION BY dr.location_id, dr.product_id, dr.therapy_type_id, dr.payer_id 
        ORDER BY cp.fiscal_period_key
    ) AS prior_period_revenue,
    
    -- Growth calculations
    (SUM(dr.total_revenue) - LAG(SUM(dr.total_revenue)) OVER (
        PARTITION BY dr.location_id, dr.product_id, dr.therapy_type_id, dr.payer_id 
        ORDER BY cp.fiscal_period_key
    )) / NULLIF(LAG(SUM(dr.total_revenue)) OVER (
        PARTITION BY dr.location_id, dr.product_id, dr.therapy_type_id, dr.payer_id 
        ORDER BY cp.fiscal_period_key
    ), 0) * 100 AS revenue_growth_pct,
    
    -- Period context
    cp.days_in_period
    
FROM daily_revenue dr
JOIN calendar_periods cp ON dr.fiscal_period_key = cp.fiscal_period_key
GROUP BY
    cp.fiscal_year,
    cp.fiscal_quarter,
    cp.fiscal_month,
    cp.fiscal_period_key,
    cp.period_start_date,
    cp.period_end_date,
    dr.location_id,
    dr.product_id,
    dr.therapy_type_id,
    dr.payer_id,
    cp.days_in_period;