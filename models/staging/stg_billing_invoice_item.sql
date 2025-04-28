-- =================================================================================
-- Staging Layer: Billing Invoice Item
-- Name: stg_billing_invoice_item
-- Source Tables: OLTP_DB.Billing.InvoiceItem
-- Purpose: 
--   Extract invoice line item data for detailed revenue analysis.
-- Key Transformations:
--   • Rename primary key to `invoice_item_id`
--   • Extract relevant invoice item attributes
-- Usage:
--   • Source for invoice line item metrics
--   • Feeds into finance.fct_revenue fact table
--   • Supports drug vs. non-drug revenue differentiation
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.billing_invoice_item AS
SELECT
  Id                    AS invoice_item_id,
  Invoice_Id            AS invoice_id,
  InventoryItem_Id      AS inventory_item_id,
  InventoryItemType_Id  AS item_type_id, -- Corrected name from source
  ItemName              AS item_name, -- Added from source
  TicketItem_Id         AS ticket_item_id, -- Added from source
  Quantity              AS quantity,
  BilledPrice           AS billed_price, -- Renamed from UnitPrice, using BilledPrice from source
  ExpectedPrice         AS expected_price, -- Added from source
  BilledTax             AS billed_tax, -- Added from source
  ExpectedTax           AS expected_tax, -- Added from source
  TotalBilledPrice      AS total_billed_price, -- Renamed from TotalPrice, using TotalBilledPrice from source
  TotalExpectedPrice    AS total_expected_price, -- Added from source
  CreatedBy             AS created_by,
  CreatedDate           AS created_date,
  ModifiedBy            AS modified_by,
  ModifiedDate          AS modified_date,
  RecStatus             AS record_status
FROM OLTP_DB.Billing.InvoiceItem
WHERE RecStatus = 1;