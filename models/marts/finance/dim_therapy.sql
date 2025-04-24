-- Finalized therapy dimension for marts or presentation layers
-- Provides therapy-related attributes for reporting and analysis
-- Each row represents a unique therapy type

SELECT 
    therapy_code, -- Therapy type code (e.g., HcPc)
    therapy_name -- Therapy type name
FROM int_dim_therapy;