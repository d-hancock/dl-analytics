-- =================================================================================
-- 4. Consolidated Facility Dimension View
-- Name: facility_dimension
-- Source Tables: OLTP_DB.Common.CompanyLocation, OLTP_DB.Common.Address
-- Purpose: Flatten physical locations with address details.
-- Key Transformations:
--   • Rename primary keys to `facility_id` and `company_id`.
--   • Add boolean flag for active status.
-- Usage:
--   • Join to inventory and billing data for location-based reporting.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.facility_dimension AS
SELECT
  cl.CompanyLocationKey    AS facility_id,
  cl.CompanyKey            AS company_id,
  cl.LocationCode          AS facility_code,
  cl.LocationName          AS facility_name,
  a.AddressLine1           AS address_line1,
  a.City                   AS city,
  a.State                  AS state,
  a.ZipCode                AS zip_code,
  CASE WHEN cl.IsActive = 'Y' THEN TRUE ELSE FALSE END AS is_active
FROM OLTP_DB.Common.CompanyLocation cl
LEFT JOIN OLTP_DB.Common.Address a
  ON cl.AddressKey = a.AddressKey;