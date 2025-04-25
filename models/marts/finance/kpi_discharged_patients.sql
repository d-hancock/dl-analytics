-- =================================================================================
-- Finance KPI: Discharged Patients
-- Name: kpi_discharged_patients
-- Source Tables: dim_date, fct_discharges
-- Purpose: 
--   Pre-aggregate patient discharge metrics at calendar_date and location level
--   to provide a ready-to-use KPI metric for operational dashboards.
-- Key Transformations:
--   • Start with the date spine to ensure complete time series
--   • Cross join with distinct locations to ensure all date-location combinations
--   • Left join to fact data and use COALESCE for zero-value dates
-- Usage:
--   • Direct source for "Discharged Patients" KPI in financial dashboards
--   • Support analysis of patient flow and treatment completion rates
--   • Enable facility comparison of discharge volumes
-- Business Definition:
--   "Discharged Patients" represents patients who completed treatment or
--   were discharged from service. This is a high-priority patient
--   demographics KPI that affects revenue projections.
-- Grain: One row per calendar_date × location_id
-- =================================================================================

-- Get all locations to ensure complete dimensional coverage
WITH locations AS (
    SELECT DISTINCT location_id 
    FROM fct_discharges
)

SELECT 
    d.calendar_date,              -- Day-level date for time-series analysis
    l.location_id,                -- Facility identifier for location-based analysis
    COALESCE(COUNT(DISTINCT f.patient_id), 0) AS discharged_patients  -- Count of unique discharged patients
FROM dim_date d
CROSS JOIN locations l
LEFT JOIN fct_discharges f
    ON d.calendar_date = f.discharge_date
    AND l.location_id = f.location_id
GROUP BY 
    d.calendar_date, 
    l.location_id;