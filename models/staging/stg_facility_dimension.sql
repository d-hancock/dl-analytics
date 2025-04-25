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
  cl.CompanyLocation_Id    AS facility_id,
  cl.Company_Id            AS company_id,
  cl.Location_Id           AS location_id,
  cl.Location_Name         AS facility_name
FROM OLTP_DB.Common.CompanyLocation cl;