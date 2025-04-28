-- =================================================================================
-- Staging Layer: Invoice Aggregate
-- Name: stg_invoice_aggregate
-- Source Tables: OLTP_DB.Billing.InvoiceAggregate
-- Purpose: 
--   Extract pre-calculated financial summaries from the invoice level.
-- Key Transformations:
--   • Rename primary key to `invoice_agg_id` (matches the invoice_id)
--   • Extract all financial summary fields including expected revenue totals
-- Usage:
--   • Source for summary revenue facts
--   • Enables efficient roll-ups without recalculating totals
--   • Supports high-level financial reporting requirements
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.invoice_aggregate AS
SELECT
  Id                    AS invoice_agg_id,   -- This matches the Invoice.Id
  BilledPrice           AS billed_price,
  ExpectedPrice         AS expected_price,
  BilledTax             AS billed_tax,
  ExpectedTax           AS expected_tax,
  TotalBilledPrice      AS total_billed_price,
  TotalExpectedPrice    AS total_expected_price,
  TotalAdjusted         AS total_adjusted,
  TotalCredits          AS total_credits,
  TotalPaid             AS total_paid,
  TotalTransfers        AS total_transfers,
  Balance               AS balance
FROM OLTP_DB.Billing.InvoiceAggregate;
-- No RecStatus filter as this table links 1:1 with Invoice, which has already been filtered