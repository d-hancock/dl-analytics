-- Intermediate Therapy Dimension
-- Enriches raw therapy data with additional attributes for reporting
-- Each row represents a unique therapy type

SELECT 
    therapy_code, -- Therapy type code (e.g., HcPc)
    therapy_name -- Therapy type name
FROM stg_encounter_patient_order;