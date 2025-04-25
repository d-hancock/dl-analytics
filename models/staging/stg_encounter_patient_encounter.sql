-- Staging Table: Patient Encounter
-- Maps patient encounter data from OLTP Patient.PatientReferrals table
-- Based on schema_mapping_before_after.md which shows the correct mapping from Encounter.PatientEncounter to Patient.PatientReferrals

SELECT 
    Id as encounter_id, -- Unique identifier for the encounter/referral
    Patient_Id as patient_id, -- Unique identifier for the patient
    ReferralDate as encounter_date, -- Date of the referral (equivalent to encounter date)
    ReferralSource_Id as encounter_type -- Source of the referral (used as encounter type)
FROM Patient.PatientReferrals
WHERE RecStatus = 1; -- Only include active records