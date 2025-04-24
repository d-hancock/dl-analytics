-- =================================================================================
-- 6. Inventory Transfer View
-- Name: inventory_transfer
-- Source Tables: OLTP_DB.Inventory.InventoryTransfer
-- Purpose: Track inventory movement events for on-hand quantity tracking.
-- Key Transformations:
--   • Rename primary key to `transfer_event_id`.
-- Usage:
--   • Feed into inventory consumption and COGS calculations.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.inventory_transfer AS
SELECT
  InventoryTransferKey  AS transfer_event_id,
  ToLocationKey         AS to_location_id
FROM OLTP_DB.Inventory.InventoryTransfer;
