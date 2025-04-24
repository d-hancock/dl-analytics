-- Denormalized table combining discharges, new starts, and referrals for patient activity analysis
-- This table is designed to support reporting and analysis by combining key dimensions and metrics
-- Each row represents a unique combination of Date × Location × Product × Therapy

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
    SUM(f.discharged_patients) AS discharged_patients, -- Total discharged patients
    SUM(f.new_starts) AS new_starts, -- Total new patient starts
    SUM(f.referrals) AS referrals -- Total referrals
FROM dim_date d
JOIN dim_location l ON d.calendar_date = l.calendar_date
JOIN dim_product p ON l.location_id = p.location_id
JOIN dim_therapy t ON p.product_id = t.product_id
JOIN fct_discharges f ON t.therapy_code = f.therapy_code
GROUP BY d.calendar_date, l.location_id, p.product_id, t.therapy_code;