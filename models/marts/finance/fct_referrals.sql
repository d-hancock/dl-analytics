-- Summable grain-level fact table for referrals
-- Provides referral-related metrics for aggregation and slicing
-- Each row represents a unique combination of referral date and referral ID

SELECT 
    referral_date, -- Date of the referral
    referral_id, -- Unique identifier for the referral
    COUNT(*) AS referral_count -- Total number of referrals
FROM int_fct_referrals
GROUP BY referral_date, referral_id;