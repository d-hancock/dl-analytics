-- =================================================================================
-- 14. Encounter Discharge Summary View
-- Name: encounter_discharge_summary
-- Source Tables: CareTend_OC.Encounter.DischargeSummary
-- Purpose: Summarize discharge records, capturing final outcomes by encounter.
-- Key Transformations:
--   • Rename primary key to `discharge_summary_id`.
--   • Expose discharge reason for downstream reporting.
-- Usage:
--   • Analyze discharge outcomes for operational and clinical metrics.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.encounter_discharge_summary AS
SELECT
  SummaryID             AS discharge_summary_id,
  DischargeReason       AS discharge_reason
FROM CareTend_OC.Encounter.DischargeSummary;