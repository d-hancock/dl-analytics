-- =================================================================================
-- Presentation Layer: Financial Executive Dashboard
-- Name: dashboard_financial_executive
-- Source Tables: 
--   • int.dim_date - Date dimension for time-based analysis and filtering
--   • finance.fct_patient_activity - Consolidated patient metrics (discharges, starts, referrals)  
--   • finance.fct_revenue - Consolidated revenue metrics
--   • finance.kpi_patient_metrics - Pre-aggregated patient KPIs
--   • finance.kpi_revenue_metrics - Pre-aggregated revenue KPIs
--   • int.dim_location - Location dimension for facility filtering
--   • int.dim_product - Product dimension for drug/item filtering
--   • int.dim_therapy - Therapy dimension for treatment category filtering
--   • int.dim_payer - Payer dimension for insurance provider filtering
-- Purpose: 
--   Provide a consolidated, presentation-ready dataset for the financial
--   executive dashboard with all key financial and operational metrics.
-- Key Features:
--   • Time-filtered to the current fiscal year (2025)
--   • Combines patient activity metrics with revenue metrics
--   • Includes all dimension attributes needed for dashboard filtering
--   • One-row-per-dimensional-slice for efficient Tableau visualization
--   • Complete time series with no gaps
-- Usage:
--   • Primary data source for financial executive Tableau dashboard
--   • Entry point for KPI reporting and trend analysis
--   • Supports drill-down analysis across multiple dimensions
-- Grain: One row per calendar_date × location × product × therapy × payer
-- =================================================================================

-- Get all payers to ensure complete dimensional coverage
WITH payers AS (
    SELECT DISTINCT payer_id, payer_name 
    FROM DEV_DB.int.dim_payer
),

-- Get KPI metrics at period level for efficient aggregation
period_metrics AS (
    SELECT
        rm.fiscal_period_key,
        rm.location_id,
        rm.product_id,
        rm.therapy_type_id AS therapy_id,
        rm.payer_id,
        rm.total_expected_revenue,
        rm.drug_revenue,
        rm.total_expected_revenue_per_day AS expected_revenue_per_day
    FROM DEV_DB.marts.finance.kpi_revenue_metrics rm
    
    UNION ALL
    
    SELECT
        pm.fiscal_period_key,
        pm.location_id,
        NULL AS product_id,
        pm.therapy_type_id AS therapy_id,
        NULL AS payer_id,
        0 AS total_expected_revenue,
        0 AS drug_revenue,
        0 AS expected_revenue_per_day
    FROM DEV_DB.marts.finance.kpi_patient_metrics pm
    WHERE NOT EXISTS (
        -- Only include patient metrics that don't already have revenue metrics
        SELECT 1 FROM DEV_DB.marts.finance.kpi_revenue_metrics rm
        WHERE pm.fiscal_period_key = rm.fiscal_period_key
        AND pm.location_id = rm.location_id
        AND pm.therapy_type_id = rm.therapy_type_id
    )
)

SELECT 
    d.calendar_date,           -- Day-level date for time-based analysis
    d.fiscal_period_key,       -- Fiscal period for financial reporting periods
    d.fiscal_year,             -- Fiscal year for annual comparison
    d.fiscal_quarter,          -- Fiscal quarter for quarterly analysis
    d.fiscal_month,            -- Fiscal month for monthly trends
    
    -- Dimension attributes (using dimension table values)
    COALESCE(l.location_id, pa.location_id, fr.location_id) AS location_id,            
    l.location_name,            
    COALESCE(p.product_id, fr.product_id) AS product_id,                
    p.product_name,                
    COALESCE(t.therapy_type_id, pa.therapy_type_id) AS therapy_id,            
    t.therapy_class AS therapy_name,            
    py.payer_id,            
    py.payer_name,          
    
    -- Patient KPI metrics (from fct_patient_activity)
    COALESCE(pa.discharged_patients, 0) AS discharged_patients,    
    COALESCE(pa.new_starts, 0) AS new_starts,             
    COALESCE(pa.referrals, 0) AS referrals,          
    
    -- Revenue KPI metrics (from fct_revenue)    
    COALESCE(fr.drug_revenue, 0) AS drug_revenue,
    COALESCE(fr.total_revenue, 0) AS total_expected_revenue,
    COALESCE(fr.total_revenue_per_day, 0) AS expected_revenue_per_day,
    
    -- Pre-aggregated KPI metrics (for efficient filtering)
    COALESCE(pm.total_expected_revenue, 0) AS period_total_expected_revenue,
    COALESCE(pm.drug_revenue, 0) AS period_drug_revenue,
    COALESCE(pm.expected_revenue_per_day, 0) AS period_expected_revenue_per_day

FROM DEV_DB.int.dim_date d

-- Join to detailed facts for daily analysis
LEFT JOIN DEV_DB.marts.finance.fct_patient_activity pa 
    ON d.calendar_date = pa.calendar_date
LEFT JOIN DEV_DB.marts.finance.fct_revenue fr 
    ON d.calendar_date = fr.calendar_date 
    -- Join conditions when location and product exist in both facts
    AND (pa.location_id = fr.location_id OR pa.location_id IS NULL OR fr.location_id IS NULL)
    AND (pa.therapy_type_id = fr.therapy_type_id OR pa.therapy_type_id IS NULL OR fr.therapy_type_id IS NULL)

-- Join to pre-aggregated metrics for period-level KPIs
LEFT JOIN period_metrics pm
    ON d.fiscal_period_key = pm.fiscal_period_key
    AND COALESCE(pa.location_id, fr.location_id) = pm.location_id
    AND COALESCE(fr.product_id, pm.product_id) = pm.product_id
    AND COALESCE(pa.therapy_type_id, fr.therapy_type_id, pm.therapy_id) = pm.therapy_id
    AND COALESCE(fr.payer_id, pm.payer_id) = pm.payer_id

-- Join to dimensions for attribute values
LEFT JOIN DEV_DB.int.dim_location l 
    ON COALESCE(pa.location_id, fr.location_id, pm.location_id) = l.location_id
LEFT JOIN DEV_DB.int.dim_product p 
    ON COALESCE(fr.product_id, pm.product_id) = p.product_id
LEFT JOIN DEV_DB.int.dim_therapy t 
    ON COALESCE(pa.therapy_type_id, fr.therapy_type_id, pm.therapy_id) = t.therapy_type_id
CROSS JOIN payers py  -- Join all payers for complete dimensional coverage

-- Filter to current fiscal year - can be adjusted as needed
WHERE d.fiscal_year = 2025;