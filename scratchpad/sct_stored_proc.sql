-- ============================================================
-- Final Tableau Dataset
-- ============================================================
-- Purpose:
-- This query assembles the final presentational dataset required
-- for the Tableau dashboard. It integrates all intermediate
-- dimensions and fact tables (KPIs) into a single dataset.
--
-- Shape:
-- - One row per combination of Date × Location × Product/Therapy × Payer.
-- - Each KPI appears as its own column for easy pivoting and visualization.
--
-- Inputs:
-- - Intermediate dimension tables:
--     - int_dim_date
--     - int_dim_location
--     - int_dim_product
--     - int_dim_therapy
--     - int_dim_payer
-- - Intermediate fact tables (KPIs):
--     - int_fct_discharges
--     - int_fct_new_starts
--     - int_fct_referrals
--     - int_fct_expected_revenue
--     - int_fct_drug_revenue
--
-- Outputs:
-- - A consolidated dataset with all dimensions and KPIs.

WITH final_dataset AS (
    SELECT 
        -- ====================================================
        -- Date Dimensions
        -- ====================================================
        d.calendar_date,
        d.fiscal_period_key,
        d.period_start_date,
        d.period_end_date,

        -- ====================================================
        -- Location Dimensions
        -- ====================================================
        l.location_id,
        l.location_name,

        -- ====================================================
        -- Product/Therapy Dimensions
        -- ====================================================
        p.product_id,
        p.product_name,
        t.therapy_code,
        t.therapy_name,

        -- ====================================================
        -- Payer Dimensions
        -- ====================================================
        payer.payer_id,
        payer.payer_name,

        -- ====================================================
        -- KPI Metrics
        -- ====================================================
        kpi_discharged.discharged_patients,
        kpi_new_starts.new_starts,
        kpi_referrals.referrals,
        kpi_expected_revenue.expected_revenue_per_day,
        kpi_drug_revenue.drug_revenue

    FROM
        -- ====================================================
        -- Join Dimension Tables
        -- ====================================================
        int_dim_date d
    LEFT JOIN int_dim_location l 
        ON d.calendar_date = l.calendar_date -- Adjust join condition as needed
    LEFT JOIN int_dim_product p 
        ON d.calendar_date = p.calendar_date -- Adjust join condition as needed
    LEFT JOIN int_dim_therapy t 
        ON d.calendar_date = t.calendar_date -- Adjust join condition as needed
    LEFT JOIN int_dim_payer payer 
        ON d.calendar_date = payer.calendar_date -- Adjust join condition as needed

        -- ====================================================
        -- Join KPI Fact Tables
        -- ====================================================
        marts.finance.kpi_discharged_patients kpi_discharged
        ON d.calendar_date = kpi_discharged.calendar_date
    LEFT JOIN marts.finance.kpi_new_starts kpi_new_starts
        ON d.calendar_date = kpi_new_starts.calendar_date
    LEFT JOIN marts.finance.kpi_referrals kpi_referrals
        ON d.calendar_date = kpi_referrals.calendar_date
    LEFT JOIN marts.finance.kpi_expected_revenue_per_day kpi_expected_revenue
        ON d.calendar_date = kpi_expected_revenue.calendar_date
    LEFT JOIN marts.finance.kpi_drug_revenue kpi_drug_revenue
        ON d.calendar_date = kpi_drug_revenue.calendar_date

    WHERE d.calendar_date IS NOT NULL -- Example condition
)

-- ============================================================
-- Final SELECT Statement
-- ============================================================
SELECT *
FROM final_dataset;