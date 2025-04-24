-- =================================================================================
-- Intermediate Fact Table: Discharges
-- Name: int_fct_discharges
-- Source Tables: stg_encounter_discharge_summary
-- Purpose: Consolidate patient discharge data for patient activity analysis
-- Key Transformations:
--   • Retain discharge_date for period assignment in marts
--   • Retain patient_id for patient-specific discharge metrics
--   • Include location_id for facility-level discharge analysis
-- Usage:
--   • Feed into finance.fct_discharges for aggregated discharge metrics
--   • Support calculation of "Discharged Patients" KPI metric
-- Grain: One row per patient discharge event
-- Business Rules:
--   • A discharge is counted on the date it occurred
--   • Each patient may have multiple discharges over time
-- =================================================================================

SELECT 
    discharge_date,     -- Date of discharge (for date dimension joins)
    patient_id,         -- Patient identifier (for patient dimension joins)
    location_id         -- Facility identifier (for location dimension joins)
FROM stg_encounter_discharge_summary; -- Source staging table