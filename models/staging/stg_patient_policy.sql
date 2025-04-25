-- =================================================================================
-- 8. Patient Policy View
-- Name: patient_policy
-- Source Tables: OLTP_DB.Patient.PatientPolicy
-- Purpose: Capture patient insurance coverage information.
-- Key Transformations:
--   • Rename primary key to `patient_policy_id`.
-- Usage:
--   • Determine payer mix and patient liability for revenue recognition.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.patient_policy AS
SELECT
  Id       AS patient_policy_id,
  Patient_Id AS patient_id,
  Carrier_Id AS carrier_id
FROM OLTP_DB.Patient.PatientPolicy;