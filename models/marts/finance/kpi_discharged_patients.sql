-- KPI: Discharged Patients
-- Provides the count of distinct patients discharged within a given period
-- Each row represents a unique combination of calendar date and location

SELECT 
    calendar_date, -- Day-level date
    location_id, -- Facility or branch identifier
    COUNT(DISTINCT patient_id) AS discharged_patients -- Total number of discharged patients
FROM fct_discharges
GROUP BY calendar_date, location_id;