-- KPI: New Starts
-- Purpose: Calculate the total number of new patient starts.
-- Inputs: int_fct_new_starts
CREATE OR REPLACE VIEW marts.finance.kpi_new_starts AS
SELECT
    calendar_date,
    new_starts
FROM
    int_fct_new_starts;