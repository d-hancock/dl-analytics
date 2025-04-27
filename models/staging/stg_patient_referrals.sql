-- =================================================================================
-- Patient Referrals View
-- Name: stg_patient_referrals
-- Source Tables: OLTP_DB.Patient.PatientReferrals
-- Purpose: Extract patient referral information
-- Key Transformations:
--   • Rename columns to use standard naming conventions
--   • Filter for active records only
-- Usage:
--   • Track referral sources and status for patient acquisition analysis
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.patient_referrals AS
SELECT
    Id                        AS referral_id,
    Patient_Id                AS patient_id,
    ReferralSource_Id         AS referral_source_id,
    ReferralRequest           AS referral_request,
    ReferralDate              AS referral_date,
    ReferralResponseDate      AS response_date,
    ResponseStatus_Id         AS response_status_id,
    ProviderType_Id           AS provider_type_id,
    Provider_Id               AS provider_id,
    DiagnosisCode_Id          AS diagnosis_code_id,
    Notes                     AS notes,
    CreatedBy                 AS created_by,
    CreatedDate               AS created_date,
    ModifiedBy                AS modified_by,
    ModifiedDate              AS modified_date,
    RecStatus                 AS record_status
FROM OLTP_DB.Patient.PatientReferrals
WHERE RecStatus = 1;