-- =================================================================================
-- Intermediate Fact Table: New Patient Starts
-- Name: int_fct_new_starts
-- Source Tables: stg.patient_dimension, stg.patient_orders
-- Purpose: Track new patient start events for patient acquisition analysis
-- Key Transformations:
--   • Use patient referral date or first order date as start date
--   • Include patient attributes for analysis
-- Usage:
--   • Feed into finance.fct_new_starts for aggregated patient start metrics
--   • Support calculation of "New Starts" KPI
-- Grain: One row per new patient start event
-- Business Rules:
--   • A patient is counted as a new start based on their referral date
--   • Only active patients are considered new starts in downstream calculations
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.fct_new_starts AS
SELECT 
    p.patient_id,
    p.medical_record_number,
    p.referral_date AS start_date,
    p.team_id,
    po.therapy_type_id,
    MIN(po.ordered_date) AS first_order_date
FROM DEV_DB.stg.patient_dimension p
LEFT JOIN DEV_DB.stg.patient_orders po ON p.patient_id = po.patient_id
WHERE p.record_status = 1
GROUP BY 
    p.patient_id,
    p.medical_record_number,
    p.referral_date,
    p.team_id,
    po.therapy_type_id;