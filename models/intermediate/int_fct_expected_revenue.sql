-- Intermediate Fact Table: Expected Revenue
-- Joins and derives metrics related to expected revenue
-- Each row represents a unique contract event

SELECT 
    revenue_date, -- Date of the expected revenue
    contract_id, -- Unique identifier for the contract
    contracted_revenue -- Expected revenue amount
FROM stg_invoice_claim_item_link;