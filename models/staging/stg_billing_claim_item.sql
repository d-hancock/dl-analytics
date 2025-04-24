-- Staging Table: Billing Claim Item
-- Cleans and casts raw billing claim item data for downstream use
-- One-to-one mapping with the source table

SELECT 
    claim_item_id, -- Unique identifier for the claim item
    claim_id, -- Associated claim identifier
    item_code, -- Code for the billed item
    item_description, -- Description of the billed item
    quantity, -- Quantity of the item billed
    unit_price -- Price per unit of the item
FROM raw_billing_claim_item;