-- Model: int_dim_payer
-- Location: models/intermediate/
-- Materialization: view
-- Purpose: Centralized payer dimension providing insurance program attributes.
-- Inputs:
--   - stg_patient_policy: Staging table containing patient policy data.
-- Outputs:
--   - payer_id: Unique identifier for payers.
--   - payer_name: Name of the insurance program.

CREATE OR REPLACE VIEW int_dim_payer AS
SELECT DISTINCT
    insurance_program_id AS payer_id,
    insurance_program_name AS payer_name
FROM
    stg_patient_policy;