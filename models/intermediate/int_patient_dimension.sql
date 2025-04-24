-- =================================================================================
-- Intermediate Patient Dimension View
-- Name: int_patient_dimension
-- Source Tables: OLTP_DB.Patient.Patient, OLTP_DB.Common.Party, OLTP_DB.Patient.PatientPolicy
-- Purpose: Flatten patient demographic and primary policy lookup.
-- Key Transformations:
--   	• Rename primary keys to `patient_id` and `party_id`.
--   	• Cast `BirthDate` to DATE for consistency.
--   	• Join patient policies to expose primary insurance policy.
-- Usage:
--   	• Join to claims, invoices, and encounters for patient-level KPIs.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.patient_dimension AS
SELECT
  p.PatientKey           AS patient_id,
  pr.PartyKey            AS party_id,
  pr.FirstName           AS first_name,
  pr.LastName            AS last_name,
  CAST(p.BirthDate AS DATE)        AS birth_date,
  pr.GenderCode          AS gender,
  p.Status               AS status,
  pol.PolicyKey          AS primary_insurance_policy_id
FROM OLTP_DB.Patient.Patient p
JOIN OLTP_DB.Common.Party pr
  ON p.PartyKey = pr.PartyKey
LEFT JOIN OLTP_DB.Patient.PatientPolicy pol
  ON p.PatientKey = pol.PatientKey
 AND pol.IsPrimary = 1;