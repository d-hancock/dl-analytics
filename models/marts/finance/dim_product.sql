-- Finalized product dimension for marts or presentation layers
-- Provides product-related attributes for reporting and analysis
-- Each row represents a unique product

SELECT 
    product_id, -- Drug or supply item identifier
    product_name -- Drug or supply item name
FROM int_dim_product;