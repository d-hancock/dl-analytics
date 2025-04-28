-- =================================================================================
-- Intermediate Product Dimension View
-- Name: int_dim_product
-- Source Tables: stg.billing_claim_item, stg.inventory_item
-- Purpose: Create product dimension for inventory items
-- Key Transformations:
--   • Join claim items with inventory data to get complete product info
--   • Create standardized product categories and hierarchies
--   • Support product-based KPI analysis
-- Usage:
--   • Product-based analysis across all marts
-- Assumptions:
--   • stg.inventory_item table exists with inventory details
--   • record_status=1 indicates active records
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.dim_product AS
WITH inventory_items AS (
    -- Extract unique inventory items from billing claims with validation
    SELECT DISTINCT
        bci.inventory_item_id,
        bci.item_description,
        bci.inventory_item_type_id,
        bci.item_type_description,
        bci.hcpcs_code
    FROM DEV_DB.stg.billing_claim_item bci
    WHERE bci.record_status = 1
    AND bci.inventory_item_id IS NOT NULL
)
SELECT
    ii.inventory_item_id AS product_id,
    ii.item_description AS product_name,
    ii.hcpcs_code,
    
    -- Use the item_type_description for basic categorization
    ii.item_type_description AS product_type,
    
    -- Create product categories based on inventory type and HCPCS code patterns
    CASE 
        WHEN ii.inventory_item_type_id = 1 OR ii.hcpcs_code LIKE 'J%' THEN 'Drug'
        WHEN ii.inventory_item_type_id = 2 OR ii.hcpcs_code LIKE 'B%' THEN 'Supply'
        WHEN ii.inventory_item_type_id = 3 OR ii.hcpcs_code LIKE 'E%' THEN 'Equipment'
        WHEN ii.inventory_item_type_id = 4 THEN 'Service'
        ELSE 'Other'
    END AS product_category,

    -- Add a flag for high-cost drugs (used in margin analysis KPIs)
    CASE 
        WHEN ii.inventory_item_type_id = 1 AND ii.hcpcs_code LIKE 'J%' THEN TRUE
        ELSE FALSE
    END AS is_specialty_drug
FROM inventory_items ii;