-- =================================================================================
-- Intermediate Therapy Dimension View
-- Name: int_dim_therapy
-- Source Tables: stg.patient_orders
-- Purpose: Standardize therapy dimension for all mart-level reporting.
-- Key Transformations:
--   • Extract therapy type information from patient orders staging table
--   • Map therapy types to standard business categories
--   • Add derived fields for reporting hierarchies
-- Usage:
--   • Core therapy-based dimension used across all marts
-- Assumptions:
--   • therapy_type_id: 1=Infusion, 2=Enteral, 3=DME, 4=Respiratory based on PatientOrder schema
--   • record_status=1 indicates active records
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.dim_therapy AS
WITH therapy_types AS (
    -- Extract distinct therapy types from patient orders
    SELECT DISTINCT
        therapy_type_id,
        inventory_item_type_id,
        therapy_type_name
    FROM DEV_DB.stg.patient_orders
    WHERE record_status = 1
)
SELECT
    therapy_type_id,
    inventory_item_type_id,
    therapy_type_name,
    
    -- Derive therapy category using standard mapping
    CASE 
        WHEN therapy_type_id = 1 THEN 'Infusion'
        WHEN therapy_type_id = 2 THEN 'Enteral'
        WHEN therapy_type_id = 3 THEN 'DME'
        WHEN therapy_type_id = 4 THEN 'Respiratory'
        ELSE 'Other'
    END AS therapy_class,
    
    -- Add therapy service line for reporting grouping
    CASE 
        WHEN therapy_type_id = 1 THEN 'Specialty Infusion'
        WHEN therapy_type_id = 2 THEN 'Nutrition'
        WHEN therapy_type_id IN (3, 4) THEN 'Equipment Services'
        ELSE 'Other Services'
    END AS therapy_service_line,
    
    -- Add reporting attributes for KPIs
    CASE 
        WHEN therapy_type_id = 1 THEN TRUE  -- Infusion therapies count for clinical metrics
        ELSE FALSE
    END AS is_clinical_therapy
FROM therapy_types;