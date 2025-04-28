-- =================================================================================
-- Staging Layer: Insurance Carrier
-- Name: stg_insurance_carrier
-- Source Tables: OLTP_DB.Insurance.Carrier
-- Purpose: 
--   Extract insurance carrier/payer details for financial analysis.
-- Key Transformations:
--   • Rename primary key to `carrier_id`
--   • Extract relevant carrier attributes
-- Usage:
--   • Source for payer dimension
--   • Enables analysis by payer category
--   • Supports the dimensional requirements in the dashboard
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.insurance_carrier AS
SELECT
  Id                    AS carrier_id,
  CarrierName           AS carrier_name,
  CarrierType_Id        AS carrier_type_id,
  PayorType_Id          AS payor_type_id,
  IsActive              AS is_active,
  Address_Id            AS address_id,
  SubmitterID           AS submitter_id,
  ReceiverId            AS receiver_id,
  CreatedBy             AS created_by,
  CreatedDate           AS created_date,
  ModifiedBy            AS modified_by,
  ModifiedDate          AS modified_date,
  RecStatus             AS record_status
FROM OLTP_DB.Insurance.Carrier
WHERE RecStatus = 1;