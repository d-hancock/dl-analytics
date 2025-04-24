-- Final tailored model for the financial executive dashboard
-- Supports filtering, slicing, and Tableau-ready structure
-- This view is designed to provide one row per combination of key dimensions (Date × Location × Product/Therapy × Payer)
-- Each KPI is represented as its own column for easy use in Tableau dashboards
-- Filters are applied to limit the data to the current fiscal year

SELECT 
    d.calendar_date, -- Day-level date
    d.fiscal_period_key, -- Surrogate for fiscal period
    d.period_start_date, -- Start date of the fiscal period
    d.period_end_date, -- End date of the fiscal period
    l.location_id, -- Facility or branch identifier
    l.location_name, -- Facility or branch name
    p.product_id, -- Drug or supply item identifier
    p.product_name, -- Drug or supply item name
    t.therapy_code, -- Therapy type code (e.g., HcPc)
    t.therapy_name, -- Therapy type name
    payer.payer_id, -- Insurance program identifier
    payer.payer_name, -- Insurance program name
    kpi.discharged_patients, -- KPI: Count of discharged patients
    kpi.new_starts, -- KPI: Count of new patient starts
    kpi.referrals, -- KPI: Count of referrals
    kpi.expected_revenue_per_day, -- KPI: Expected revenue per day
    kpi.drug_revenue -- KPI: Total drug revenue
FROM mart_patient_activity kpi
JOIN dim_date d ON kpi.calendar_date = d.calendar_date
JOIN dim_location l ON kpi.location_id = l.location_id
JOIN dim_product p ON kpi.product_id = p.product_id
JOIN dim_therapy t ON kpi.therapy_code = t.therapy_code
JOIN dim_payer payer ON kpi.payer_id = payer.payer_id
WHERE d.calendar_date BETWEEN '2025-01-01' AND '2025-12-31';