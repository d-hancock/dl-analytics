-- Intermediate Fact Table: Drug Revenue
-- Joins and derives metrics related to drug revenue
-- Each row represents a unique transaction event

SELECT 
    transaction_date, -- Date of the transaction
    item_sku AS product_id, -- Drug or supply item identifier
    quantity, -- Quantity sold
    unit_price, -- Price per unit
    discount_amt, -- Discount applied
    tax_amt -- Tax applied
FROM stg_inventory_item_location_quantity;