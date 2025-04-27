-- =================================================================================
-- 15. Encounter Patient Order View
-- Name: encounter_patient_order
-- Source Tables: OLTP_DB.Prescription.PatientOrder
-- Purpose: Represent raw patient orders used to identify referrals and first starts.
-- Key Transformations:
--   • Rename primary key to `order_id`.
--   • Expose order type for downstream reporting.
-- Usage:
--   • Analyze patient orders for referral and new-start metrics.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.encounter_patient_order AS
SELECT
  Id                       AS order_id,
  Patient_Id               AS patient_id,
  TherapyType_Id           AS therapy_type_id,
  PatientOrderStatus_Id    AS order_status_id,
  OrderedDate              AS ordered_date,
  StartDate                AS start_date,
  StopDate                 AS stop_date,
  DiscontinuedDate         AS discontinued_date,
  Provider_Id              AS provider_id,
  OrderSource_Id           AS order_source_id,
  PatientEncounter_Id      AS patient_encounter_id
FROM OLTP_DB.Prescription.PatientOrder
WHERE Record_Status_Id = 1;