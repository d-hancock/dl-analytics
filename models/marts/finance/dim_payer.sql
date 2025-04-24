-- Finalized payer dimension for marts or presentation layers
-- Provides payer-related attributes for reporting and analysis
-- Each row represents a unique payer

SELECT 
    payer_id, -- Insurance program identifier
    payer_name -- Insurance program name
FROM int_dim_payer;