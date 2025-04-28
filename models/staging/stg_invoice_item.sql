-- =================================================================================
-- Staging Layer: Invoice Item
-- Name: stg_invoice_item
-- Source Tables: OLTP_DB.Billing.InvoiceItem
-- Purpose: 
--   Extract invoice line item details with expected revenue data.
-- Key Transformations:
--   • Rename primary key to `invoice_item_id`
--   • Extract relevant invoice item attributes including expected revenue fields
--   • Maintain original expected price and tax fields
-- Usage:
--   • Source for revenue facts
--   • Enables expected revenue analysis at the line item level
--   • Supports the revenue analysis requirements in the dashboard
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.invoice_item AS
SELECT
  Id                    AS invoice_item_id,
  Invoice_Id            AS invoice_id,
  InventoryItem_Id      AS inventory_item_id, 
  InventoryItemType_Id  AS inventory_item_type_id,
  ItemName              AS item_name,
  Quantity              AS quantity,
  BilledPrice           AS billed_price,
  ExpectedPrice         AS expected_price,
  BilledTax             AS billed_tax,
  ExpectedTax           AS expected_tax,
  TotalBilledPrice      AS total_billed_price,
  TotalExpectedPrice    AS total_expected_price,
  TicketItem_Id         AS ticket_item_id,
  CreatedBy             AS created_by,
  CreatedDate           AS created_date,
  ModifiedBy            AS modified_by,
  ModifiedDate          AS modified_date,
  RecStatus             AS record_status
FROM OLTP_DB.Billing.InvoiceItem
WHERE RecStatus = 1;  -- Only include active records