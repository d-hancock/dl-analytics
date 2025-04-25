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
    CreatedDate               AS created_date,
    ModifiedDate              AS modified_date,
    RecStatus                 AS record_status
FROM OLTP_DB.Patient.PatientReferrals
WHERE RecStatus = 1;