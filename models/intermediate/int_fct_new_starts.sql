-- Model: int_fct_new_starts
-- Location: models/intermediate/
-- Materialization: view
-- Purpose: Count of new patient starts within a specific period.
-- Inputs:
--   - stg_patient_visits: Staging table for patient visit data.
--   - int_dim_date: Dimension table providing period start and end dates.
-- Outputs:
--   - new_starts: Count of unique patients with a first visit in the period.

CREATE OR REPLACE VIEW int_fct_new_starts AS
SELECT
    COUNT(DISTINCT patient_id) AS new_starts
FROM
    stg_patient_visits
WHERE
    status = 'Active'
    AND first_visit_date BETWEEN (
        SELECT
            period_start_date
        FROM
            int_dim_date
    ) AND (
        SELECT
            period_end_date
        FROM
            int_dim_date
    );