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
  InventoryItemLocationQuantityKey AS item_location_quantity_id,
  OnHandQuantity                  AS on_hand_quantity
FROM OLTP_DB.Inventory.InventoryItemLocationQuantity;