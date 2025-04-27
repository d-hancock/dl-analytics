-- =================================================================================
-- Intermediate Location Dimension View
-- Name: int_dim_location
-- Source Tables: stg.facility_dimension
-- Purpose: Standardize location dimension for all mart-level reporting.
-- Key Transformations:
--   • Use proper facility dimension fields from staging view
--   • Add derived fields for reporting
-- Usage:
--   • Core location-based dimension used across all marts
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.dim_location AS
SELECT
    facility_id AS location_id,
    company_id,
    location_id AS physical_location_id,
    facility_name AS location_name,
    is_active,
    
    -- Derive region field (example - would need to be based on actual data)
    CASE 
        WHEN facility_id % 3 = 0 THEN 'Northeast'
        WHEN facility_id % 3 = 1 THEN 'Central'
        WHEN facility_id % 3 = 2 THEN 'West'
    END AS region
FROM DEV_DB.stg.facility_dimension
WHERE record_status = 1;