-- =================================================================================
-- Intermediate Fact Table: Referrals
-- Name: int_fct_referrals
-- Source Tables: stg_encounter_patient_order
-- Purpose: Transform patient orders into referral metrics for downstream analysis
-- Key Transformations:
--   • Map order_date to referral_date for consistent date-based joining
--   • Map order_id to referral_id for entity identification
--   • Include location_id for proper location-based analysis
--   • Map order_type to referral_status to identify pending/active referrals
-- Usage:
--   • Feed into finance.fct_referrals for aggregated referral analysis 
--   • Support calculation of "Referrals" KPI metric, particularly pending referrals
-- Grain: One row per patient referral event
-- =================================================================================

SELECT 
    order_date AS referral_date,     -- Map date field for consistent date dimension joining
    order_id AS referral_id,         -- Map ID field for entity tracking
    location_id,                     -- Facility identifier for location dimension joining
    order_type AS referral_status    -- Map type field for referral status analysis
FROM stg_encounter_patient_order;    -- Source staging table