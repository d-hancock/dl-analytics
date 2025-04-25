-- =================================================================================
-- Intermediate Product Dimension View
-- Name: int_dim_product
-- Source Tables: stg.billing_claim_item
-- Purpose: Create product dimension for inventory items
-- Key Transformations:
--   • Extract distinct inventory items from claim items
--   • Create a standardized product dimension
-- Usage:
--   • Product-based analysis across all marts
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.dim_product AS
WITH inventory_items AS (
    -- Extract unique inventory items from billing claims
    SELECT DISTINCT
        inventory_item_id
    FROM DEV_DB.stg.billing_claim_item
    WHERE record_status = 1
)
SELECT
    inventory_item_id AS product_id,
    
    -- Note: In a real implementation, you would join to an inventory item table
    -- This is a placeholder for the product dimension with derived fields
    CASE 
        WHEN inventory_item_id % 5 = 0 THEN 'Drug'
        WHEN inventory_item_id % 5 = 1 THEN 'Supply'
        WHEN inventory_item_id % 5 = 2 THEN 'Equipment'
        WHEN inventory_item_id % 5 = 3 THEN 'Service'
        ELSE 'Other'
    END AS product_category,
    
    CASE 
        WHEN inventory_item_id % 3 = 0 THEN 'High'
        WHEN inventory_item_id % 3 = 1 THEN 'Medium'
        ELSE 'Low'
    END AS price_tier
    
FROM inventory_items;