-- =================================================================================
-- Intermediate Clinical Dimension View
-- Name: int_dim_clinical
-- Source Tables: stg.clinician_visit, stg.nursing
-- Purpose: Standardize clinical and nursing dimensions for all mart-level reporting.
-- Key Transformations:
--   • Combine nursing type with visit information
--   • Create nursing categorization for KPIs
-- Usage:
--   • Core clinical dimension used across clinical and revenue KPIs
-- Assumptions:
--   • stg.clinician_visit contains visit type information 
--   • stg.nursing contains nursing type information
--   • record_status=1 indicates active records
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.dim_clinical AS
WITH nursing_types AS (
    -- Extract distinct nursing types from nursing staging table
    SELECT DISTINCT
        nursing_type_id,
        nursing_type_name,
        is_specialized
    FROM DEV_DB.stg.nursing
    WHERE record_status = 1
)
SELECT
    n.nursing_type_id,
    n.nursing_type_name,
    
    -- Derive nursing category for reporting
    CASE 
        WHEN n.is_specialized = TRUE THEN 'Specialized'
        ELSE 'General'
    END AS nursing_category,
    
    -- Add nursing service level classification
    CASE 
        WHEN LOWER(n.nursing_type_name) LIKE '%infusion%' THEN 'Infusion'
        WHEN LOWER(n.nursing_type_name) LIKE '%enteral%' THEN 'Enteral'
        WHEN LOWER(n.nursing_type_name) LIKE '%respiratory%' THEN 'Respiratory'
        WHEN LOWER(n.nursing_type_name) LIKE '%wound%' THEN 'Wound Care'
        ELSE 'General'
    END AS nursing_service_type,
    
    -- Add flag for revenue reporting
    CASE
        WHEN n.is_specialized = TRUE THEN TRUE
        ELSE FALSE
    END AS is_billable_service
FROM nursing_types n;