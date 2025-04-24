-- KPI: Referrals
-- Purpose: Calculate the total number of patient referrals.
-- Inputs: int_fct_referrals
CREATE OR REPLACE VIEW marts.finance.kpi_referrals AS
SELECT
    calendar_date,
    referrals
FROM
    int_fct_referrals;