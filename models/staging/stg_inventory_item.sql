-- =================================================================================
-- Staging Layer: Inventory Item
-- Name: stg_inventory_item
-- Source Tables: OLTP_DB.Inventory.InventoryItem
-- Purpose: 
--   Extract product information to support product dimension for analysis.
-- Key Transformations:
--   • Rename primary key to `inventory_item_id`
--   • Extract relevant product attributes
-- Usage:
--   • Source for product dimension
--   • Enables analytics by product and product category
--   • Supports drug vs. non-drug revenue analysis
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.inventory_item AS
SELECT
  Id                      AS inventory_item_id,
  -- ItemNumber              AS item_number, -- Removed, not in source docs
  Description             AS item_name, -- Renamed from ItemName, using Description from source
  ItemType_Id             AS item_type_id,
  HCPC_Id                 AS hcpc_id, -- Renamed from HCPC, using HCPC_Id from source
  HCPCUnits               AS hcpc_units, -- Added from source docs
  -- HCPC_Modifier           AS hcpc_modifier, -- Removed, not in source docs
  -- NDC                     AS ndc_code, -- Removed, not in source docs
  -- UPN                     AS upn_code, -- Removed, not in source docs
  Category_Id             AS inventory_category_id, -- Renamed from InventoryCategory_Id, using Category_Id from source
  -- IsDrugItem              AS is_drug_item, -- Removed, not explicitly in source docs
  Active                  AS is_active, -- Renamed from IsActive, using Active from source
  Manufacturer_Id         AS manufacturer_id,
  -- UnitOfMeasure_Id        AS unit_of_measure_id, -- Removed, not in source docs
  CreatedBy               AS created_by,
  CreatedDate             AS created_date,
  ModifiedBy              AS modified_by,
  ModifiedDate            AS modified_date,
  RecStatus               AS record_status
FROM OLTP_DB.Inventory.InventoryItem
WHERE RecStatus = 1;