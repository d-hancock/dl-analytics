-- KPI: Discharged Patients
-- Purpose: Calculate the total number of discharged patients.
-- Inputs: int_fct_discharges
CREATE OR REPLACE VIEW marts.finance.kpi_discharged_patients AS
SELECT
    calendar_date,
    discharged_patients
FROM
    int_fct_discharges;