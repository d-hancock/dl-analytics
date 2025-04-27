-- =================================================================================
-- Finance Mart Layer: Patient Activity Facts
-- Name: fct_patient_activity
-- Source Tables: 
--   • int_fct_referrals - Patient referral metrics
--   • int_fct_new_starts - New patient start metrics
--   • int_fct_discharges - Patient discharge metrics
--   • int_dim_date - Date dimension for time-based analysis
--   • int_dim_location - Location dimension for facility-based filtering
--   • int_dim_therapy - Therapy dimension for treatment categorization
-- Purpose: 
--   Consolidate patient activity metrics (referrals, starts, discharges) with
--   consistent dimensions for downstream reporting.
-- Key Features:
--   • Daily grain for time-series analysis
--   • Consolidates metrics from three different patient activity streams
--   • Allows analysis by location, therapy type, and time period
-- Usage:
--   • Feed dashboard_financial_executive for patient demographic metrics
--   • Support patient acquisition and retention analysis
-- =================================================================================

-- 1. Referrals fact at daily grain
WITH referrals_daily AS (
    SELECT
        d.calendar_date,
        d.fiscal_period_key,
        ref.patient_id,
        ref.team_id AS location_id,
        
        -- Count referrals (pending status per requirements doc)
        CASE 
            WHEN ref.response_status_id = 1 THEN 1 -- Assuming 1 = 'Pending'
            ELSE 0 
        END AS referral_count,
        
        0 AS new_start_count,
        0 AS discharge_count
    FROM DEV_DB.int.fct_referrals ref
    JOIN DEV_DB.int.dim_date d ON ref.referral_date = d.calendar_date
),

-- 2. New starts fact at daily grain
new_starts_daily AS (
    SELECT
        d.calendar_date,
        d.fiscal_period_key,
        ns.patient_id,
        ns.team_id AS location_id,
        
        0 AS referral_count,
        1 AS new_start_count, -- Each row represents one new start
        0 AS discharge_count
    FROM DEV_DB.int.fct_new_starts ns
    JOIN DEV_DB.int.dim_date d ON ns.start_date = d.calendar_date
),

-- 3. Discharges fact at daily grain
discharges_daily AS (
    SELECT
        d.calendar_date,
        d.fiscal_period_key,
        dis.patient_id,
        dis.team_id AS location_id,
        
        0 AS referral_count,
        0 AS new_start_count,
        1 AS discharge_count -- Each row represents one discharge
    FROM DEV_DB.int.fct_discharges dis
    JOIN DEV_DB.int.dim_date d ON dis.discharge_date = d.calendar_date
)

-- 4. Union all patient activity metrics
SELECT
    -- Time dimension
    d.calendar_date,
    d.fiscal_period_key,
    d.fiscal_year,
    d.fiscal_quarter,
    d.fiscal_month,
    
    -- Location dimension
    loc.location_id,
    loc.location_name,
    loc.region,
    
    -- Therapy dimension (can be enriched with patient therapy information when available)
    NULL AS therapy_type_id,
    NULL AS therapy_class,
    
    -- Activity metrics
    SUM(src.referral_count) AS referrals,
    SUM(src.new_start_count) AS new_starts,
    SUM(src.discharge_count) AS discharged_patients,
    
    -- Calculated metrics
    SUM(src.new_start_count) - SUM(src.discharge_count) AS net_patient_change,
    
    -- Period metrics (for easy period comparisons)
    FIRST_VALUE(d.calendar_date) OVER (
        PARTITION BY d.fiscal_period_key 
        ORDER BY d.calendar_date
    ) AS period_start_date,
    
    LAST_VALUE(d.calendar_date) OVER (
        PARTITION BY d.fiscal_period_key 
        ORDER BY d.calendar_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS period_end_date
FROM (
    SELECT * FROM referrals_daily
    UNION ALL
    SELECT * FROM new_starts_daily
    UNION ALL
    SELECT * FROM discharges_daily
) src
JOIN DEV_DB.int.dim_date d ON src.calendar_date = d.calendar_date
LEFT JOIN DEV_DB.int.dim_location loc ON src.location_id = loc.location_id
GROUP BY
    d.calendar_date,
    d.fiscal_period_key,
    d.fiscal_year,
    d.fiscal_quarter,
    d.fiscal_month,
    loc.location_id,
    loc.location_name,
    loc.region;