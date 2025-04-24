-- =================================================================================
-- Intermediate Fact Table: New Patient Starts
-- Name: int_fct_new_starts
-- Source Tables: stg_encounter_patient_encounter
-- Purpose: Track new patient start events for patient acquisition analysis
-- Key Transformations:
--   • Map encounter_date to start_date for consistent naming
--   • Include patient_id for patient-level analysis and deduplication
--   • Include location_id for facility-level patient acquisition metrics
-- Usage:
--   • Feed into finance.fct_new_starts for aggregated patient start metrics
--   • Support calculation of "New Starts" KPI (unique MRNs with Active status, 365-day lookback)
-- Grain: One row per new patient start event
-- Business Rules:
--   • A patient is counted as a new start on their first encounter date
--   • Only active patients are considered new starts in downstream calculations
-- =================================================================================

SELECT 
    encounter_date AS start_date,  -- Date of the patient's first encounter
    patient_id,                    -- Patient identifier for deduplication and dimension joining
    location_id                    -- Facility identifier for location-based analysis
FROM stg_encounter_patient_encounter; -- Source staging table