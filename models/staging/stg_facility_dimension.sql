-- =================================================================================
-- 4. Consolidated Facility Dimension View
-- Name: facility_dimension
-- Source Tables: OLTP_DB.Common.CompanyLocation
-- Purpose: Flatten company locations for facility analysis.
-- Key Transformations:
--   • Rename keys to meaningful column names.
-- Usage:
--   • Join to inventory and billing data for location-based reporting.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.facility_dimension AS
SELECT
  cl.Id                  AS facility_id,
  cl.Company_Id          AS company_id,
  cl.Location_Id         AS location_id,
  cl.Name                AS facility_name,
  cl.IsActive            AS is_active,
  cl.Address_Id          AS address_id,
  cl.PhoneNumber_Id      AS phone_number_id,
  cl.CreatedBy           AS created_by,
  cl.CreatedDate         AS created_date,
  cl.ModifiedBy          AS modified_by,
  cl.ModifiedDate        AS modified_date,
  cl.RecStatus           AS record_status
FROM OLTP_DB.Common.CompanyLocation cl
WHERE cl.RecStatus = 1;