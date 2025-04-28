-- =================================================================================
-- 8. Patient Policy View
-- Name: patient_policy
-- Source Tables: OLTP_DB.Patient.PatientPolicy
-- Purpose: Capture patient insurance coverage information.
-- Key Transformations:
--   • Rename primary key to `patient_policy_id`.
--   • Map fields according to the source schema documented in the CareTend Data Dictionary.
-- Usage:
--   • Determine payer mix and patient liability for revenue recognition.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.patient_policy AS
SELECT
  Id                              AS patient_policy_id,
  Patient_Id                      AS patient_id,
  Carrier_Id                      AS carrier_id,
  PolicyOwner_Id                  AS policy_owner_id,    -- Corrected from PolicyHolder_Id
  PolicyNumber                    AS policy_number,
  GroupNumber                     AS group_number,
  InsuredIDNumber                 AS insured_id_number,  -- Added from source
  PolicyStatus_Id                 AS policy_status_id,   -- Added from source
  Employer_Id                     AS employer_id,        -- Added from source
  PolicyContact_Id                AS policy_contact_id,  -- Added from source
  InsuranceProgram_Id             AS insurance_program_id, -- Added from source
  PatientRelationToInsured_Id     AS patient_relation_to_insured_id, -- Corrected from RelationshipType_Id
  Sequence                        AS insurance_sequence, -- Changed from InsuranceSequence_Id to match source
  SecondaryPatientPolicy_Id       AS secondary_patient_policy_id, -- Added from source
  EffectiveDate                   AS effective_date,
  ExpirationDate                  AS expiration_date,    -- Corrected from TerminationDate
  MedicareSecondaryProviderType_Id AS medicare_secondary_provider_type_id, -- Added from source
  SignatureSource_Id              AS signature_source_id, -- Added from source
  ReleaseofInformation_Id         AS release_of_information_id, -- Added from source
  IsBilledForDenial               AS is_billed_for_denial, -- Added from source
  CreatedBy                       AS created_by,
  CreatedDate                     AS created_date,
  ModifiedBy                      AS modified_by,
  ModifiedDate                    AS modified_date,
  RecStatus                       AS record_status
FROM OLTP_DB.Patient.PatientPolicy
WHERE RecStatus = 1;