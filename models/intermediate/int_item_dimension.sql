-- filepath: /home/dale/development/dl-analytics/models/intermediate/int_item_dimension.sql
-- =================================================================================
-- Intermediate Item Dimension View
-- Name: int_item_dimension
-- Source Tables: stg.inventory_item, stg.item_type_dimension (assuming it exists or will be created)
-- Purpose: Standardize item/product attributes for reporting.
-- Key Transformations:
--   • Select relevant item fields from stg.inventory_item.
--   • Join with item type information (placeholder for now).
--   • Add derived fields like item category (e.g., Drug, Supply, Service).
-- Usage:
--   • Join to fact tables for item-based analysis (e.g., revenue by product).
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.item_dimension AS
SELECT
    ii.inventory_item_id,
    ii.item_name,
    ii.item_type_id,
    -- Placeholder for item type name - join required with stg.item_type_dimension
    -- itt.item_type_name, 
    ii.hcpc_id,
    ii.hcpc_units,
    ii.ndc_code,
    ii.manufacturer_name,
    ii.brand_name,
    ii.unit_of_measure,
    ii.unit_price,
    ii.is_billable,
    ii.is_taxable,
    ii.is_active,
    -- Basic categorization based on item_type_id (example, adjust as needed)
    CASE 
        WHEN ii.item_type_id IN (1, 5) THEN 'Drug' -- Assuming types 1 and 5 are drugs
        WHEN ii.item_type_id = 2 THEN 'Supply'
        WHEN ii.item_type_id = 3 THEN 'Service'
        ELSE 'Other' 
    END AS item_category,
    ii.created_date,
    ii.modified_date,
    ii.record_status
FROM DEV_DB.stg.inventory_item ii
-- LEFT JOIN DEV_DB.stg.item_type_dimension itt ON ii.item_type_id = itt.item_type_id -- Uncomment when stg.item_type_dimension is available
WHERE ii.record_status = 1;

