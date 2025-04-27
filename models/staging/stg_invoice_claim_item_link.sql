-- =================================================================================
-- 7. Invoice Claim Item Link View
-- Name: invoice_claim_item_link
-- Source Tables: OLTP_DB.Billing.InvoiceClaim
-- Purpose: Link invoice items to claim items for revenue reconciliation.
-- Key Transformations:
--   • Expose both invoice_id and claim_id for relationship tracking.
-- Usage:
--   • Join invoices to claims when tracking revenue recognition.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.invoice_claim_item_link AS
SELECT
  Id                AS invoice_claim_id,
  Invoice_Id        AS invoice_id,
  Claim_Id          AS claim_id,
  InvoiceItem_Id    AS invoice_item_id,
  ClaimItem_Id      AS claim_item_id,
  CreatedBy         AS created_by,
  CreatedDate       AS created_date,
  ModifiedBy        AS modified_by,
  ModifiedDate      AS modified_date,
  RecStatus         AS record_status
FROM OLTP_DB.Billing.InvoiceAggregate
WHERE RecStatus = 1;