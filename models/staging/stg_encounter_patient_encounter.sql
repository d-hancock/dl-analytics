-- Staging Table: Patient Encounter
-- Cleans and casts raw patient encounter data for downstream use
-- One-to-one mapping with the source table

SELECT 
    encounter_id, -- Unique identifier for the encounter
    patient_id, -- Unique identifier for the patient
    encounter_date, -- Date of the encounter
    encounter_type -- Type of the encounter
FROM raw_patient_encounter;