-- =================================================================================
-- 9. Party View
-- Name: party
-- Source Tables: OLTP_DB.Common.Party
-- Purpose: Core party entity information.
-- Key Transformations:
--   • Rename primary key to `party_id`.
--   • Expose proper party attributes from data dictionary.
-- Usage:
--   • Join to other entities for master data.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.party AS
SELECT
  Id                     AS party_id,
  PartyType_Id           AS party_type_id,
  TaxIdentifier          AS tax_identifier,
  Notes                  AS notes,
  PrimaryContact_Id      AS primary_contact_id,
  IsActive               AS is_active,
  CreatedBy              AS created_by,
  CreatedDate            AS created_date,
  ModifiedBy             AS modified_by,
  ModifiedDate           AS modified_date,
  RecStatus              AS record_status
FROM OLTP_DB.Common.Party
WHERE RecStatus = 1;