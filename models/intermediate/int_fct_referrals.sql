-- Intermediate Fact Table: Referrals
-- Joins and derives metrics related to referrals
-- Each row represents a unique referral event

SELECT 
    referral_date, -- Date of the referral
    referral_id, -- Unique identifier for the referral
    referral_status -- Status of the referral
FROM stg_encounter_patient_order;