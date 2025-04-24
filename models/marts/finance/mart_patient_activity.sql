-- =================================================================================
-- Finance Mart: Patient Activity
-- Name: mart_patient_activity
-- Source Tables:
--   • dim_date - Date dimension for time-based analysis
--   • fct_discharges - Fact table with patient discharge data
--   • dim_location - Location dimension for facility analysis
--   • fct_new_starts - Fact table with new patient start events
--   • fct_referrals - Fact table with referral events
--   • dim_product - Product dimension for drug/item analysis
--   • dim_therapy - Therapy dimension for treatment type analysis
-- Purpose:
--   Provide a consolidated view of patient activity metrics including discharges,
--   new starts, and referrals for financial and operational analysis.
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
    COALESCE(fd.discharge_count, 0) AS discharged_patients, -- Total patient discharges
    COALESCE(fn.new_start_count, 0) AS new_starts,         -- Total new patient starts
    COALESCE(fr.referral_count, 0) AS referrals            -- Total patient referrals
FROM dim_date d
LEFT JOIN fct_discharges fd ON d.calendar_date = fd.discharge_date
LEFT JOIN dim_location l ON fd.location_id = l.location_id
LEFT JOIN fct_new_starts fn ON d.calendar_date = fn.start_date AND fn.location_id = l.location_id
LEFT JOIN fct_referrals fr ON d.calendar_date = fr.referral_date AND fr.location_id = l.location_id
LEFT JOIN dim_product p ON p.product_id IS NOT NULL -- Join all products 
LEFT JOIN dim_therapy t ON t.therapy_code IS NOT NULL -- Join all therapy types
GROUP BY 
    d.calendar_date, 
    d.fiscal_period_key,
    d.period_start_date, 
    d.period_end_date,
    l.location_id, 
    l.location_name,
    p.product_id, 
    p.product_name,
    t.therapy_code, 
    t.therapy_name;