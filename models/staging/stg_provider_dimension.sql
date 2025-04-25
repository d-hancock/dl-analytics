-- =================================================================================
-- 3. Provider Dimension View
-- Name: provider_dimension
-- Source Tables: OLTP_DB.Provider.Provider
-- Purpose: Provider information for analysis.
-- Key Transformations:
--   • Rename primary key to `provider_id`.
--   • Expose provider attributes.
-- Usage:
--   • Join to claims, orders, and encounters for provider-level metrics.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.provider_dimension AS
SELECT
  p.Id                AS provider_id,
  p.ProviderName      AS provider_name,
  p.NPI               AS provider_npi,
  p.IsActive          AS is_active,
  p.ProviderType_Id   AS provider_type_id
FROM OLTP_DB.Provider.Provider p;