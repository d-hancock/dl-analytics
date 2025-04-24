-- Model: int_dim_location
-- Location: models/intermediate/
-- Materialization: view
-- Purpose: Centralized location dimension providing facility or branch attributes.
-- Inputs:
--   - stg_party: Staging table containing raw location data.
-- Outputs:
--   - location_id: Unique identifier for each location.
--   - location_name: Human-readable name for each location.

CREATE OR REPLACE VIEW int_dim_location AS
SELECT DISTINCT
    location_id,
    location_name
FROM
    stg_party;