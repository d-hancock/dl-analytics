-- =================================================================================
-- Intermediate Payer Dimension View
-- Name: int_dim_payer
-- Source Tables: stg.payer_dimension
-- Purpose: Standardize payer dimension for all mart-level reporting.
-- Key Transformations:
--   • Use proper payer fields from staging view
--   • Add derived fields for reporting categories
-- Usage:
--   • Core payer-based dimension used across all marts
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.dim_payer AS
SELECT
    payer_id,
    payer_name,
    carrier_type_id,
    payor_type_id,
    
    -- Derive payer category based on type IDs
    CASE 
        WHEN payor_type_id = 1 THEN 'Medicare'
        WHEN payor_type_id = 2 THEN 'Medicaid'
        WHEN payor_type_id = 3 THEN 'Commercial'
        WHEN payor_type_id = 4 THEN 'Self Pay'
        ELSE 'Other'
    END AS payer_category,
    
    use_medicare_rules,
    is_supplementary,
    is_medicare_cba_provider
FROM DEV_DB.stg.payer_dimension;