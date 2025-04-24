-- =================================================================================
-- Intermediate Fact Table: Drug Revenue
-- Name: int_fct_drug_revenue
-- Source Tables: stg_inventory_item_location_quantity
-- Purpose: Consolidate drug revenue transactions and enable downstream revenue analysis
-- Key Transformations:
--   • Map product item_sku to standard product_id for consistent joins
--   • Retain location_id for proper dimensional analysis
--   • Include all revenue calculation components (quantity, unit_price, discounts, taxes)
-- Usage:
--   • Feed into finance.fct_drug_revenue for aggregated revenue analysis
--   • Support calculation of "Drug Revenue" KPI metric
-- Grain: One row per product transaction event
-- =================================================================================

SELECT 
    transaction_date,    -- Date of the transaction (to join with date dimension)
    item_sku AS product_id,  -- Map SKU to standard product ID to join with product dimension
    location_id,         -- Retain location ID for location dimension joining
    quantity,            -- Quantity sold in this transaction
    unit_price,          -- Price per unit for revenue calculation
    discount_amt,        -- Discount amount to be subtracted from revenue
    tax_amt              -- Tax amount to be added to revenue
FROM stg_inventory_item_location_quantity;  -- Source staging table