-- Model: int_fct_referrals
-- Location: models/intermediate/
-- Materialization: view
-- Purpose: Count of referrals with a "Pending" status within the period.
-- Inputs:
--   - stg_referrals: Staging table for referral data.
--   - int_dim_date: Dimension table for period start and end dates.
-- Outputs:
--   - referrals: Count of referrals with a "Pending" status.

CREATE OR REPLACE VIEW int_fct_referrals AS
SELECT
    COUNT(referral_id) AS referrals
FROM
    stg_referrals
WHERE
    referral_status = 'Pending'
    AND referral_date BETWEEN (
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