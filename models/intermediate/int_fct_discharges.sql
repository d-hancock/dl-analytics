-- Intermediate Fact Table: Discharges
-- Joins and derives metrics related to patient discharges
-- Each row represents a unique discharge event

SELECT 
    discharge_date, -- Date of discharge
    patient_id, -- Unique identifier for the patient
    location_id -- Facility or branch identifier
FROM stg_encounter_discharge_summary;