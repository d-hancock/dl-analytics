-- =================================================================================
-- Patient Orders View
-- Name: stg_patient_orders
-- Source Tables: OLTP_DB.Prescription.PatientOrder
-- Purpose: Extract patient therapy orders
-- Key Transformations:
--   • Rename columns to use standard naming conventions
--   • Filter for active records only
-- Usage:
--   • Track therapy orders and status for clinical analysis
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.patient_orders AS
SELECT
    Id                        AS order_id,
    Patient_Id                AS patient_id,
    TherapyType_Id            AS therapy_type_id,
    PatientOrderStatus_Id     AS order_status_id,
    OrderedDate               AS ordered_date,
    StartDate                 AS start_date,
    StopDate                  AS stop_date,
    DiscontinuedDate          AS discontinued_date,
    InventoryItem_Id          AS inventory_item_id,
    InventoryItemType_Id      AS inventory_item_type_id,
    Provider_Id               AS provider_id,
    Record_Status_Id          AS record_status
FROM OLTP_DB.Prescription.PatientOrder
WHERE Record_Status_Id = 1;