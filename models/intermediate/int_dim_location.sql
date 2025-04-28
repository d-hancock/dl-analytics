-- =================================================================================
-- Intermediate Location Dimension View
-- Name: int_dim_location
-- Source Tables: stg.facility_dimension, stg.employee_dimension
-- Purpose: Standardize location dimension for all mart-level reporting.
-- Key Transformations:
--   • Join facility dimension with location records to get location names
--   • Link locations to Account Executives (AE) for sales analysis
--   • Add derived fields for reporting
-- Usage:
--   • Core location-based dimension used across all marts
-- Assumptions:
--   • facility_dimension contains a join to Inventory.Location
--   • employee_dimension contains Account Executive information
--   • RecStatus=1 indicates active records
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.dim_location AS
WITH ae_location_mapping AS (
    -- This CTE maps Account Executives to locations based on company assignments
    -- In a production environment, this should be replaced with an actual mapping table
    SELECT 
        location_id,
        ae_employee_id,
        ae_name,
        ae_region,
        ROW_NUMBER() OVER(PARTITION BY location_id ORDER BY assignment_date DESC) as rn
    FROM DEV_DB.stg.ae_location_assignment
    WHERE record_status = 1
)
SELECT
    fd.facility_id AS location_id,
    fd.company_id,
    fd.physical_location_id,
    fd.facility_name AS location_name,
    fd.is_active,
    
    -- Derive region field based on location name pattern
    -- Note: In production, this should be based on proper geographic data
    CASE 
        WHEN LOWER(fd.facility_name) LIKE '%north%' THEN 'North'
        WHEN LOWER(fd.facility_name) LIKE '%south%' THEN 'South'
        WHEN LOWER(fd.facility_name) LIKE '%east%' THEN 'East'
        WHEN LOWER(fd.facility_name) LIKE '%west%' THEN 'West'
        WHEN LOWER(fd.facility_name) LIKE '%central%' THEN 'Central'
        ELSE 'Other'
    END AS region,
    
    -- Add location type from staging if available
    fd.location_type_name,
    
    -- Add account executive mapping - either from mapping table or NULL if no mapping exists
    ae.ae_employee_id AS account_executive_id,
    ae.ae_name AS account_executive_name,
    ae.ae_region AS account_executive_region,
    
    -- Add modification tracking
    fd.created_date,
    fd.modified_date
FROM DEV_DB.stg.facility_dimension fd
LEFT JOIN ae_location_mapping ae ON fd.facility_id = ae.location_id AND ae.rn = 1
WHERE fd.record_status = 1;