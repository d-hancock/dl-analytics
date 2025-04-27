-- =================================================================================
-- Intermediate Fact Table: Discharges
-- Name: int_fct_discharges
-- Source Tables: stg.discharge_summary, stg.patient_dimension
-- Purpose: Consolidate patient discharge data for patient activity analysis
-- Key Transformations:
--   • Join with patient_dimension to get patient team information
--   • Include discharge status and reason information
-- Usage:
--   • Feed into finance.fct_discharges for aggregated discharge metrics
--   • Support calculation of "Discharged Patients" KPI metric
-- Grain: One row per patient discharge event
-- Business Rules:
--   • A discharge is counted on the date it occurred
--   • Each patient may have multiple discharges over time
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.fct_discharges AS
SELECT 
    ds.discharge_id,
    ds.patient_encounter_id,
    ds.discharge_date,
    ds.discharge_status_id,
    ds.patient_status_id,
    ds.discharge_reason_id,
    ds.discharge_acuity_id,
    p.patient_id,
    p.team_id
FROM DEV_DB.stg.discharge_summary ds
JOIN DEV_DB.stg.patient_dimension p
    ON ds.patient_encounter_id IN (
        SELECT pe.encounter_id 
        FROM DEV_DB.stg.encounter_patient_encounter pe 
        WHERE pe.patient_id = p.patient_id
        AND pe.record_status = 1
    )
WHERE ds.record_status = 1
AND p.record_status = 1;