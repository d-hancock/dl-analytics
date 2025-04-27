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
    -- 1. Date dimension with fiscal periods directly from source
    WITH date_dim AS (
        SELECT
            calendar_date,
            fiscal_period_id AS fiscal_period_key,
            fiscal_year,
            fiscal_quarter,
            fiscal_month,
            MIN(calendar_date) OVER (PARTITION BY fiscal_period_id) AS period_start_date,
            MAX(calendar_date) OVER (PARTITION BY fiscal_period_id) AS period_end_date,
            COUNT(*) OVER (PARTITION BY fiscal_period_id) AS days_in_period
        FROM OLTP_DB.Reference.CalendarDates
        WHERE (calendar_date BETWEEN p_start_date AND p_end_date)
           OR (p_fiscal_year IS NOT NULL AND fiscal_year = p_fiscal_year)
    ),
    
    -- 2. Get patient referrals directly from source
    referrals AS (
        SELECT
            d.calendar_date,
            pr.team_id AS location_id,
            po.therapy_type_id,
            COUNT(CASE WHEN pr.referral_status_id = 1 THEN 1 END) AS referrals -- Pending status
        FROM OLTP_DB.Patient.PatientReferrals pr
        JOIN OLTP_DB.Prescription.PatientOrder po ON pr.patient_id = po.patient_id
        JOIN date_dim d ON pr.referral_date = d.calendar_date
        WHERE pr.record_status = 1 -- Active records only
        GROUP BY d.calendar_date, pr.team_id, po.therapy_type_id
    ),
    
    -- 3. Get new patient starts directly from source
    new_starts AS (
        SELECT
            d.calendar_date,
            p.assigned_team_id AS team_id,
            po.therapy_type_id,
            COUNT(DISTINCT p.patient_id) AS new_starts
        FROM OLTP_DB.Patient.Patient p
        JOIN OLTP_DB.Prescription.PatientOrder po ON p.patient_id = po.patient_id
        JOIN date_dim d ON p.admission_date = d.calendar_date
        WHERE p.record_status = 1 -- Active records only
        AND NOT EXISTS (
            -- Looking back 365 days to ensure this is truly a new start
            SELECT 1 FROM OLTP_DB.Patient.PatientStatusHistory psh
            WHERE psh.patient_id = p.patient_id
            AND psh.status_date < p.admission_date
            AND psh.status_date >= DATEADD(day, -365, p.admission_date)
        )
        GROUP BY d.calendar_date, p.assigned_team_id, po.therapy_type_id
    ),
    
    -- 4. Get patient discharges directly from source
    discharges AS (
        SELECT
            d.calendar_date,
            p.assigned_team_id AS team_id,
            po.therapy_type_id,
            COUNT(DISTINCT p.patient_id) AS discharged_patients
        FROM OLTP_DB.Encounter.DischargeSummary ds
        JOIN OLTP_DB.Patient.Patient p ON ds.patient_id = p.patient_id
        JOIN OLTP_DB.Prescription.PatientOrder po ON p.patient_id = po.patient_id
        JOIN date_dim d ON ds.discharge_date = d.calendar_date
        WHERE ds.record_status = 1 -- Active records only
        GROUP BY d.calendar_date, p.assigned_team_id, po.therapy_type_id
    ),
    
    -- 5. Get drug revenue directly from source
    drug_revenue AS (
        SELECT
            d.calendar_date,
            c.facility_id AS location_id,
            ci.product_id,
            p.product_category_id AS therapy_type_id,
            c.payer_id,
            SUM(ci.quantity * ci.unit_price * (1 - ci.discount_percentage/100)) AS drug_revenue
        FROM OLTP_DB.Billing.ClaimItem ci
        JOIN OLTP_DB.Billing.Claim c ON ci.claim_id = c.claim_id
        JOIN OLTP_DB.Catalog.Product p ON ci.product_id = p.product_id
        JOIN date_dim d ON c.service_date = d.calendar_date
        WHERE ci.record_status = 1 -- Active records only
        AND p.product_category_id IN (SELECT category_id FROM OLTP_DB.Catalog.ProductCategory WHERE category_type = 'Drug')
        GROUP BY d.calendar_date, c.facility_id, ci.product_id, p.product_category_id, c.payer_id
    ),
    
    -- 6. Get expected revenue directly from source
    expected_revenue AS (
        SELECT
            d.calendar_date,
            c.facility_id AS location_id,
            ci.product_id,
            p.product_category_id AS therapy_type_id,
            c.payer_id,
            SUM(ci.expected_reimbursement) AS expected_revenue
        FROM OLTP_DB.Billing.ClaimItem ci
        JOIN OLTP_DB.Billing.Claim c ON ci.claim_id = c.claim_id
        JOIN OLTP_DB.Catalog.Product p ON ci.product_id = p.product_id
        JOIN date_dim d ON c.service_date = d.calendar_date
        WHERE ci.record_status = 1 -- Active records only
        GROUP BY d.calendar_date, c.facility_id, ci.product_id, p.product_category_id, c.payer_id
    ),
    
    -- 7. Combine patient activity metrics
    patient_activity AS (
        SELECT
            COALESCE(r.calendar_date, ns.calendar_date, d.calendar_date) AS calendar_date,
            COALESCE(r.location_id, ns.team_id, d.team_id) AS location_id,
            COALESCE(r.therapy_type_id, ns.therapy_type_id, d.therapy_type_id) AS therapy_type_id,
            COALESCE(r.referrals, 0) AS referrals,
            COALESCE(ns.new_starts, 0) AS new_starts,
            COALESCE(d.discharged_patients, 0) AS discharged_patients
        FROM referrals r
        FULL OUTER JOIN new_starts ns 
            ON r.calendar_date = ns.calendar_date 
            AND r.location_id = ns.team_id 
            AND r.therapy_type_id = ns.therapy_type_id
        FULL OUTER JOIN discharges d 
            ON COALESCE(r.calendar_date, ns.calendar_date) = d.calendar_date 
            AND COALESCE(r.location_id, ns.team_id) = d.team_id 
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
    
    -- 10. Get dimension tables directly from source
    locations AS (
        SELECT 
            facility_id AS location_id, 
            facility_name AS location_name 
        FROM OLTP_DB.Facility.Facility
        WHERE record_status = 1
    ),
    
    products AS (
        SELECT 
            product_id, 
            product_name 
        FROM OLTP_DB.Catalog.Product
        WHERE record_status = 1
    ),
    
    therapies AS (
        SELECT 
            therapy_type_id, 
            therapy_name 
        FROM OLTP_DB.Therapy.TherapyType
        WHERE record_status = 1
    ),
    
    payers AS (
        SELECT 
            payer_id, 
            payer_name 
        FROM OLTP_DB.Billing.Payer
        WHERE record_status = 1
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
    LEFT JOIN locations l ON COALESCE(pa.location_id, rm.location_id) = l.location_id
    LEFT JOIN products p ON rm.product_id = p.product_id
    LEFT JOIN therapies t ON COALESCE(pa.therapy_type_id, rm.therapy_type_id) = t.therapy_id
    LEFT JOIN payers py ON rm.payer_id = py.payer_id
    ORDER BY dd.calendar_date, location_id, rm.product_id;
END;
$$;