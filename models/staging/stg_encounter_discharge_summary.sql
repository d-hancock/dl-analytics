-- Staging Table: Encounter Discharge Summary
-- Cleans and casts discharge summary data from Encounter.DischargeSummary for downstream use
-- Maps OLTP DB fields to analytics naming conventions

CREATE OR REPLACE VIEW DEV_DB.stg.encounter_discharge_summary AS
SELECT 
    Id                          AS discharge_id,
    PatientEncounter_Id         AS patient_encounter_id,
    DischargeDate               AS discharge_date,
    DischargeStatus_Id          AS discharge_status_id,
    PatientStatus_Id            AS patient_status_id,
    DischargeReason_Id          AS discharge_reason_id,
    DischargeAcuity_Id          AS discharge_acuity_id,
    -- Added columns based on source documentation
    CopyMD                      AS copy_md_flag,
    CarePlanReviewDate          AS care_plan_review_date,
    DischargeInstructionsGiven  AS discharge_instructions_given_flag,
    CreatedBy                   AS created_by, -- Added missing column
    CreatedDate                 AS created_date,
    ModifiedBy                  AS modified_by, -- Added missing column
    ModifiedDate                AS modified_date,
    RecStatus                   AS record_status
FROM OLTP_DB.Encounter.DischargeSummary
WHERE RecStatus = 1;