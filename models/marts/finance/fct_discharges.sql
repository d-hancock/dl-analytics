-- Summable grain-level fact table for discharges
-- Provides discharge-related metrics for aggregation and slicing
-- Each row represents a unique combination of discharge date and patient

SELECT 
    discharge_date, -- Date of discharge
    patient_id, -- Unique identifier for the patient
    COUNT(*) AS discharge_count -- Total number of discharges
FROM int_fct_discharges
GROUP BY discharge_date, patient_id;