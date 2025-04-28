-- =================================================================================
-- Staging Layer: Therapy Type Lookup
-- Name: stg_lookups_therapy_type
-- Source Tables: OLTP_DB.Lookups.TherapyType
-- Purpose: 
--   Extract therapy type information to support therapy dimension for analysis.
-- Key Transformations:
--   • Rename primary key to `therapy_type_id`
--   • Extract relevant therapy type attributes
-- Usage:
--   • Source for therapy type dimension
--   • Enables analytics across therapy types
--   • Required dimensional support per analytics requirements
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.lookups_therapy_type AS
SELECT
  Id                    AS therapy_type_id,
  Name                  AS therapy_type_name,
  Description           AS therapy_type_description,
  IsActive              AS is_active,
  SortOrder             AS sort_order,
  CreatedBy             AS created_by,
  CreatedDate           AS created_date,
  ModifiedBy            AS modified_by,
  ModifiedDate          AS modified_date,
  RecStatus             AS record_status
FROM OLTP_DB.Lookups.TherapyType
WHERE RecStatus = 1;