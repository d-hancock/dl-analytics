-- =================================================================================
-- Discharge Summary View 
-- Name: stg_discharge_summary
-- Source Tables: OLTP_DB.Encounter.DischargeSummary
-- Purpose: Extract discharge information for clinical analysis
-- Key Transformations:
--   • Rename columns to use standard naming conventions
--   • Filter for active records only
-- Usage:
--   • Track discharge outcomes for clinical quality metrics
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.discharge_summary AS
SELECT 
    Id                   AS discharge_id,
    PatientEncounter_Id  AS patient_encounter_id,
    DischargeDate        AS discharge_date,
    DischargeStatus_Id   AS discharge_status_id,
    PatientStatus_Id     AS patient_status_id,
    DischargeReason_Id   AS discharge_reason_id,
    DischargeAcuity_Id   AS discharge_acuity_id,
    CreatedBy            AS created_by,
    CreatedDate          AS created_date,
    ModifiedBy           AS modified_by,
    ModifiedDate         AS modified_date,
    RecStatus            AS record_status
FROM OLTP_DB.Encounter.DischargeSummary
WHERE RecStatus = 1;