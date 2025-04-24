-- =================================================================================
-- 8. Patient Policy View
-- Name: patient_policy
-- Source Tables: OLTP_DB.Patient.PatientPolicy
-- Purpose: Capture patient insurance coverage over time.
-- Key Transformations:
--   • Rename primary key to `patient_policy_id`.
--   • Expose coverage type for downstream payer mix analysis.
-- Usage:
--   • Determine payer mix and patient liability for revenue recognition.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.patient_policy AS
SELECT
  PatientPolicyKey       AS patient_policy_id,
  CoverageTypeCode       AS coverage_type
FROM OLTP_DB.Patient.PatientPolicy;