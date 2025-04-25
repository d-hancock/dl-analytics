-- =================================================================================
-- Finance Mart: Patient Activity
-- Name: mart_patient_activity
-- Source Tables:
--   • dim_date - Date dimension for time-based analysis
--   • kpi_discharged_patients - KPI table with discharge metrics
--   • dim_location - Location dimension for facility analysis
--   • kpi_new_starts - KPI table with new patient start metrics
--   • kpi_referrals - KPI table with referral metrics
--   • dim_product - Product dimension for drug/item analysis
--   • dim_therapy - Therapy dimension for treatment type analysis
-- Purpose:
--   Provide a consolidated view of patient activity metrics including discharges,
--   new starts, and referrals for financial and operational analysis with complete time series.
-- Key Transformations:
--   • Start with the date spine to ensure complete time series
--   • Cross join with dimensions to ensure all combinations are present
--   • Left join to KPI tables for metrics
--   • Use COALESCE to handle missing values
-- Key Metrics:
--   • discharged_patients - Count of patients discharged in the period
--   • new_starts - Count of new patients starting treatment
--   • referrals - Count of patient referrals received
-- Usage:
--   • Support financial dashboards and patient activity reporting
--   • Feed the presentation.dashboard_financial_executive view
--   • Enable trend analysis of patient flow and acquisition
-- Grain: One row per calendar_date × location × product × therapy
-- =================================================================================

-- Get all locations, products, and therapies to ensure complete dimensional coverage
WITH locations AS (
    SELECT DISTINCT location_id, location_name 
    FROM dim_location
),
products AS (
    SELECT DISTINCT product_id, product_name 
    FROM dim_product
),
therapies AS (
    SELECT DISTINCT therapy_code, therapy_name 
    FROM dim_therapy
)

SELECT 
    d.calendar_date,           -- Day-level date for time-based analysis
    d.fiscal_period_key,       -- Fiscal period for financial reporting
    d.period_start_date,       -- Start of fiscal period
    d.period_end_date,         -- End of fiscal period
    l.location_id,             -- Facility identifier
    l.location_name,           -- Readable facility name
    p.product_id,              -- Drug/supply item identifier
    p.product_name,            -- Readable product name
    t.therapy_code,            -- Treatment type code
    t.therapy_name,            -- Readable treatment type
    COALESCE(dp.discharged_patients, 0) AS discharged_patients,  -- Total patient discharges
    COALESCE(ns.new_starts, 0) AS new_starts,                    -- Total new patient starts
    COALESCE(r.referrals, 0) AS referrals                        -- Total patient referrals
FROM dim_date d
CROSS JOIN locations l
CROSS JOIN products p
CROSS JOIN therapies t
LEFT JOIN kpi_discharged_patients dp 
    ON d.calendar_date = dp.calendar_date
    AND l.location_id = dp.location_id
LEFT JOIN kpi_new_starts ns 
    ON d.calendar_date = ns.calendar_date
    AND l.location_id = ns.location_id
LEFT JOIN kpi_referrals r 
    ON d.calendar_date = r.calendar_date;