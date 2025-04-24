-- KPI: New Patient Starts
-- Provides the count of distinct new patient starts within a given period
-- Each row represents a unique combination of calendar date and location

SELECT 
    calendar_date, -- Day-level date
    location_id, -- Facility or branch identifier
    COUNT(DISTINCT patient_id) AS new_starts -- Total number of new patient starts
FROM fct_new_starts
GROUP BY calendar_date, location_id;