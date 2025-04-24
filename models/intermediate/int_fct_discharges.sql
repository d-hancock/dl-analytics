-- Model: int_fct_discharges
-- Location: models/intermediate/
-- Materialization: view
-- Purpose: Count of discharged patients within a specific period.
-- Inputs:
--   - stg_patient_discharge: Staging table for patient discharge data.
--   - int_dim_date: Dimension table providing period start and end dates.
-- Outputs:
--   - discharged_patients: Count of unique patients discharged within the period.

CREATE OR REPLACE VIEW int_fct_discharges AS
SELECT
    COUNT(DISTINCT patient_id) AS discharged_patients
FROM
    stg_patient_discharge
WHERE
    discharge_date BETWEEN (
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