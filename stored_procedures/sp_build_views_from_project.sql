CREATE OR REPLACE PROCEDURE sp_build_views_from_project(
    p_project_root VARCHAR -- Root path to the project, e.g., '/home/dale/development/dl-analytics'
)
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    build_message STRING;
    sql_content STRING;
    file_path STRING;
    error_message STRING;
    staging_files ARRAY;
    intermediate_files ARRAY;
    marts_files ARRAY;
    presentation_files ARRAY;
BEGIN
    build_message := 'CareTend Analytics View Builder (Project-Based)\n';
    build_message := build_message || '--------------------------------------\n';
    build_message := build_message || 'Started: ' || CURRENT_TIMESTAMP() || '\n';
    build_message := build_message || 'Project Root: ' || p_project_root || '\n\n';
    
    -- Track successful builds
    LET staging_views_built INTEGER := 0;
    LET intermediate_views_built INTEGER := 0;
    LET marts_views_built INTEGER := 0;
    LET presentation_views_built INTEGER := 0;

    -- Define staging layer files (relative paths)
    staging_files := ARRAY[
        '/models/staging/stg_date_dimension.sql',
        '/models/staging/stg_facility_dimension.sql',
        '/models/staging/stg_patient_dimension.sql',
        '/models/staging/stg_payer_dimension.sql',
        '/models/staging/stg_provider_dimension.sql',
        '/models/staging/stg_patient_policy.sql',
        '/models/staging/stg_patient_referrals.sql',
        '/models/staging/stg_encounter_patient_encounter.sql',
        '/models/staging/stg_encounter_discharge_summary.sql',
        '/models/staging/stg_encounter_patient_order.sql',
        '/models/staging/stg_billing_claim.sql',
        '/models/staging/stg_billing_claim_item.sql',
        '/models/staging/stg_party.sql',
        '/models/staging/stg_inventory_item_location_quantity.sql',
        '/models/staging/stg_inventory_transfer.sql',
        '/models/staging/stg_invoice_claim_item_link.sql'
    ];
    
    -- Define intermediate layer files
    intermediate_files := ARRAY[
        '/models/intermediate/int_dim_date.sql',
        '/models/intermediate/int_dim_location.sql',
        '/models/intermediate/int_dim_payer.sql',
        '/models/intermediate/int_dim_product.sql',
        '/models/intermediate/int_dim_therapy.sql',
        '/models/intermediate/int_patient_dimension.sql',
        '/models/intermediate/int_provider_dimension.sql',
        '/models/intermediate/int_payer_dimension.sql',
        '/models/intermediate/int_fct_referrals.sql',
        '/models/intermediate/int_fct_new_starts.sql',
        '/models/intermediate/int_fct_discharges.sql',
        '/models/intermediate/int_fct_drug_revenue.sql',
        '/models/intermediate/int_fct_expected_revenue.sql'
    ];
    
    -- Define marts layer files
    marts_files := ARRAY[
        '/models/marts/finance/fct_revenue.sql',
        '/models/marts/finance/fct_patient_activity.sql',
        '/models/marts/finance/kpi_revenue_metrics.sql',
        '/models/marts/finance/kpi_patient_metrics.sql'
    ];
    
    -- Define presentation layer files
    presentation_files := ARRAY[
        '/models/presentation/dashboard_financial_executive.sql'
    ];

    -- First, process the staging layer
    build_message := build_message || '1. Building Staging Layer Views\n';
    build_message := build_message || '----------------------------\n';
    
    FOR i IN 0 TO ARRAY_SIZE(staging_files) - 1 DO
        file_path := p_project_root || staging_files[i];
        
        -- Process staging layer file
        BEGIN
            -- Read the SQL file content
            LET sql_content STRING := SYSTEM$READ_FILE(file_path);
            
            -- Execute the SQL code
            EXECUTE IMMEDIATE sql_content;
            
            staging_views_built := staging_views_built + 1;
            build_message := build_message || '✓ Built: ' || REGEXP_SUBSTR(file_path, '[^/]+$') || '\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: ' || REGEXP_SUBSTR(file_path, '[^/]+$') || ' - ' || error_message || '\n';
        END;
    END FOR;
    
    -- Second, process the intermediate layer
    build_message := build_message || '\n2. Building Intermediate Layer Views\n';
    build_message := build_message || '--------------------------------\n';
    
    FOR i IN 0 TO ARRAY_SIZE(intermediate_files) - 1 DO
        file_path := p_project_root || intermediate_files[i];
        
        -- Process intermediate layer file
        BEGIN
            -- Read the SQL file content
            LET sql_content STRING := SYSTEM$READ_FILE(file_path);
            
            -- Execute the SQL code
            EXECUTE IMMEDIATE sql_content;
            
            intermediate_views_built := intermediate_views_built + 1;
            build_message := build_message || '✓ Built: ' || REGEXP_SUBSTR(file_path, '[^/]+$') || '\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: ' || REGEXP_SUBSTR(file_path, '[^/]+$') || ' - ' || error_message || '\n';
        END;
    END FOR;
    
    -- Third, process the marts layer
    build_message := build_message || '\n3. Building Marts Layer Views\n';
    build_message := build_message || '----------------------------\n';
    
    FOR i IN 0 TO ARRAY_SIZE(marts_files) - 1 DO
        file_path := p_project_root || marts_files[i];
        
        -- Process marts layer file
        BEGIN
            -- Read the SQL file content
            LET sql_content STRING := SYSTEM$READ_FILE(file_path);
            
            -- Execute the SQL code
            EXECUTE IMMEDIATE sql_content;
            
            marts_views_built := marts_views_built + 1;
            build_message := build_message || '✓ Built: ' || REGEXP_SUBSTR(file_path, '[^/]+$') || '\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: ' || REGEXP_SUBSTR(file_path, '[^/]+$') || ' - ' || error_message || '\n';
        END;
    END FOR;
    
    -- Fourth, process the presentation layer
    build_message := build_message || '\n4. Building Presentation Layer Views\n';
    build_message := build_message || '----------------------------------\n';
    
    FOR i IN 0 TO ARRAY_SIZE(presentation_files) - 1 DO
        file_path := p_project_root || presentation_files[i];
        
        -- Process presentation layer file
        BEGIN
            -- Read the SQL file content
            LET sql_content STRING := SYSTEM$READ_FILE(file_path);
            
            -- Execute the SQL code
            EXECUTE IMMEDIATE sql_content;
            
            presentation_views_built := presentation_views_built + 1;
            build_message := build_message || '✓ Built: ' || REGEXP_SUBSTR(file_path, '[^/]+$') || '\n';
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || '✗ Failed: ' || REGEXP_SUBSTR(file_path, '[^/]+$') || ' - ' || error_message || '\n';
        END;
    END FOR;
    
    -- Generate build summary
    build_message := build_message || '\n\nBuild Summary\n';
    build_message := build_message || '------------\n';
    build_message := build_message || 'Staging Views Built: ' || staging_views_built || '\n';
    build_message := build_message || 'Intermediate Views Built: ' || intermediate_views_built || '\n';
    build_message := build_message || 'Marts Views Built: ' || marts_views_built || '\n';
    build_message := build_message || 'Presentation Views Built: ' || presentation_views_built || '\n';
    build_message := build_message || 'Total Views Built: ' || (staging_views_built + intermediate_views_built + marts_views_built + presentation_views_built) || '\n';
    build_message := build_message || '\nCompleted: ' || CURRENT_TIMESTAMP();
    
    RETURN build_message;
END;
$$;