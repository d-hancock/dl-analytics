-- Staging Table: Billing Claim
-- Cleans and casts raw billing claim data for downstream use
-- One-to-one mapping with the source table

SELECT 
    claim_id, -- Unique identifier for the claim
    patient_id, -- Unique identifier for the patient
    provider_id, -- Unique identifier for the provider
    claim_date, -- Date of the claim
    total_amount -- Total amount billed
FROM raw_billing_claim;
