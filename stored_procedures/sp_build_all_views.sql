CREATE OR REPLACE PROCEDURE sp_build_all_views()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    build_message STRING;
    project_root VARCHAR;
BEGIN
    -- Determine project root directory by extracting path from this stored procedure's location
    -- Assuming this stored procedure is in /home/dale/development/dl-analytics/stored_procedures/
    -- We need to go up one directory level to get the project root
    
    project_root := REGEXP_REPLACE(CURRENT_PATH(), '/stored_procedures$', '');
    
    -- Call the dynamic builder with the detected project root
    CALL sp_build_analytics_views_dynamic(project_root) INTO build_message;
    
    RETURN build_message;
END;
$$;