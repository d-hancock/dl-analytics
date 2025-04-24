-- Intermediate Payer Dimension
-- Enriches raw payer data with additional attributes for reporting
-- Each row represents a unique payer

SELECT 
    insurance_program_id AS payer_id, -- Insurance program identifier
    insurance_program_name AS payer_name -- Insurance program name
FROM stg_payer_dimension;