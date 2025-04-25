-- =================================================================================
-- Intermediate Therapy Dimension View
-- Name: int_dim_therapy
-- Source Tables: stg.patient_orders
-- Purpose: Standardize therapy dimension for all mart-level reporting.
-- Key Transformations:
--   • Extract therapy type information from patient orders
--   • Add derived fields for therapy categories
-- Usage:
--   • Core therapy-based dimension used across all marts
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.dim_therapy AS
WITH therapy_types AS (
    -- Extract distinct therapy types from patient orders
    SELECT DISTINCT
        therapy_type_id,
        inventory_item_type_id
    FROM DEV_DB.stg.patient_orders
    WHERE record_status = 1
)
SELECT
    therapy_type_id,
    inventory_item_type_id,
    
    -- Derive therapy category (would need to be based on actual data)
    CASE 
        WHEN therapy_type_id = 1 THEN 'Infusion'
        WHEN therapy_type_id = 2 THEN 'Enteral'
        WHEN therapy_type_id = 3 THEN 'DME'
        WHEN therapy_type_id = 4 THEN 'Respiratory'
        ELSE 'Other'
    END AS therapy_category,
    
    -- Derive therapy class
    CASE 
        WHEN therapy_type_id IN (1, 2) THEN 'Drug'
        WHEN therapy_type_id IN (3, 4) THEN 'Equipment'
        ELSE 'Other'
    END AS therapy_class
    
FROM therapy_types;