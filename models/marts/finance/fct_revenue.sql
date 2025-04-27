-- =================================================================================
-- Finance Mart Layer: Revenue Facts
-- Name: fct_revenue
-- Source Tables: 
--   • int_fct_drug_revenue - Drug-related revenue metrics from drug claims
--   • int_fct_expected_revenue - Expected revenue metrics for forecasting
--   • int_dim_date - Date dimension for time-based analysis
--   • int_dim_location - Location dimension for facility-based filtering
--   • int_dim_product - Product dimension for drug/item filtering
--   • int_dim_therapy - Therapy dimension for treatment categorization
--   • int_dim_payer - Payer dimension for insurance filtering
-- Purpose: 
--   Provide daily summable revenue facts that can be aggregated across
--   multiple dimensions for financial analysis.
-- Key Features:
--   • Daily grain for time-series analysis
--   • Complete dimensional coverage (location, product, therapy, payer)
--   • Clear separation of drug and non-drug revenue
--   • Expected revenue calculations for forecasting
-- Usage:
--   • Feed dashboard_financial_executive for revenue metrics
--   • Support ad-hoc revenue analysis across all dimensions
-- =================================================================================

WITH revenue_base AS (
    -- Combine drug revenue and expected revenue at daily grain
    SELECT
        d.calendar_date,
        d.fiscal_period_key,
        dr.product_id,
        dr.patient_id,
        dr.patient_policy_id,
        dr.quantity,
        dr.unit_price,
        dr.total_price AS drug_revenue,
        0 AS non_drug_revenue,
        dr.transaction_date AS revenue_date,
        'Drug' AS revenue_type
    FROM DEV_DB.int.fct_drug_revenue dr
    JOIN DEV_DB.int.dim_date d ON dr.transaction_date = d.calendar_date
    
    UNION ALL
    
    SELECT
        d.calendar_date,
        d.fiscal_period_key,
        er.product_id,
        er.patient_id,
        er.patient_policy_id,
        er.quantity,
        er.unit_price,
        0 AS drug_revenue,
        er.expected_revenue AS non_drug_revenue,
        er.revenue_date,
        'Non-Drug' AS revenue_type
    FROM DEV_DB.int.fct_expected_revenue er
    JOIN DEV_DB.int.dim_date d ON er.revenue_date = d.calendar_date
    WHERE er.product_id NOT IN (
        -- Exclude products that are already counted as drug revenue
        SELECT DISTINCT product_id FROM DEV_DB.int.fct_drug_revenue
    )
)

SELECT
    -- Time dimension
    rb.calendar_date,
    rb.fiscal_period_key,
    d.fiscal_year,
    d.fiscal_quarter,
    d.fiscal_month,
    
    -- Entity dimensions
    rb.product_id,
    p.product_name,
    COALESCE(p.product_category, 'Unknown') AS product_category,
    
    -- Get therapy info from product when available
    t.therapy_type_id,
    t.therapy_class,
    
    -- Location details from patient info
    pat.team_id AS location_id,
    
    -- Payer information
    rb.patient_policy_id AS payer_id,
    pay.payer_name,
    pay.payer_category,
    
    -- Revenue metrics
    SUM(rb.drug_revenue) AS drug_revenue,
    SUM(rb.non_drug_revenue) AS non_drug_revenue,
    SUM(rb.drug_revenue + rb.non_drug_revenue) AS total_revenue,
    
    -- Per-day calculations - these will be aggregated at presentation layer
    SUM(rb.drug_revenue) / COUNT(DISTINCT rb.calendar_date) AS drug_revenue_per_day,
    SUM(rb.non_drug_revenue) / COUNT(DISTINCT rb.calendar_date) AS non_drug_revenue_per_day,
    SUM(rb.drug_revenue + rb.non_drug_revenue) / COUNT(DISTINCT rb.calendar_date) AS total_revenue_per_day,
    
    -- Flag to identify drug revenue for filtering
    CASE WHEN SUM(rb.drug_revenue) > 0 THEN TRUE ELSE FALSE END AS has_drug_revenue
    
FROM revenue_base rb
JOIN DEV_DB.int.dim_date d ON rb.calendar_date = d.calendar_date
LEFT JOIN DEV_DB.int.dim_product p ON rb.product_id = p.product_id
LEFT JOIN DEV_DB.int.dim_therapy t ON p.product_category = 'Drug' -- Join condition needs refinement based on actual data model
LEFT JOIN DEV_DB.int.patient_dimension pat ON rb.patient_id = pat.patient_id
LEFT JOIN DEV_DB.int.dim_payer pay ON rb.patient_policy_id = pay.payer_id
GROUP BY
    rb.calendar_date,
    rb.fiscal_period_key,
    d.fiscal_year,
    d.fiscal_quarter,
    d.fiscal_month,
    rb.product_id,
    p.product_name,
    p.product_category,
    t.therapy_type_id,
    t.therapy_class,
    pat.team_id,
    rb.patient_policy_id,
    pay.payer_name,
    pay.payer_category;