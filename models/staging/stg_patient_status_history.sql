-- =================================================================================
-- Staging Layer: Patient Status History
-- Name: stg_patient_status_history
-- Source Tables: OLTP_DB.Patient.PatientStatusHistory
-- Purpose: 
--   Extract patient status change events for tracking referrals, starts,
--   and discharged patients as required by analytics requirements.
-- Key Transformations:
--   • Rename primary key to `patient_status_history_id`
--   • Extract relevant status change attributes
-- Usage:
--   • Source for patient activity metrics
--   • Feeds into finance.fct_patient_activity fact table
--   • Essential for referral-to-start conversion rate calculations
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.patient_status_history AS
SELECT
  Id                    AS patient_status_history_id,
  Patient_Id            AS patient_id,
  -- Replaced FromStatus_Id and ToStatus_Id with Status_Id based on source documentation
  Status_Id             AS status_id, 
  EffectiveDate         AS effective_date,
  -- Replaced Comment with Notes based on source documentation
  Notes                 AS status_change_notes, 
  CreatedBy             AS created_by,
  CreatedDate           AS created_date,
  ModifiedBy            AS modified_by,
  ModifiedDate          AS modified_date,
  RecStatus             AS record_status
FROM OLTP_DB.Patient.PatientStatusHistory
WHERE RecStatus = 1;