-- Staging Layer Conventions and Examples
-- Schema: DEV_DB.stg (staging schema)
-- Materialization: VIEW
-- Purpose: Minimal transformations to raw OLTP tables:
--   1. Standardize model names and location
--   2. Select only business-relevant columns
--   3. Rename keys and cast types for consistency
--   4. Drop system metadata not needed downstream
--   5. Serve as a clean, stable foundation for dim_ views

-- 1. Staging view for date dimension (stg_dim_date)
--    Source: OLTP_DB.Utilities.Date
--    Purpose: Prepare calendar scaffold for time-series and fiscal calculations
CREATE OR REPLACE VIEW DEV_DB.stg.dim_date AS
SELECT
  CalendarDate                 AS calendar_date,
  CalendarYear                 AS calendar_year,
  CalendarMonth                AS calendar_month,
  DayOfWeek                    AS day_of_week,
  FiscalYear                   AS fiscal_year,
  AccountingPeriodKey          AS fiscal_period_key,
  PeriodStartDate              AS period_start_date,
  PeriodEndDate                AS period_end_date,
  CASE WHEN IsMonthEnd = 'Y' THEN TRUE ELSE FALSE END AS is_month_end,
  CASE WHEN IsFiscalPeriodEnd = 'Y' THEN TRUE ELSE FALSE END AS is_fiscal_period_end
FROM OLTP_DB.Utilities.Date;

-- 2. Staging view for patient dimension (stg_dim_patient)
--    Sources: OLTP_DB.Patient.Patient, OLTP_DB.Common.Party, OLTP_DB.Patient.PatientPolicy
--    Purpose: Flatten patient demographic and primary policy lookup
CREATE OR REPLACE VIEW DEV_DB.stg.dim_patient AS
SELECT
  p.PatientKey           AS patient_id,
  pr.PartyKey            AS party_id,
  pr.FirstName           AS first_name,
  pr.LastName            AS last_name,
  CAST(p.BirthDate AS DATE)        AS birth_date,
  pr.GenderCode          AS gender,
  p.Status               AS status,
  pol.PolicyKey          AS primary_insurance_policy_id
FROM OLTP_DB.Patient.Patient p
JOIN OLTP_DB.Common.Party pr
  ON p.PartyKey = pr.PartyKey
LEFT JOIN OLTP_DB.Patient.PatientPolicy pol
  ON p.PatientKey = pol.PatientKey
 AND pol.IsPrimary = 1;

-- 3. Staging view for provider dimension (stg_dim_provider)
--    Sources: OLTP_DB.Provider.Provider, OLTP_DB.Common.Party
--    Purpose: Normalize provider lookup with name, NPI, specialty, and active flag
CREATE OR REPLACE VIEW DEV_DB.stg.dim_provider AS
SELECT
  pr.ProviderKey        AS provider_id,
  pa.PartyKey           AS party_id,
  pa.FirstName          AS first_name,
  pa.LastName           AS last_name,
  pr.NPI                AS npi,
  pr.SpecialtyCode      AS specialty,
  CASE WHEN pr.IsActive = 'Y' THEN TRUE ELSE FALSE END AS is_active
FROM OLTP_DB.Provider.Provider pr
JOIN OLTP_DB.Common.Party pa
  ON pr.PartyKey = pa.PartyKey;

-- 4. Staging view for facility dimension (stg_dim_facility)
--    Sources: OLTP_DB.Common.CompanyLocation, OLTP_DB.Common.Address
--    Purpose: Flatten physical locations with address details
CREATE OR REPLACE VIEW DEV_DB.stg.dim_facility AS
SELECT
  cl.CompanyLocationKey    AS facility_id,
  cl.CompanyKey            AS company_id,
  cl.LocationCode          AS facility_code,
  cl.LocationName          AS facility_name,
  a.AddressLine1           AS address_line1,
  a.City                   AS city,
  a.State                  AS state,
  a.ZipCode                AS zip_code,
  CASE WHEN cl.IsActive = 'Y' THEN TRUE ELSE FALSE END AS is_active
FROM OLTP_DB.Common.CompanyLocation cl
LEFT JOIN OLTP_DB.Common.Address a
  ON cl.AddressKey = a.AddressKey;

-- 5. Staging view for payer dimension (stg_dim_payer)
--    Source: OLTP_DB.Insurance.Carrier
--    Purpose: Normalize payer lookup for revenue and claims analysis
CREATE OR REPLACE VIEW DEV_DB.stg.dim_payer AS
SELECT
  c.CarrierKey        AS payer_id,
  c.CarrierName       AS payer_name,
  c.CarrierTypeCode   AS payer_type,
  CASE WHEN c.IsActive = 'Y' THEN TRUE ELSE FALSE END AS is_active
FROM OLTP_DB.Insurance.Carrier c;
