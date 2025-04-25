-- =================================================================================
-- Presentation Layer: Financial Executive Dashboard
-- Name: dashboard_financial_executive
-- Source Tables: 
--   • dim_date - Date dimension for time-based analysis and filtering
--   • mart_patient_activity - Consolidated patient metrics (discharges, starts, referrals)  
--   • mart_revenue_analysis - Consolidated revenue metrics
--   • dim_location - Location dimension for facility filtering
--   • dim_product - Product dimension for drug/item filtering
--   • dim_therapy - Therapy dimension for treatment category filtering
--   • dim_payer - Payer dimension for insurance provider filtering
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
    FROM dim_payer
)

SELECT 
    d.calendar_date,           -- Day-level date for time-based analysis
    d.fiscal_period_key,       -- Fiscal period for financial reporting periods
    d.period_start_date,       -- Start date of fiscal period for date range calculations
    d.period_end_date,         -- End date of fiscal period for date range calculations
    
    -- Dimension attributes (using dimension table values preferentially, falling back to mart values)
    COALESCE(l.location_id, ma.location_id, ra.location_id) AS location_id,            
    COALESCE(l.location_name, ma.location_name, ra.location_name) AS location_name,            
    COALESCE(p.product_id, ma.product_id, ra.product_id) AS product_id,                
    COALESCE(p.product_name, ma.product_name, ra.product_name) AS product_name,                
    COALESCE(t.therapy_code, ma.therapy_code) AS therapy_code,            
    COALESCE(t.therapy_name, ma.therapy_name) AS therapy_name,            
    py.payer_id,            
    py.payer_name,          
    
    -- KPI metrics (using COALESCE to ensure zero values instead of nulls)
    COALESCE(ma.discharged_patients, 0) AS discharged_patients,    
    COALESCE(ma.new_starts, 0) AS new_starts,             
    COALESCE(ma.referrals, 0) AS referrals,              
    COALESCE(ra.expected_revenue_per_day, 0) AS expected_revenue_per_day,
    COALESCE(ra.drug_revenue, 0) AS drug_revenue            

FROM dim_date d

-- Join to both marts using calendar_date
LEFT JOIN mart_patient_activity ma 
    ON d.calendar_date = ma.calendar_date
LEFT JOIN mart_revenue_analysis ra 
    ON d.calendar_date = ra.calendar_date 
    -- Join conditions when location and product exist in both marts
    AND (ma.location_id = ra.location_id OR ma.location_id IS NULL OR ra.location_id IS NULL)
    AND (ma.product_id = ra.product_id OR ma.product_id IS NULL OR ra.product_id IS NULL)

-- Join to dimensions for preferred attribute values
LEFT JOIN dim_location l 
    ON COALESCE(ma.location_id, ra.location_id) = l.location_id
LEFT JOIN dim_product p 
    ON COALESCE(ma.product_id, ra.product_id) = p.product_id
LEFT JOIN dim_therapy t 
    ON ma.therapy_code = t.therapy_code
CROSS JOIN payers py  -- Join all payers for complete dimensional coverage

-- Filter to current fiscal year - can be adjusted as needed
WHERE d.calendar_date BETWEEN DATEADD(YEAR, 2025 - EXTRACT(YEAR FROM CURRENT_DATE()), DATE_TRUNC('YEAR', CURRENT_DATE())) 
                          AND DATEADD(YEAR, 2025 - EXTRACT(YEAR FROM CURRENT_DATE()) + 1, DATE_TRUNC('YEAR', CURRENT_DATE())) - 1;