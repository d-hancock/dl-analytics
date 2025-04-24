-- Intermediate Fact Table: New Patient Starts
-- Joins and derives metrics related to new patient starts
-- Each row represents a unique patient start event

SELECT 
    start_date, -- Date of the new patient start
    patient_id, -- Unique identifier for the patient
    location_id -- Facility or branch identifier
FROM stg_encounter_patient_encounter;