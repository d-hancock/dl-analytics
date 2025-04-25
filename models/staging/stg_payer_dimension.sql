-- =================================================================================
-- 5. Consolidated Payer Dimension View
-- Name: payer_dimension
-- Source Tables: OLTP_DB.Insurance.Carrier
-- Purpose: Normalize payer lookup for revenue and claims analysis.
-- Key Transformations:
--   • Rename primary key to `payer_id`.
--   • Include carrier/payer attributes for analysis.
-- Usage:
--   • Join to claims and invoices for payer-level revenue analysis.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.payer_dimension AS
SELECT
  c.Id                          AS payer_id,
  c.BillingOrganizationName     AS payer_name,
  c.CarrierType_Id              AS carrier_type_id,
  c.PayorType_Id                AS payor_type_id,
  c.Identifier                  AS identifier,
  c.UseMedicareRules            AS use_medicare_rules,
  c.ClaimInsuranceType_Id       AS claim_insurance_type_id,
  c.IsSupplementary             AS is_supplementary,
  c.IsAlwaysBilledForDenial     AS is_always_billed_for_denial,
  c.IsMedicareCBAProvider       AS is_medicare_cba_provider,
  c.CreatedDate                 AS created_date,
  c.ModifiedDate                AS modified_date
FROM OLTP_DB.Insurance.Carrier c;