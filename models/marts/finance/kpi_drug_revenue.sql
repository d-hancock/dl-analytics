-- KPI: Drug Revenue
-- Purpose: Calculate the total drug revenue.
-- Inputs: int_fct_drug_revenue
CREATE OR REPLACE VIEW marts.finance.kpi_drug_revenue AS
SELECT
    calendar_date,
    drug_revenue
FROM
    int_fct_drug_revenue;