-- Intermediate Product Dimension
-- Enriches raw product data with additional attributes for reporting
-- Each row represents a unique product

SELECT 
    item_sku AS product_id, -- Drug or supply item identifier
    item_name AS product_name -- Drug or supply item name
FROM stg_inventory_item;