-- ============================================================
-- Combined SQL for Intermediate Views
-- Purpose: This file defines all intermediate views, including
--          dimensions and KPI fact tables, to support the final
--          presentational dataset for Tableau.
-- ============================================================
-- ============================================================
-- 1. Date Dimension
-- ============================================================
WITH
    int_dim_date AS (
        -- Purpose: Centralized date dimension providing calendar and fiscal period information.
        -- Inputs:
        --   - stg_date: Staging table containing raw date information.
        -- Outputs:
        --   - calendar_date: Day-level date.
        --   - fiscal_period_key: Surrogate key for fiscal periods.
        --   - period_start_date, period_end_date: Start and end dates for the fiscal periods.
        SELECT
            calendar_date,
            fiscal_period_key,
            period_start_date,
            period_end_date
        FROM
            stg_date
    ),
    -- ============================================================
    -- 2. Location Dimension
    -- ============================================================
    int_dim_location AS (
        -- Purpose: Centralized location dimension providing facility or branch attributes.
        -- Inputs:
        --   - stg_party: Staging table containing raw location data.
        -- Outputs:
        --   - location_id: Unique identifier for each location.
        --   - location_name: Human-readable name for each location.
        SELECT DISTINCT
            location_id,
            location_name
        FROM
            stg_party
    ),
    -- ============================================================
    -- 3. Product Dimension
    -- ============================================================
    int_dim_product AS (
        -- Purpose: Centralized product dimension providing drug or supply item attributes.
        -- Inputs:
        --   - stg_inventory_item: Staging table for inventory items.
        -- Outputs:
        --   - product_id: Unique identifier for products.
        --   - product_name: Human-readable name of the product.
        SELECT
            item_sku AS product_id,
            item_name AS product_name
        FROM
            stg_inventory_item
    ),
    -- ============================================================
    -- 4. Payer Dimension
    -- ============================================================
    int_dim_payer AS (
        -- Purpose: Centralized payer dimension providing insurance program attributes.
        -- Inputs:
        --   - stg_patient_policy: Staging table containing patient policy data.
        -- Outputs:
        --   - payer_id: Unique identifier for payers.
        --   - payer_name: Name of the insurance program.
        SELECT DISTINCT
            insurance_program_id AS payer_id,
            insurance_program_name AS payer_name
        FROM
            stg_patient_policy
    ),
    -- ============================================================
    -- 5. Therapy Dimension
    -- ============================================================
    int_dim_therapy AS (
        -- Purpose: Centralized therapy dimension providing therapy code and name attributes.
        -- Inputs:
        --   - therapy_lookup: Lookup table for therapy details.
        -- Outputs:
        --   - therapy_code: Unique code for therapies (e.g., HcPc).
        --   - therapy_name: Human-readable name for therapies.
        SELECT DISTINCT
            therapy_code,
            therapy_name
        FROM
            therapy_lookup
    ),
    -- ============================================================
    -- 6. KPI Fact: Discharges
    -- ============================================================
    int_fct_discharges AS (
        -- Purpose: Count of discharged patients within a specific period.
        -- Inputs:
        --   - stg_patient_discharge: Staging table for patient discharge data.
        --   - int_dim_date: Dimension table providing period start and end dates.
        -- Outputs:
        --   - discharged_patients: Count of unique patients discharged within the period.
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
            )
    ),
    -- ============================================================
    -- 7. KPI Fact: New Starts
    -- ============================================================
    int_fct_new_starts AS (
        -- Purpose: Count of new patient starts within a specific period.
        -- Inputs:
        --   - stg_patient_visits: Staging table for patient visit data.
        --   - int_dim_date: Dimension table providing period start and end dates.
        -- Outputs:
        --   - new_starts: Count of unique patients with a first visit in the period.
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
            )
    ),
    -- ============================================================
    -- 8. KPI Fact: Referrals
    -- ============================================================
    int_fct_referrals AS (
        -- Purpose: Count of referrals with a "Pending" status within the period.
        -- Inputs:
        --   - stg_referrals: Staging table for referral data.
        --   - int_dim_date: Dimension table for period start and end dates.
        -- Outputs:
        --   - referrals: Count of referrals with a "Pending" status.
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
            )
    ),
    -- ============================================================
    -- 9. KPI Fact: Expected Revenue
    -- ============================================================
    int_fct_expected_revenue AS (
        -- Purpose: Calculate expected revenue per day within the period.
        -- Inputs:
        --   - stg_revenue: Staging table for revenue data.
        --   - int_dim_date: Dimension table for calendar dates.
        -- Outputs:
        --   - expected_revenue_per_day: Average revenue per calendar day.
        SELECT
            SUM(total_revenue) / COUNT(DISTINCT calendar_date) AS expected_revenue_per_day
        FROM
            (
                SELECT
                    calendar_date,
                    SUM(contracted_revenue) AS total_revenue
                FROM
                    stg_revenue
                GROUP BY
                    calendar_date
            )
    ),
    -- ============================================================
    -- 10. KPI Fact: Drug Revenue
    -- ============================================================
    int_fct_drug_revenue AS (
        -- Purpose: Calculate total drug revenue within the period.
        -- Inputs:
        --   - stg_drug_sales: Staging table for drug sales data.
        -- Outputs:
        --   - drug_revenue: Total calculated drug revenue.
        SELECT
            SUM(quantity * unit_price) - SUM(discount_amt) + SUM(tax_amt) AS drug_revenue
        FROM
            stg_drug_sales
    )
    -- ============================================================
    -- End of Combined Intermediate Views
    -- ============================================================