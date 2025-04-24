-- Staging Table: Encounter Discharge Summary
-- Cleans and casts raw discharge summary data for downstream use
-- One-to-one mapping with the source table

SELECT 
    discharge_id, -- Unique identifier for the discharge event
    patient_id, -- Unique identifier for the patient
    discharge_date, -- Date of discharge
    discharge_status -- Status of the discharge
FROM raw_encounter_discharge_summary;