-- Staging Table: Encounter Discharge Summary
-- Cleans and casts discharge summary data from Encounter.DischargeSummary for downstream use
-- Maps OLTP DB fields to analytics naming conventions

CREATE OR REPLACE VIEW DEV_DB.stg.encounter_discharge_summary AS
SELECT 
    Id as discharge_id, -- Unique identifier for the discharge event
    PatientEncounter_Id as patient_encounter_id, -- Unique identifier for the patient encounter (renamed to match downstream)
    DischargeDate as discharge_date, -- Date of discharge
    DischargeStatus_Id as discharge_status_id, -- Status of the discharge (renamed to match downstream)
    PatientStatus_Id as patient_status_id, -- Status of the patient at discharge (renamed to match downstream)
    DischargeReason_Id as discharge_reason_id, -- Reason for discharge (renamed to match downstream)
    DischargeAcuity_Id as discharge_acuity_id, -- Acuity level at discharge (renamed to match downstream)
    CreatedDate as created_date, -- Record creation timestamp
    ModifiedDate as modified_date, -- Record modification timestamp
    RecStatus as record_status -- Record status flag (renamed to match downstream)
FROM OLTP_DB.Encounter.DischargeSummary
WHERE RecStatus = 1;