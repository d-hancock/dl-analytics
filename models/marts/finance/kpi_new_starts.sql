-- =================================================================================
-- Finance KPI: New Patient Starts
-- Name: kpi_new_starts
-- Source Tables: dim_date, fct_new_starts
-- Purpose:
--   Pre-aggregate new patient starts at calendar_date and location level,
--   ensuring a complete time series including zero-value days.
-- Key Transformations:
--   • Start with the date spine to ensure complete time series 
--   • Cross join with distinct locations to ensure all date-location combinations
--   • Left join to fact data and use COALESCE for zero-value dates
-- Usage:
--   • Direct source for "New Starts" KPI in patient activity dashboards
--   • Support analysis of patient acquisition trends
--   • Enable location comparison of new patient starts
-- Business Definition:
--   "New Starts" represents unique MRNs with Active status looking back 365 days.
--   This is a high-priority patient demographics KPI.
-- Grain: One row per calendar_date × location_id
-- =================================================================================

-- Get all locations to ensure complete dimensional coverage
WITH locations AS (
    SELECT DISTINCT location_id 
    FROM fct_new_starts
)

SELECT 
    d.calendar_date,              -- Day-level date for time-series analysis
    l.location_id,                -- Facility identifier for location-based analysis
    COALESCE(COUNT(DISTINCT f.patient_id), 0) AS new_starts -- Count of unique new patients
FROM dim_date d
CROSS JOIN locations l
LEFT JOIN fct_new_starts f
    ON d.calendar_date = f.start_date
    AND l.location_id = f.location_id
GROUP BY 
    d.calendar_date, 
    l.location_id;