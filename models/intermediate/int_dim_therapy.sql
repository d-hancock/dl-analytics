-- Model: int_dim_therapy
-- Location: models/intermediate/
-- Materialization: view
-- Purpose: Centralized therapy dimension providing therapy code and name attributes.
-- Inputs:
--   - therapy_lookup: Lookup table for therapy details.
-- Outputs:
--   - therapy_code: Unique code for therapies (e.g., HcPc).
--   - therapy_name: Human-readable name for therapies.

CREATE OR REPLACE VIEW int_dim_therapy AS
SELECT DISTINCT
    therapy_code,
    therapy_name
FROM
    therapy_lookup;