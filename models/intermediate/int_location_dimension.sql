-- =================================================================================
-- Intermediate Location Dimension View
-- Name: int_location_dimension
-- Source Tables: stg.location_dimension
-- Purpose: Standardize location attributes for reporting.
-- Key Transformations:
--   • Use refactored staging view with corrected schema references.
--   • Select relevant location fields.
-- Usage:
--   • Join to fact tables for location-based analysis (e.g., patient address, service location).
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.location_dimension AS
SELECT
    location_id,
    location_name,
    address_line_1,
    address_line_2,
    city,
    state,
    zip_code,
    county,
    country,
    phone_number,
    fax_number,
    is_primary_location,
    is_billing_location,
    is_shipping_location,
    created_date,
    modified_date,
    record_status
FROM DEV_DB.stg.location_dimension
WHERE record_status = 1;
