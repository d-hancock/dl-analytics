CREATE OR REPLACE PROCEDURE sp_build_analytics_views_dynamic(
    p_project_root VARCHAR DEFAULT CURRENT_PATH() -- Default to the current path
)
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    build_message STRING;
    model_path STRING;
    current_dir STRING;
    current_file STRING;
    sql_content STRING;
    error_message STRING;
    found_paths ARRAY;
    current_run_order INTEGER := 0;
BEGIN
    build_message := 'CareTend Analytics View Builder (Dynamic Discovery)\n';
    build_message := build_message || '--------------------------------------------\n';
    build_message := build_message || 'Started: ' || CURRENT_TIMESTAMP() || '\n';
    build_message := build_message || 'Project Root: ' || p_project_root || '\n\n';
    
    -- Track successful builds by layer
    LET staging_views_built INTEGER := 0;
    LET intermediate_views_built INTEGER := 0;
    LET marts_views_built INTEGER := 0;
    LET presentation_views_built INTEGER := 0;
    LET total_views_built INTEGER := 0;
    
    -- Create a temporary table to store discovered SQL files and their layer
    CREATE TEMPORARY TABLE IF NOT EXISTS tmp_sql_files (
        file_path VARCHAR,
        layer_name VARCHAR,
        layer_order INTEGER,
        file_name VARCHAR,
        built BOOLEAN DEFAULT FALSE
    );
    
    -- Define paths to discover (in order of dependency)
    found_paths := ARRAY[
        p_project_root || '/models/staging',
        p_project_root || '/models/intermediate',
        p_project_root || '/models/marts/finance',
        p_project_root || '/models/presentation'
    ];
    
    -- Clean up temp table
    TRUNCATE TABLE tmp_sql_files;
    
    -- Loop through each directory and discover .sql files
    FOR dir_index IN 0 TO ARRAY_SIZE(found_paths) - 1 DO
        current_dir := found_paths[dir_index];
        
        -- Determine layer name and order
        LET layer_name VARCHAR := 
            CASE 
                WHEN CONTAINS(current_dir, '/staging') THEN 'staging'
                WHEN CONTAINS(current_dir, '/intermediate') THEN 'intermediate'
                WHEN CONTAINS(current_dir, '/marts') THEN 'marts'
                WHEN CONTAINS(current_dir, '/presentation') THEN 'presentation'
                ELSE 'unknown'
            END;
        
        LET layer_order INTEGER :=
            CASE 
                WHEN CONTAINS(current_dir, '/staging') THEN 1
                WHEN CONTAINS(current_dir, '/intermediate') THEN 2
                WHEN CONTAINS(current_dir, '/marts') THEN 3
                WHEN CONTAINS(current_dir, '/presentation') THEN 4
                ELSE 5
            END;
        
        -- Discover all SQL files in the directory
        -- This is a simplified example - in a real implementation, you'd use SYSTEM$LIST_FILES or similar
        -- to actually discover files in the directory
        
        -- First try to list files in the directory
        BEGIN
            -- Here you would use the filesystem to list files
            -- For illustration, we'll use a simplified approach that assumes we know the file patterns
            
            -- For staging layer
            IF layer_name = 'staging' THEN
                INSERT INTO tmp_sql_files (file_path, layer_name, layer_order, file_name)
                SELECT 
                    current_dir || '/' || f.file_name,
                    layer_name,
                    layer_order,
                    f.file_name
                FROM (
                    -- List of staging files we know exist
                    SELECT 'stg_date_dimension.sql' AS file_name UNION ALL
                    SELECT 'stg_facility_dimension.sql' UNION ALL
                    SELECT 'stg_patient_dimension.sql' UNION ALL
                    SELECT 'stg_payer_dimension.sql' UNION ALL
                    SELECT 'stg_provider_dimension.sql' UNION ALL
                    SELECT 'stg_patient_policy.sql' UNION ALL
                    SELECT 'stg_patient_referrals.sql' UNION ALL
                    SELECT 'stg_encounter_patient_encounter.sql' UNION ALL
                    SELECT 'stg_encounter_discharge_summary.sql' UNION ALL
                    SELECT 'stg_encounter_patient_order.sql' UNION ALL
                    SELECT 'stg_billing_claim.sql' UNION ALL
                    SELECT 'stg_billing_claim_item.sql' UNION ALL
                    SELECT 'stg_party.sql' UNION ALL
                    SELECT 'stg_inventory_item_location_quantity.sql' UNION ALL
                    SELECT 'stg_inventory_transfer.sql' UNION ALL
                    SELECT 'stg_invoice_claim_item_link.sql'
                ) f;
            END IF;
            
            -- For intermediate layer
            IF layer_name = 'intermediate' THEN
                INSERT INTO tmp_sql_files (file_path, layer_name, layer_order, file_name)
                SELECT 
                    current_dir || '/' || f.file_name,
                    layer_name,
                    layer_order,
                    f.file_name
                FROM (
                    -- List of intermediate files we know exist
                    SELECT 'int_dim_date.sql' AS file_name UNION ALL
                    SELECT 'int_dim_location.sql' UNION ALL
                    SELECT 'int_dim_payer.sql' UNION ALL
                    SELECT 'int_dim_product.sql' UNION ALL
                    SELECT 'int_dim_therapy.sql' UNION ALL
                    SELECT 'int_patient_dimension.sql' UNION ALL
                    SELECT 'int_provider_dimension.sql' UNION ALL
                    SELECT 'int_payer_dimension.sql' UNION ALL
                    SELECT 'int_fct_referrals.sql' UNION ALL
                    SELECT 'int_fct_new_starts.sql' UNION ALL
                    SELECT 'int_fct_discharges.sql' UNION ALL
                    SELECT 'int_fct_drug_revenue.sql' UNION ALL
                    SELECT 'int_fct_expected_revenue.sql'
                ) f;
            END IF;
            
            -- For marts layer
            IF layer_name = 'marts' THEN
                INSERT INTO tmp_sql_files (file_path, layer_name, layer_order, file_name)
                SELECT 
                    current_dir || '/' || f.file_name,
                    layer_name,
                    layer_order,
                    f.file_name
                FROM (
                    -- List of marts files we know exist
                    SELECT 'fct_revenue.sql' AS file_name UNION ALL
                    SELECT 'fct_patient_activity.sql' UNION ALL
                    SELECT 'kpi_revenue_metrics.sql' UNION ALL
                    SELECT 'kpi_patient_metrics.sql'
                ) f;
            END IF;
            
            -- For presentation layer
            IF layer_name = 'presentation' THEN
                INSERT INTO tmp_sql_files (file_path, layer_name, layer_order, file_name)
                SELECT 
                    current_dir || '/' || f.file_name,
                    layer_name,
                    layer_order,
                    f.file_name
                FROM (
                    -- List of presentation files we know exist
                    SELECT 'dashboard_financial_executive.sql' AS file_name
                ) f;
            END IF;
            
        EXCEPTION
            WHEN OTHER THEN
                error_message := SQLSTATE || ': ' || SQLERRM;
                build_message := build_message || 'Warning: Error scanning directory ' || current_dir || ' - ' || error_message || '\n';
        END;
    END FOR;
    
    -- Build views layer by layer
    FOR current_layer IN 1 TO 4 DO
        
        -- Set layer header based on current_layer
        CASE current_layer
            WHEN 1 THEN 
                build_message := build_message || '\n1. Building Staging Layer Views\n';
                build_message := build_message || '----------------------------\n';
            WHEN 2 THEN 
                build_message := build_message || '\n2. Building Intermediate Layer Views\n';
                build_message := build_message || '--------------------------------\n';
            WHEN 3 THEN 
                build_message := build_message || '\n3. Building Marts Layer Views\n';
                build_message := build_message || '----------------------------\n';
            WHEN 4 THEN 
                build_message := build_message || '\n4. Building Presentation Layer Views\n';
                build_message := build_message || '----------------------------------\n';
        END CASE;
        
        -- Get all files for this layer
        FOR current_file_rec IN (
            SELECT file_path, file_name 
            FROM tmp_sql_files 
            WHERE layer_order = current_layer
            ORDER BY file_name
        ) DO
            current_file := current_file_rec.file_path;
            
            BEGIN
                -- Read the SQL file content
                -- In a real implementation, this would use SYSTEM$READ_FILE or a similar function
                LET sql_content STRING := SYSTEM$READ_FILE(current_file);
                
                -- Execute the SQL code
                EXECUTE IMMEDIATE sql_content;
                
                -- Update build counts
                CASE current_layer
                    WHEN 1 THEN staging_views_built := staging_views_built + 1;
                    WHEN 2 THEN intermediate_views_built := intermediate_views_built + 1;
                    WHEN 3 THEN marts_views_built := marts_views_built + 1;
                    WHEN 4 THEN presentation_views_built := presentation_views_built + 1;
                END CASE;
                
                -- Mark as built in the temp table
                UPDATE tmp_sql_files 
                SET built = TRUE 
                WHERE file_path = current_file;
                
                -- Add to build message
                build_message := build_message || '✓ Built: ' || current_file_rec.file_name || '\n';
            EXCEPTION
                WHEN OTHER THEN
                    error_message := SQLSTATE || ': ' || SQLERRM;
                    build_message := build_message || '✗ Failed: ' || current_file_rec.file_name || ' - ' || error_message || '\n';
            END;
        END FOR;
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
    
    -- Clean up
    DROP TABLE IF EXISTS tmp_sql_files;
    
    RETURN build_message;
END;
$$;