-- =================================================================================
-- 15. Encounter Patient Order View
-- Name: encounter_patient_order
-- Source Tables: CareTend_OC.Encounter.PatientOrder
-- Purpose: Represent raw patient orders used to identify referrals and first starts.
-- Key Transformations:
--   • Rename primary key to `order_id`.
--   • Expose order type for downstream reporting.
-- Usage:
--   • Analyze patient orders for referral and new-start metrics.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.encounter_patient_order AS
SELECT
  OrderID               AS order_id,
  OrderType             AS order_type
FROM CareTend_OC.Encounter.PatientOrder;