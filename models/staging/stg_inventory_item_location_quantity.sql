-- =================================================================================
-- 12. Inventory Item Location Quantity View
-- Name: inventory_item_location_quantity
-- Source Tables: OLTP_DB.Inventory.InventoryItemLocationQuantity
-- Purpose: Track on-hand inventory quantity by location.
-- Key Transformations:
--   • Rename primary key to `item_location_quantity_id`.
--   • Expose on-hand quantity for inventory tracking.
-- Usage:
--   • Feed into inventory availability and stock-level reporting.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.inventory_item_location_quantity AS
SELECT
  Id                            AS item_location_quantity_id,
  InventoryItemLocation_Id      AS inventory_item_location_id,
  LotInformation_Id             AS lot_information_id,
  Quantity                      AS quantity,
  AvailableQuantity             AS available_quantity,
  RequestedQuantity             AS requested_quantity,
  UnitsPerVial                  AS units_per_vial
FROM OLTP_DB.Inventory.InventoryItemLocationQuantity;