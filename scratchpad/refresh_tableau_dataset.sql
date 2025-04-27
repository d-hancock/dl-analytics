-- =================================================================================
-- Script: Refresh Tableau Analytics Dataset
-- Purpose: Creates or refreshes the materialized dataset table for Tableau
--          dashboards by executing the generate_tableau_analytics_dataset procedure
--
-- Usage: Execute this script on a schedule (e.g., nightly) to refresh the
--        analytics dataset for Tableau dashboards with the latest data
-- =================================================================================

-- Create the tableau schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS DEV_DB.tableau;

-- Create or replace the dashboard dataset table
CREATE OR REPLACE TABLE DEV_DB.tableau.financial_exec_dashboard AS
SELECT * FROM TABLE(DEV_DB.admin.generate_tableau_analytics_dataset());

-- Grant appropriate permissions for Tableau service accounts
GRANT SELECT ON TABLE DEV_DB.tableau.financial_exec_dashboard TO ROLE TABLEAU_VIEWER;

-- Log the refresh operation
INSERT INTO DEV_DB.admin.data_refresh_log (
    table_name,
    refresh_timestamp,
    row_count,
    refresh_type,
    refresh_status
)
SELECT 
    'DEV_DB.tableau.financial_exec_dashboard',
    CURRENT_TIMESTAMP(),
    (SELECT COUNT(*) FROM DEV_DB.tableau.financial_exec_dashboard),
    'SCHEDULED',
    'SUCCESS';

-- Output success message
SELECT 
    'Tableau financial executive dashboard dataset refreshed successfully at ' || 
    CURRENT_TIMESTAMP() || 
    ' with ' || 
    (SELECT COUNT(*) FROM DEV_DB.tableau.financial_exec_dashboard) || 
    ' rows.' AS refresh_status;