-- =================================================================================
-- Stored Procedure: generate_tableau_analytics_dataset
-- Purpose: Produces a consolidated analytical dataset for Tableau dashboards
--          by joining all relevant marts and dimensions.
--
-- Parameters:
--   • p_start_date DATE - The start date for data extraction (defaults to start of current fiscal year)
--   • p_end_date DATE - The end date for data extraction (defaults to end of current fiscal year)
--   • p_location_ids VARCHAR - Comma-separated list of location_ids to filter by (optional)
--   • p_payer_ids VARCHAR - Comma-separated list of payer_ids to filter by (optional)
--   • p_product_ids VARCHAR - Comma-separated list of product_ids to filter by (optional)
--   • p_therapy_codes VARCHAR - Comma-separated list of therapy_codes to filter by (optional)
--
-- Output: 
--   Materialized result set containing all dimensions and metrics needed for
--   financial executive dashboard visualization in Tableau
-- =================================================================================

CREATE OR REPLACE PROCEDURE DEV_DB.admin.generate_tableau_analytics_dataset(
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_location_ids VARCHAR DEFAULT NULL,
    p_payer_ids VARCHAR DEFAULT NULL, 
    p_product_ids VARCHAR DEFAULT NULL,
    p_therapy_codes VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    calendar_date DATE,
    fiscal_period_key VARCHAR,
    period_start_date DATE,
    period_end_date DATE,
    location_id VARCHAR, 
    location_name VARCHAR,
    product_id VARCHAR,
    product_name VARCHAR,
    therapy_code VARCHAR,
    therapy_name VARCHAR,
    payer_id VARCHAR,
    payer_name VARCHAR,
    discharged_patients INTEGER,
    new_starts INTEGER,
    referrals INTEGER,
    expected_revenue_per_day DECIMAL(18,2),
    drug_revenue DECIMAL(18,2)
)
LANGUAGE SQL
AS
$$
DECLARE
    v_start_date DATE;
    v_end_date DATE;
