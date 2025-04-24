-- =================================================================================
-- 13. Encounter Patient Encounter View
-- Name: encounter_patient_encounter
-- Source Tables: CareTend_OC.Encounter.PatientEncounter
-- Purpose: Represent raw encounter events for discharge and new-start metrics.
-- Key Transformations:
--   • Rename primary key to `encounter_id`.
--   • Expose encounter type for downstream reporting.
-- Usage:
--   • Analyze patient encounters for operational metrics.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.encounter_patient_encounter AS
SELECT
  EncounterID           AS encounter_id,
  EncounterType         AS encounter_type
FROM CareTend_OC.Encounter.PatientEncounter;