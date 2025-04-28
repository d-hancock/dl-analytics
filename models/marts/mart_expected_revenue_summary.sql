-- =================================================================================
-- Mart Layer: Expected Revenue Summary
-- Name: mart_expected_revenue_summary
-- Source Tables: 
--   • int_expected_revenue
-- Purpose: 
--   Provides aggregated expected revenue metrics across multiple dimensions for
--   financial reporting and KPI analysis. This model serves as the primary source
--   for expected revenue dashboards and financial reports.
-- Key Transformations:
--   • Aggregates expected revenue data across multiple dimensions
--   • Calculates key metrics like average invoice value and revenue realization %
--   • Provides time-based summaries for trend analysis
-- Usage:
--   • Powers expected revenue KPI dashboards
--   • Enables financial trend analysis and forecasting
--   • Supports comparison of expected vs. actual revenue
-- =================================================================================

WITH monthly_summaries AS (
    SELECT
        -- Time dimensions
        service_year,
        service_month,
        service_month_start,
        
        -- Entity dimensions
        company_id,
        carrier_id,
        billing_provider_id,
        therapy_id,
        claim_type_id,
        
        -- Revenue metrics
        COUNT(DISTINCT invoice_id) AS invoice_count,
        SUM(invoice_total_expected_price) AS total_expected_revenue,
        SUM(total_paid) AS total_actual_revenue,
        SUM(revenue_gap) AS total_revenue_gap,
        
        -- Derived metrics
        CASE 
            WHEN SUM(invoice_total_expected_price) = 0 THEN 0
            ELSE SUM(total_paid) / SUM(invoice_total_expected_price) * 100 
        END AS revenue_realization_pct,
        
        -- Avg values
        AVG(invoice_total_expected_price) AS avg_expected_invoice_value
    FROM 
        DEV_DB.intermediate.int_expected_revenue
    WHERE
        invoice_total_expected_price > 0
    GROUP BY
        service_year,
        service_month,
        service_month_start,
        company_id,
        carrier_id,
        billing_provider_id,
        therapy_id,
        claim_type_id
),

invoice_status_summary AS (
    SELECT
        -- Time dimensions
        service_year,
        service_month,
        service_month_start,
        
        -- Invoice status dimension
        invoice_status,
        
        -- Entity dimensions
        company_id,
        carrier_id,
        
        -- Metrics
        COUNT(DISTINCT invoice_id) AS invoice_count,
        SUM(invoice_total_expected_price) AS total_expected_revenue,
        SUM(total_paid) AS total_actual_revenue
    FROM 
        DEV_DB.intermediate.int_expected_revenue
    GROUP BY
        service_year,
        service_month,
        service_month_start,
        invoice_status,
        company_id,
        carrier_id
)

-- Main mart model
SELECT
    -- Time dimensions
    ms.service_year,
    ms.service_month,
    ms.service_month_start,
    
    -- Entity dimensions
    ms.company_id,
    ms.carrier_id,1
    ms.billing_provider_id,
    ms.therapy_id,
    ms.claim_type_id,
    
    -- Revenue metrics
    ms.invoice_count,
    ms.total_expected_revenue,
    ms.total_actual_revenue,
    ms.total_revenue_gap,
    ms.revenue_realization_pct,
    ms.avg_expected_invoice_value,
    
    -- Additional metrics from status summary
    COALESCE(open_inv.invoice_count, 0) AS open_invoice_count,
    COALESCE(open_inv.total_expected_revenue, 0) AS open_expected_revenue,
    COALESCE(closed_inv.invoice_count, 0) AS closed_invoice_count,
    COALESCE(closed_inv.total_expected_revenue, 0) AS closed_expected_revenue,
    
    -- Derived metrics
    CASE 
        WHEN COALESCE(ms.invoice_count, 0) = 0 THEN 0
        ELSE COALESCE(open_inv.invoice_count, 0) * 100.0 / ms.invoice_count 
    END AS open_invoice_pct,
    
    -- Current timestamp for tracking last refresh
    CURRENT_TIMESTAMP() AS last_refreshed_at

FROM 
    monthly_summaries ms
LEFT JOIN 
    invoice_status_summary open_inv
    ON  ms.service_year = open_inv.service_year
    AND ms.service_month = open_inv.service_month
    AND ms.company_id = open_inv.company_id
    AND ms.carrier_id = open_inv.carrier_id
    AND open_inv.invoice_status = 'Open'
LEFT JOIN 
    invoice_status_summary closed_inv
    ON  ms.service_year = closed_inv.service_year
    AND ms.service_month = closed_inv.service_month
    AND ms.company_id = closed_inv.company_id
    AND ms.carrier_id = closed_inv.carrier_id
    AND closed_inv.invoice_status = 'Closed'
;