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
  Id                   AS patient_policy_id,
  Patient_Id           AS patient_id,
  Carrier_Id           AS carrier_id,
  PolicyNumber         AS policy_number,
  GroupNumber          AS group_number,
  InsuranceSequence_Id AS insurance_sequence_id,
  PolicyHolder_Id      AS policy_holder_id,
  RelationshipType_Id  AS relationship_type_id,
  EffectiveDate        AS effective_date,
  TerminationDate      AS termination_date,
  IsVerified           AS is_verified,
  LastVerifiedDate     AS last_verified_date,
  VerificationMethod_Id AS verification_method_id,
  CoverageType_Id      AS coverage_type_id,
  InsuranceCardDate    AS insurance_card_date,
  CreatedBy            AS created_by,
  CreatedDate          AS created_date,
  ModifiedBy           AS modified_by,
  ModifiedDate         AS modified_date,
  RecStatus            AS record_status
FROM OLTP_DB.Patient.PatientPolicy
WHERE RecStatus = 1;