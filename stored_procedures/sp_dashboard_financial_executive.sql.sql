CREATE OR REPLACE PROCEDURE sp_dashboard_financial_executive(
    p_start_date DATE,
    p_end_date DATE,
    p_fiscal_year INTEGER DEFAULT NULL
)
RETURNS TABLE (
    calendar_date DATE,
    fiscal_period_key VARCHAR,
    fiscal_year INTEGER,
    fiscal_quarter INTEGER,
    fiscal_month INTEGER,
    location_id INTEGER,
    location_name VARCHAR,
    product_id INTEGER,
    product_name VARCHAR,
    therapy_id INTEGER,
    therapy_name VARCHAR,
    payer_id INTEGER,
    payer_name VARCHAR,
    discharged_patients INTEGER,
    new_starts INTEGER,
    referrals INTEGER,
    drug_revenue DECIMAL(18,2),
    total_expected_revenue DECIMAL(18,2),
    expected_revenue_per_day DECIMAL(18,2),
    period_total_expected_revenue DECIMAL(18,2),
    period_drug_revenue DECIMAL(18,2),
    period_expected_revenue_per_day DECIMAL(18,2)
)
LANGUAGE SQL
AS
$$
BEGIN
    -- 1. Create date dimension CTE
    WITH date_dim AS (
        SELECT
            d.calendar_date,
            d.fiscal_period_key,
            d.fiscal_year,
            d.fiscal_quarter,
            d.fiscal_month,
            MIN(d.calendar_date) OVER (PARTITION BY d.fiscal_period_key) AS period_start_date,
            MAX(d.calendar_date) OVER (PARTITION BY d.fiscal_period_key) AS period_end_date,
            COUNT(*) OVER (PARTITION BY d.fiscal_period_key) AS days_in_period
        FROM DEV_DB.int.dim_date d
        WHERE (d.calendar_date BETWEEN p_start_date AND p_end_date)
           OR (p_fiscal_year IS NOT NULL AND d.fiscal_year = p_fiscal_year)
    ),
    
    -- 2. Get patient referrals
    referrals AS (
        SELECT
            d.calendar_date,
            ref.team_id AS location_id,
            ref.therapy_type_id,
            COUNT(CASE WHEN ref.response_status_id = 1 THEN 1 END) AS referrals -- Pending status
        FROM DEV_DB.int.fct_referrals ref
        JOIN date_dim d ON ref.referral_date = d.calendar_date
        GROUP BY d.calendar_date, ref.team_id, ref.therapy_type_id
    ),
    
    -- 3. Get new patient starts
    new_starts AS (
        SELECT
            d.calendar_date,
            ns.team_id AS location_id,
            ns.therapy_type_id,
            COUNT(*) AS new_starts
        FROM DEV_DB.int.fct_new_starts ns
        JOIN date_dim d ON ns.start_date = d.calendar_date
        GROUP BY d.calendar_date, ns.team_id, ns.therapy_type_id
    ),
    
    -- 4. Get patient discharges
    discharges AS (
        SELECT
            d.calendar_date,
            dis.team_id AS location_id,
            dis.therapy_type_id,
            COUNT(*) AS discharged_patients
        FROM DEV_DB.int.fct_discharges dis
        JOIN date_dim d ON dis.discharge_date = d.calendar_date
        GROUP BY d.calendar_date, dis.team_id, dis.therapy_type_id
    ),
    
    -- 5. Get drug revenue
    drug_revenue AS (
        SELECT
            d.calendar_date,
            dr.location_id,
            p.product_id,
            p.product_category_id AS therapy_type_id,
            dr.payer_id,
            SUM(dr.total_price) AS drug_revenue
        FROM DEV_DB.int.fct_drug_revenue dr
        JOIN date_dim d ON dr.transaction_date = d.calendar_date
        JOIN DEV_DB.int.dim_product p ON dr.product_id = p.product_id
        GROUP BY d.calendar_date, dr.location_id, p.product_id, p.product_category_id, dr.payer_id
    ),
    
    -- 6. Get expected revenue
    expected_revenue AS (
        SELECT
            d.calendar_date,
            er.location_id,
            er.product_id,
            p.product_category_id AS therapy_type_id,
            er.payer_id,
            SUM(er.expected_revenue) AS expected_revenue
        FROM DEV_DB.int.fct_expected_revenue er
        JOIN date_dim d ON er.revenue_date = d.calendar_date
        JOIN DEV_DB.int.dim_product p ON er.product_id = p.product_id
        GROUP BY d.calendar_date, er.location_id, er.product_id, p.product_category_id, er.payer_id
    ),
    
    -- 7. Combine patient activity metrics
    patient_activity AS (
        SELECT
            COALESCE(r.calendar_date, ns.calendar_date, d.calendar_date) AS calendar_date,
            COALESCE(r.location_id, ns.location_id, d.location_id) AS location_id,
            COALESCE(r.therapy_type_id, ns.therapy_type_id, d.therapy_type_id) AS therapy_type_id,
            COALESCE(r.referrals, 0) AS referrals,
            COALESCE(ns.new_starts, 0) AS new_starts,
            COALESCE(d.discharged_patients, 0) AS discharged_patients
        FROM referrals r
        FULL OUTER JOIN new_starts ns 
            ON r.calendar_date = ns.calendar_date 
            AND r.location_id = ns.location_id 
            AND r.therapy_type_id = ns.therapy_type_id
        FULL OUTER JOIN discharges d 
            ON COALESCE(r.calendar_date, ns.calendar_date) = d.calendar_date 
            AND COALESCE(r.location_id, ns.location_id) = d.location_id 
            AND COALESCE(r.therapy_type_id, ns.therapy_type_id) = d.therapy_type_id
    ),
    
    -- 8. Combine revenue metrics
    revenue_metrics AS (
        SELECT
            COALESCE(dr.calendar_date, er.calendar_date) AS calendar_date,
            COALESCE(dr.location_id, er.location_id) AS location_id,
            COALESCE(dr.product_id, er.product_id) AS product_id,
            COALESCE(dr.therapy_type_id, er.therapy_type_id) AS therapy_type_id,
            COALESCE(dr.payer_id, er.payer_id) AS payer_id,
            COALESCE(dr.drug_revenue, 0) AS drug_revenue,
            COALESCE(er.expected_revenue, 0) AS expected_revenue,
            COALESCE(dr.drug_revenue, 0) + COALESCE(er.expected_revenue, 0) AS total_revenue
        FROM drug_revenue dr
        FULL OUTER JOIN expected_revenue er 
            ON dr.calendar_date = er.calendar_date 
            AND dr.location_id = er.location_id 
            AND dr.product_id = er.product_id 
            AND dr.payer_id = er.payer_id
    ),
    
    -- 9. Create period aggregations for KPIs
    period_metrics AS (
        SELECT
            dd.fiscal_period_key,
            rm.location_id,
            rm.product_id,
            rm.therapy_type_id,
            rm.payer_id,
            SUM(rm.drug_revenue) AS period_drug_revenue,
            SUM(rm.total_revenue) AS period_total_expected_revenue,
            SUM(rm.total_revenue) / MAX(dd.days_in_period) AS period_expected_revenue_per_day
        FROM revenue_metrics rm
        JOIN date_dim dd ON rm.calendar_date = dd.calendar_date
        GROUP BY dd.fiscal_period_key, rm.location_id, rm.product_id, rm.therapy_type_id, rm.payer_id
    ),
    
    -- 10. Get all dimensions for complete coverage
    payers AS (
        SELECT DISTINCT payer_id, payer_name 
        FROM DEV_DB.int.dim_payer
    )
    
    -- 11. Final presentation dataset
    SELECT 
        dd.calendar_date,
        dd.fiscal_period_key,
        dd.fiscal_year,
        dd.fiscal_quarter,
        dd.fiscal_month,
        
        -- Entity dimensions
        COALESCE(pa.location_id, rm.location_id) AS location_id,
        l.location_name,
        rm.product_id,
        p.product_name,
        COALESCE(pa.therapy_type_id, rm.therapy_type_id) AS therapy_id,
        t.therapy_name,
        rm.payer_id,
        py.payer_name,
        
        -- Patient metrics
        COALESCE(pa.discharged_patients, 0) AS discharged_patients,    
        COALESCE(pa.new_starts, 0) AS new_starts,             
        COALESCE(pa.referrals, 0) AS referrals,          
        
        -- Revenue metrics
        COALESCE(rm.drug_revenue, 0) AS drug_revenue,
        COALESCE(rm.total_revenue, 0) AS total_expected_revenue,
        COALESCE(rm.total_revenue / dd.days_in_period, 0) AS expected_revenue_per_day,
        
        -- Period metrics
        COALESCE(pm.period_drug_revenue, 0) AS period_drug_revenue,
        COALESCE(pm.period_total_expected_revenue, 0) AS period_total_expected_revenue,
        COALESCE(pm.period_expected_revenue_per_day, 0) AS period_expected_revenue_per_day
        
    FROM date_dim dd
    LEFT JOIN patient_activity pa ON dd.calendar_date = pa.calendar_date
    LEFT JOIN revenue_metrics rm 
        ON dd.calendar_date = rm.calendar_date
        AND (pa.location_id = rm.location_id OR pa.location_id IS NULL OR rm.location_id IS NULL)
        AND (pa.therapy_type_id = rm.therapy_type_id OR pa.therapy_type_id IS NULL OR rm.therapy_type_id IS NULL)
    LEFT JOIN period_metrics pm
        ON dd.fiscal_period_key = pm.fiscal_period_key
        AND COALESCE(pa.location_id, rm.location_id) = pm.location_id
        AND rm.product_id = pm.product_id
        AND COALESCE(pa.therapy_type_id, rm.therapy_type_id) = pm.therapy_type_id
        AND rm.payer_id = pm.payer_id
    LEFT JOIN DEV_DB.int.dim_location l ON COALESCE(pa.location_id, rm.location_id) = l.location_id
    LEFT JOIN DEV_DB.int.dim_product p ON rm.product_id = p.product_id
    LEFT JOIN DEV_DB.int.dim_therapy t ON COALESCE(pa.therapy_type_id, rm.therapy_type_id) = t.therapy_type_id
    LEFT JOIN payers py ON rm.payer_id = py.payer_id
    ORDER BY dd.calendar_date, location_id, rm.product_id;
END;
$$;