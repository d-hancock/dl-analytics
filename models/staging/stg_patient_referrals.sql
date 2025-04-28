-- =================================================================================
-- Patient Referrals View
-- Name: stg_patient_referrals
-- Source Tables: OLTP_DB.Patient.PatientReferrals
-- Purpose: Extract supplementary patient referral details based on documented source table.
-- Key Transformations:
--   • Rename columns to use standard naming conventions.
--   • Map documented source columns.
-- Usage:
--   • Provide source data for referral analysis (supplementary details).
-- Note: This table does not contain referral status or dates needed for KPI tracking.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.patient_referrals AS
SELECT
    Id                          AS referral_id,
    -- Columns present in source table documentation:
    PhysicianFirstName          AS physician_first_name,
    PhysicianLastName           AS physician_last_name,
    PhysicianPhoneNumber        AS physician_phone_number,
    InsuranceCompany            AS insurance_company,
    InsurancePhoneNumber        AS insurance_phone_number,
    InsurancePolicyOwner        AS insurance_policy_owner,
    InsurancePolicyNumber       AS insurance_policy_number,
    InsurancePolicyGroupNumber  AS insurance_policy_group_number,
    ReferralNotes               AS referral_notes,
    MedicalHistory              AS medical_history,
    DiagnosisCode1Description   AS diagnosis_code_1_description,
    DiagnosisCode2Description   AS diagnosis_code_2_description,
    ReferralRequest             AS referral_request
    -- Columns NOT present in source table documentation (removed):
    -- Patient_Id, ReferralSource_Id, ReferralDate, ReferralResponseDate,
    -- ResponseStatus_Id, ProviderType_Id, Provider_Id, DiagnosisCode_Id,
    -- Notes, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate, RecStatus
FROM OLTP_DB.Patient.PatientReferrals;
-- WHERE RecStatus = 1; -- Removed as RecStatus is not in the documented source table