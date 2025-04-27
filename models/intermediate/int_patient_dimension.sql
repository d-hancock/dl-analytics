-- =================================================================================
-- Intermediate Patient Dimension View
-- Name: int_patient_dimension
-- Source Tables: stg.patient_dimension, stg.patient_policy, stg.payer_dimension
-- Purpose: Flatten patient demographic and primary policy lookup.
-- Key Transformations:
--   • Use refactored staging views with corrected schema references
--   • Join to payer dimension for insurance information
-- Usage:
--   • Join to claims, invoices, and encounters for patient-level KPIs.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.patient_dimension AS
SELECT
  p.patient_id,
  p.medical_record_number,
  p.birth_date,
  p.referral_date,
  p.gender_id,
  p.date_of_death,
  p.team_id,
  p.insurance_coordinator_id,
  p.advance_directives,
  p.record_status,
  pp.patient_policy_id,
  pp.carrier_id,
  pd.payer_name AS primary_insurance_name
FROM DEV_DB.stg.patient_dimension p
LEFT JOIN DEV_DB.stg.patient_policy pp
  ON p.patient_id = pp.patient_id
  AND pp.record_status = 1
  AND pp.insurance_sequence_id = 1 -- Primary insurance
LEFT JOIN DEV_DB.stg.payer_dimension pd
  ON pp.carrier_id = pd.payer_id
  AND pd.record_status = 1
WHERE p.record_status = 1;