BEGIN
    -- Set default date range if not provided (current fiscal year)
    IF (p_start_date IS NULL) THEN
        v_start_date := DATEADD(YEAR, 2025 - EXTRACT(YEAR FROM CURRENT_DATE()), DATE_TRUNC('YEAR', CURRENT_DATE()));
    ELSE
        v_start_date := p_start_date;
    END IF;
    
    IF (p_end_date IS NULL) THEN
        v_end_date := DATEADD(YEAR, 2025 - EXTRACT(YEAR FROM CURRENT_DATE()) + 1, DATE_TRUNC('YEAR', CURRENT_DATE())) - 1;
    ELSE
        v_end_date := p_end_date;
    END IF;
    
    -- Create temporary tables for parameter parsing if filters are provided
    IF (p_location_ids IS NOT NULL) THEN
        CREATE TEMPORARY TABLE temp_location_filter AS
        SELECT TRIM(value) AS location_id 
        FROM TABLE(SPLIT_TO_TABLE(p_location_ids, ','));
    END IF;
    
    IF (p_payer_ids IS NOT NULL) THEN
        CREATE TEMPORARY TABLE temp_payer_filter AS
        SELECT TRIM(value) AS payer_id 
        FROM TABLE(SPLIT_TO_TABLE(p_payer_ids, ','));
    END IF;
    
    IF (p_product_ids IS NOT NULL) THEN
        CREATE TEMPORARY TABLE temp_product_filter AS
        SELECT TRIM(value) AS product_id 
        FROM TABLE(SPLIT_TO_TABLE(p_product_ids, ','));
    END IF;
    
    IF (p_therapy_codes IS NOT NULL) THEN
        CREATE TEMPORARY TABLE temp_therapy_filter AS
        SELECT TRIM(value) AS therapy_code 
        FROM TABLE(SPLIT_TO_TABLE(p_therapy_codes, ','));
    END IF;
    
    -- Return the final consolidated dataset with all dimensions and metrics
    RETURN TABLE(
        WITH payers AS (
            SELECT DISTINCT payer_id, payer_name 
            FROM dim_payer
            WHERE p_payer_ids IS NULL OR payer_id IN (SELECT payer_id FROM temp_payer_filter)
        )
        
        SELECT 
            d.calendar_date,
            d.fiscal_period_key,
            d.period_start_date,
            d.period_end_date,
            
            -- Dimension attributes (using dimension table values preferentially, falling back to mart values)
            COALESCE(l.location_id, ma.location_id, ra.location_id) AS location_id,            
            COALESCE(l.location_name, ma.location_name, ra.location_name) AS location_name,            
            COALESCE(p.product_id, ma.product_id, ra.product_id) AS product_id,                
            COALESCE(p.product_name, ma.product_name, ra.product_name) AS product_name,                
            COALESCE(t.therapy_code, ma.therapy_code) AS therapy_code,            
            COALESCE(t.therapy_name, ma.therapy_name) AS therapy_name,            
            py.payer_id,            
            py.payer_name,          
            
            -- KPI metrics (using COALESCE to ensure zero values instead of nulls)
            COALESCE(ma.discharged_patients, 0) AS discharged_patients,    
            COALESCE(ma.new_starts, 0) AS new_starts,             
            COALESCE(ma.referrals, 0) AS referrals,              
            COALESCE(ra.expected_revenue_per_day, 0) AS expected_revenue_per_day,
            COALESCE(ra.drug_revenue, 0) AS drug_revenue            
        
        FROM dim_date d
        
        -- Join to both marts using calendar_date
        LEFT JOIN mart_patient_activity ma 
            ON d.calendar_date = ma.calendar_date
        LEFT JOIN mart_revenue_analysis ra 
            ON d.calendar_date = ra.calendar_date 
            -- Join conditions when location and product exist in both marts
            AND (ma.location_id = ra.location_id OR ma.location_id IS NULL OR ra.location_id IS NULL)
            AND (ma.product_id = ra.product_id OR ma.product_id IS NULL OR ra.product_id IS NULL)
        
        -- Join to dimensions for preferred attribute values
        LEFT JOIN dim_location l 
            ON COALESCE(ma.location_id, ra.location_id) = l.location_id
        LEFT JOIN dim_product p 
            ON COALESCE(ma.product_id, ra.product_id) = p.product_id
        LEFT JOIN dim_therapy t 
            ON ma.therapy_code = t.therapy_code
        CROSS JOIN payers py  -- Join all payers for complete dimensional coverage
        
        WHERE d.calendar_date BETWEEN v_start_date AND v_end_date
        -- Apply dimensional filters if provided
        AND (p_location_ids IS NULL OR COALESCE(l.location_id, ma.location_id, ra.location_id) IN (SELECT location_id FROM temp_location_filter))
        AND (p_product_ids IS NULL OR COALESCE(p.product_id, ma.product_id, ra.product_id) IN (SELECT product_id FROM temp_product_filter))
        AND (p_therapy_codes IS NULL OR COALESCE(t.therapy_code, ma.therapy_code) IN (SELECT therapy_code FROM temp_therapy_filter))
    );
    
    -- Drop temporary tables if they were created
    IF (p_location_ids IS NOT NULL) THEN
        DROP TABLE IF EXISTS temp_location_filter;
    END IF;
    
    IF (p_payer_ids IS NOT NULL) THEN
        DROP TABLE IF EXISTS temp_payer_filter;
    END IF;
    
    IF (p_product_ids IS NOT NULL) THEN
        DROP TABLE IF EXISTS temp_product_filter;
    END IF;
    
    IF (p_therapy_codes IS NOT NULL) THEN
        DROP TABLE IF EXISTS temp_therapy_filter;
    END IF;
END;
$$;

-- =================================================================================
-- Example usage:
-- =================================================================================

-- 1. Generate dataset for current fiscal year (default)
-- CALL DEV_DB.admin.generate_tableau_analytics_dataset();

-- 2. Generate dataset for a specific date range
-- CALL DEV_DB.admin.generate_tableau_analytics_dataset('2025-01-01', '2025-03-31');

-- 3. Generate dataset for specific locations
-- CALL DEV_DB.admin.generate_tableau_analytics_dataset(NULL, NULL, '100,101,102');

-- 4. Generate dataset for specific payers and products
-- CALL DEV_DB.admin.generate_tableau_analytics_dataset(NULL, NULL, NULL, '50,51', '200,201');

-- 5. Export to a table for Tableau consumption
-- CREATE OR REPLACE TABLE DEV_DB.tableau.financial_exec_dashboard AS
-- SELECT * FROM TABLE(DEV_DB.admin.generate_tableau_analytics_dataset());