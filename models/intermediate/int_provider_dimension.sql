-- =================================================================================
-- Intermediate Provider Dimension View
-- Name: int_provider_dimension
-- Source Tables: stg.employee_dimension, stg.referring_provider_dimension
-- Purpose: Consolidate internal employees (like RNs, AEs) and external referring providers into a single dimension.
-- Key Transformations:
--   • Union employee and referring provider data.
--   • Standardize key fields like provider_id, provider_name, provider_type.
--   • Add flags for specific roles (e.g., is_rn, is_ae, is_referring_provider).
-- Usage:
--   • Link to fact tables for analysis by provider type (internal vs. external).
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.provider_dimension AS

WITH combined_providers AS (
    -- Internal Employees
    SELECT
        employee_id         AS provider_sk, -- Surrogate Key
        employee_id         AS provider_id, -- Natural Key (Employee ID)
        employee_name       AS provider_name,
        'Internal'          AS provider_source, -- Indicate source
        job_title,
        department,
        hire_date,
        termination_date,
        is_active,
        is_account_executive,
        is_registered_nurse,
        FALSE               AS is_referring_provider, -- Flag for type
        NULL                AS npi, -- NPI not applicable to all internal staff
        NULL                AS specialty, -- Specialty not typically tracked for internal staff here
        created_date,
        modified_date,
        record_status
    FROM DEV_DB.stg.employee_dimension
    WHERE record_status = 1

    UNION ALL

    -- External Referring Providers
    SELECT
        referring_provider_id AS provider_sk, -- Surrogate Key
        referring_provider_id AS provider_id, -- Natural Key (Referring Provider ID)
        provider_name,
        'External'            AS provider_source, -- Indicate source
        'Referring Provider'  AS job_title, -- Standardized job title
        NULL                  AS department,
        NULL                  AS hire_date,
        NULL                  AS termination_date,
        is_active,
        FALSE                 AS is_account_executive,
        FALSE                 AS is_registered_nurse,
        TRUE                  AS is_referring_provider, -- Flag for type
        npi,
        specialty,
        created_date,
        modified_date,
        record_status
    FROM DEV_DB.stg.referring_provider_dimension
    WHERE record_status = 1
)
SELECT
    provider_sk,
    provider_id,
    provider_name,
    provider_source,
    job_title,
    department,
    hire_date,
    termination_date,
    is_active,
    is_account_executive,
    is_registered_nurse,
    is_referring_provider,
    npi,
    specialty,
    created_date,
    modified_date,
    record_status
FROM combined_providers;
