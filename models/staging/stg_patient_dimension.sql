-- =================================================================================
-- 2. Consolidated Patient Dimension View
-- Name: patient_dimension
-- Source Tables: OLTP_DB.Patient.Patient
-- Purpose: Flatten patient demographic data.
-- Key Transformations:
--   • Rename primary key to `patient_id`.
--   • Cast date fields to DATE for consistency.
--   • Expose relevant patient attributes.
-- Usage:
--   • Join to claims, invoices, and encounters for patient-level KPIs.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.patient_dimension AS
SELECT
  p.Id                     AS patient_id,
  p.MedicalRecordNo        AS medical_record_number,
  p.DateOfBirth            AS birth_date,
  p.Gender_Id              AS gender_id,
  p.ReferralDate           AS referral_date,
  p.PrimaryRN_Id           AS primary_rn_id,
  p.CodeStatus_Id          AS code_status_id,
  p.PatientDateOfDeath     AS date_of_death,
  p.Team_Id                AS team_id,
  p.InsuranceCoordinator_Id AS insurance_coordinator_id,
  p.AdvanceDirectives      AS advance_directives,
  p.InformationComplete    AS information_complete,
  p.Person_Id              AS person_id,
  p.PatientStatus_Id       AS patient_status_id,
  p.MaritalStatus_Id       AS marital_status_id,
  p.Language_Id            AS language_id,
  p.IsReferable            AS is_referable,
  p.CreatedBy              AS created_by,
  p.CreatedDate            AS created_date,
  p.ModifiedBy             AS modified_by,
  p.ModifiedDate           AS modified_date,
  p.RecStatus              AS record_status
FROM OLTP_DB.Patient.Patient p
WHERE p.RecStatus = 1;