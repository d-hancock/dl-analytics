-- KPI: Referrals
-- Provides the count of referrals within a given period
-- Each row represents a unique combination of calendar date and referral ID

SELECT 
    calendar_date, -- Day-level date
    referral_id, -- Unique identifier for the referral
    COUNT(*) AS total_referrals -- Total number of referrals
FROM fct_referrals
GROUP BY calendar_date, referral_id;