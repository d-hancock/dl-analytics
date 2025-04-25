-- =================================================================================
-- Intermediate Fact Table: Referrals
-- Name: int_fct_referrals
-- Source Tables: stg.patient_referrals
-- Purpose: Transform patient referrals into metrics for downstream analysis
-- Key Transformations:
--   • Use correct patient_referrals table instead of patient_order
--   • Include proper referral attributes for analysis
-- Usage:
--   • Feed into finance.fct_referrals for aggregated referral analysis 
--   • Support calculation of "Referrals" KPI metric
-- Grain: One row per patient referral event
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.fct_referrals AS
SELECT 
    pr.referral_id,
    pr.patient_id,
    pr.referral_date,
    pr.referral_source_id,
    pr.response_date,
    pr.response_status_id,
    p.team_id,
    DATEDIFF(day, pr.referral_date, pr.response_date) AS days_to_response
FROM DEV_DB.stg.patient_referrals pr
JOIN DEV_DB.stg.patient_dimension p ON pr.patient_id = p.patient_id
WHERE pr.record_status = 1;