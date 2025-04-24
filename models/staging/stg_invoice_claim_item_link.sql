-- =================================================================================
-- 7. Invoice Claim Item Link View
-- Name: invoice_claim_item_link
-- Source Tables: OLTP_DB.Billing.InvoiceClaimItemLink
-- Purpose: Bridge invoice headers to claim line items for combined revenue and AR analysis.
-- Key Transformations:
--   • Rename primary key to `link_id`.
-- Usage:
--   • Enable combined revenue and AR analysis by linking invoices to claims.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.invoice_claim_item_link AS
SELECT
  InvoiceClaimItemLinkKey   AS link_id,
  ClaimItemKey              AS claim_item_id
FROM OLTP_DB.Billing.InvoiceClaimItemLink;