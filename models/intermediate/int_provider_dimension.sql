-- =================================================================================
-- Intermediate Provider Dimension View
-- Name: int_provider_dimension
-- Source Tables: stg.provider_dimension
-- Purpose: Prepare provider information for analytics views.
-- Key Transformations:
--   • Use refactored staging views with corrected schema references
-- Usage:
--   • Join to claims, invoices, and encounters for provider-level KPIs.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.provider_dimension AS
SELECT
  p.provider_id,
  p.provider_name,
  p.provider_npi AS npi_number,
  p.is_active,
  p.provider_type_id,
  p.specialty_one_id,
  p.specialty_two_id,
  p.tax_id,
  p.upin,
  p.state_license_number,
  p.created_date,
  p.modified_date,
  p.record_status
FROM DEV_DB.stg.provider_dimension p
WHERE p.record_status = 1;