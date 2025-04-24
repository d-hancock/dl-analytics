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
-- Usage:
--   • Primary data source for financial executive Tableau dashboard
--   • Entry point for KPI reporting and trend analysis
--   • Supports drill-down analysis across multiple dimensions
-- Grain: One row per calendar_date × location × product × therapy × payer
-- =================================================================================

SELECT 
    d.calendar_date,           -- Day-level date for time-based analysis
    d.fiscal_period_key,       -- Fiscal period for financial reporting periods
    d.period_start_date,       -- Start date of fiscal period for date range calculations
    d.period_end_date,         -- End date of fiscal period for date range calculations
    l.location_id,             -- Facility identifier for location filtering
    l.location_name,           -- Human-readable facility name for display
    p.product_id,              -- Product identifier for drug/supply filtering
    p.product_name,            -- Human-readable product name for display
    t.therapy_code,            -- Therapy code (e.g., HcPc) for therapy type filtering
    t.therapy_name,            -- Human-readable therapy name for display
    payer.payer_id,            -- Payer identifier for insurance provider filtering
    payer.payer_name,          -- Human-readable payer name for display
    ma.discharged_patients,    -- Count of patients discharged in the period
    ma.new_starts,             -- Count of new patients starting treatment
    ma.referrals,              -- Count of referrals received
    ra.expected_revenue_per_day, -- Average expected revenue per day
    ra.drug_revenue            -- Total revenue from drug sales
FROM dim_date d
LEFT JOIN mart_patient_activity ma ON d.calendar_date = ma.calendar_date
LEFT JOIN mart_revenue_analysis ra ON d.calendar_date = ra.calendar_date 
    AND (ma.location_id = ra.location_id OR ma.location_id IS NULL OR ra.location_id IS NULL)
    AND (ma.product_id = ra.product_id OR ma.product_id IS NULL OR ra.product_id IS NULL)
LEFT JOIN dim_location l ON COALESCE(ma.location_id, ra.location_id) = l.location_id
LEFT JOIN dim_product p ON COALESCE(ma.product_id, ra.product_id) = p.product_id
LEFT JOIN dim_therapy t ON ma.therapy_code = t.therapy_code
LEFT JOIN dim_payer payer ON payer.payer_id IS NOT NULL -- Get all payers
WHERE d.calendar_date BETWEEN '2025-01-01' AND '2025-12-31'; -- Filter to current fiscal year