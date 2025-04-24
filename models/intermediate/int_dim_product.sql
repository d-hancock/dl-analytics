-- Model: int_dim_product
-- Location: models/intermediate/
-- Materialization: view
-- Purpose: Centralized product dimension providing drug or supply item attributes.
-- Inputs:
--   - stg_inventory_item: Staging table for inventory items.
-- Outputs:
--   - product_id: Unique identifier for products.
--   - product_name: Human-readable name of the product.

CREATE OR REPLACE VIEW int_dim_product AS
SELECT
    item_sku AS product_id,
    item_name AS product_name
FROM
    stg_inventory_item;