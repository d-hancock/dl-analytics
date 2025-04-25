-- =================================================================================
-- Intermediate Payer Dimension View
-- Name: int_payer_dimension
-- Source Tables: stg.payer_dimension
-- Purpose: Normalize payer lookup for revenue and claims analysis.
-- Key Transformations:
--   • Use refactored staging views with corrected schema references
--   • Standardize payer attributes for reporting
-- Usage:
--   • Join to claims and invoices for payer-level revenue analysis.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.payer_dimension AS
SELECT
  pd.payer_id,
  pd.payer_name,
  pd.carrier_type_id,
  pd.payor_type_id,
  pd.identifier,
  pd.use_medicare_rules,
  pd.is_supplementary,
  pd.is_always_billed_for_denial,
  pd.is_medicare_cba_provider
FROM DEV_DB.stg.payer_dimension pd;