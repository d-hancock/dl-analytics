-- Summable grain-level fact table for new patient starts
-- Provides metrics for new patient starts for aggregation and slicing
-- Each row represents a unique combination of start date and patient

SELECT 
    start_date, -- Date of the new patient start
    patient_id, -- Unique identifier for the patient
    COUNT(*) AS new_start_count -- Total number of new patient starts
FROM int_fct_new_starts
GROUP BY start_date, patient_id;