-- =================================================================================
-- Finance KPI: Discharged Patients
-- Name: kpi_discharged_patients
-- Source Tables: fct_discharges
-- Purpose: 
--   Pre-aggregate patient discharge metrics at calendar_date and location level
--   to provide a ready-to-use KPI metric for operational dashboards.
-- Key Transformations:
--   • Group by calendar date and location
--   • Count distinct patients discharged for the "Discharged Patients" KPI
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

SELECT 
    calendar_date,              -- Day-level date for time-series analysis
    location_id,                -- Facility identifier for location-based analysis
    COUNT(DISTINCT patient_id) AS discharged_patients  -- Count of unique discharged patients
FROM fct_discharges
GROUP BY calendar_date, location_id;