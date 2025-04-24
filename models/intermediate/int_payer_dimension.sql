-- =================================================================================
-- Intermediate Payer Dimension View
-- Name: int_payer_dimension
-- Source Tables: OLTP_DB.Insurance.Carrier
-- Purpose: Normalize payer lookup for revenue and claims analysis.
-- Key Transformations:
--   	• Rename primary key to `payer_id`.
--   	• Add boolean flag for active status.
--   	• Include effective and termination dates for coverage tracking.
-- Usage:
--   	• Join to claims and invoices for payer-level revenue analysis.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.payer_dimension AS
SELECT
  c.CarrierKey        AS payer_id,
  c.CarrierName       AS payer_name,
  c.CarrierTypeCode   AS payer_type,
  CASE WHEN c.IsActive = 'Y' THEN TRUE ELSE FALSE END AS is_active,
  c.EffectiveDate     AS effective_date,
  c.TerminationDate   AS termination_date
FROM OLTP_DB.Insurance.Carrier c;