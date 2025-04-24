-- =================================================================================
-- Intermediate Provider Dimension View
-- Name: int_provider_dimension
-- Source Tables: OLTP_DB.Provider.Provider, OLTP_DB.Common.Party
-- Purpose: Flatten provider demographic and associated information.
-- Key Transformations:
--   	• Rename primary keys to `provider_id` and `party_id`.
--   	• Cast relevant dates to DATE for consistency.
--   	• Include provider specialty and status information.
-- Usage:
--   	• Join to claims, invoices, and encounters for provider-level KPIs.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.provider_dimension AS
SELECT
  p.ProviderKey          AS provider_id,
  pr.PartyKey            AS party_id,
  pr.FirstName           AS first_name,
  pr.LastName            AS last_name,
  p.NPI                  AS npi_number,
  p.SpecialtyCode        AS specialty,
  CASE WHEN p.IsActive = 'Y' THEN TRUE ELSE FALSE END AS is_active
FROM OLTP_DB.Provider.Provider p
JOIN OLTP_DB.Common.Party pr
  ON p.PartyKey = pr.PartyKey;