-- =================================================================================
-- Patient Encounter View
-- Name: encounter_patient_encounter
-- Source Tables: OLTP_DB.Encounter.PatientEncounter
-- Purpose: Extract patient encounter data
-- Key Transformations:
--   • Rename columns to use standard naming conventions
--   • Filter for active records only
-- Usage:
--   • Track patient encounters for clinical and operational analysis
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.encounter_patient_encounter AS
SELECT 
    Id                   AS encounter_id,
    Patient_Id           AS patient_id,
    StartDate            AS start_date,
    EndDate              AS end_date,
    CreatedBy            AS created_by,
    CreatedDate          AS created_date,
    ModifiedBy           AS modified_by,
    ModifiedDate         AS modified_date,
    RecStatus            AS record_status
FROM OLTP_DB.Encounter.PatientEncounter
WHERE RecStatus = 1;