-- =====================================================================================
-- DIMENSION: Date Spine
-- Purpose: Serve as the core time axis for all reporting and KPI models
-- Features: Includes calendar logic, weekday flags, and fiscal scaffolding placeholders
-- =====================================================================================

-- Note: Add fiscal mappings (e.g., fiscal year, period, quarter) using joins to AccountingPeriod if available
create or replace table int_dim_date as
with date_spine as (
    -- Generate a date range spanning 10 years: 5 in the past, 5 in the future
    select dateadd(day, seq4(), dateadd(year, -5, current_date())) as date_day
    from table(generator(rowcount => 3650))
)
select
    date_day as date_id,                            -- Unique identifier for each day (same as date)
    date_day,                                       -- Raw calendar date

    -- Day/Week attributes
    dayname(date_day) as day_name,                  -- 'Monday', 'Tuesday', etc.
    day(date_day) as day_of_month,                  -- 1-31
    dayofweek(date_day) as day_of_week,             -- 0 = Sunday, 1 = Monday, etc.
    dayofyear(date_day) as day_of_year,             -- 1-365/366
    weekofyear(date_day) as week_of_year,           -- ISO week number

    -- Month/Quarter/Year attributes
    month(date_day) as month_number,
    monthname(date_day) as month_name,
    quarter(date_day) as quarter_number,
    year(date_day) as year_number,

    -- Booleans for easy filtering in dashboards or KPIs
    case when date_day = current_date() then true else false end as is_current_day,
    case when date_day >= date_trunc('month', current_date())
              and date_day < dateadd(month, 1, date_trunc('month', current_date()))
         then true else false end as is_current_month,
    case when dayofweek(date_day) in (0, 6) then false else true end as is_weekday,

    -- Placeholders for future joins with accounting or fiscal periods
    null as fiscal_period_key,                      -- Join from AccountingPeriod table if needed
    null as fiscal_year,                            -- Derived from mapped accounting calendar
    null as is_fiscal_period_end                    -- Can be flagged if needed

from date_spine;-- Intermediate Location Dimension
-- Enriches raw location data with additional attributes for reporting
-- Each row represents a unique location

SELECT 
    location_id, -- Facility or branch identifier
    location_name -- Facility or branch name
FROM stg_facility_dimension;-- Intermediate Payer Dimension
-- Enriches raw payer data with additional attributes for reporting
-- Each row represents a unique payer

SELECT 
    insurance_program_id AS payer_id, -- Insurance program identifier
    insurance_program_name AS payer_name -- Insurance program name
FROM stg_payer_dimension;-- Intermediate Product Dimension
-- Enriches raw product data with additional attributes for reporting
-- Each row represents a unique product

SELECT 
    item_sku AS product_id, -- Drug or supply item identifier
    item_name AS product_name -- Drug or supply item name
FROM stg_inventory_item;-- Intermediate Therapy Dimension
-- Enriches raw therapy data with additional attributes for reporting
-- Each row represents a unique therapy type

SELECT 
    therapy_code, -- Therapy type code (e.g., HcPc)
    therapy_name -- Therapy type name
FROM stg_encounter_patient_order;-- =================================================================================
-- Intermediate Fact Table: Discharges
-- Name: int_fct_discharges
-- Source Tables: stg_encounter_discharge_summary
-- Purpose: Consolidate patient discharge data for patient activity analysis
-- Key Transformations:
--   • Retain discharge_date for period assignment in marts
--   • Retain patient_id for patient-specific discharge metrics
--   • Include location_id for facility-level discharge analysis
-- Usage:
--   • Feed into finance.fct_discharges for aggregated discharge metrics
--   • Support calculation of "Discharged Patients" KPI metric
-- Grain: One row per patient discharge event
-- Business Rules:
--   • A discharge is counted on the date it occurred
--   • Each patient may have multiple discharges over time
-- =================================================================================

SELECT 
    discharge_date,     -- Date of discharge (for date dimension joins)
    patient_id,         -- Patient identifier (for patient dimension joins)
    location_id         -- Facility identifier (for location dimension joins)
FROM stg_encounter_discharge_summary; -- Source staging table-- =================================================================================
-- Intermediate Fact Table: Drug Revenue
-- Name: int_fct_drug_revenue
-- Source Tables: stg_inventory_item_location_quantity
-- Purpose: Consolidate drug revenue transactions and enable downstream revenue analysis
-- Key Transformations:
--   • Map product item_sku to standard product_id for consistent joins
--   • Retain location_id for proper dimensional analysis
--   • Include all revenue calculation components (quantity, unit_price, discounts, taxes)
-- Usage:
--   • Feed into finance.fct_drug_revenue for aggregated revenue analysis
--   • Support calculation of "Drug Revenue" KPI metric
-- Grain: One row per product transaction event
-- =================================================================================

SELECT 
    transaction_date,    -- Date of the transaction (to join with date dimension)
    item_sku AS product_id,  -- Map SKU to standard product ID to join with product dimension
    location_id,         -- Retain location ID for location dimension joining
    quantity,            -- Quantity sold in this transaction
    unit_price,          -- Price per unit for revenue calculation
    discount_amt,        -- Discount amount to be subtracted from revenue
    tax_amt              -- Tax amount to be added to revenue
FROM stg_inventory_item_location_quantity;  -- Source staging table-- =================================================================================
-- Intermediate Fact Table: Expected Revenue
-- Name: int_fct_expected_revenue
-- Source Tables: stg_billing_claim
-- Purpose: Transform billing claims into expected revenue metrics for forecasting
-- Key Transformations:
--   • Map claim_date to revenue_date for consistent date dimension joining
--   • Map claim_id to contract_id for entity identification
--   • Include location_id for location-specific revenue analysis
--   • Map total_amount to contracted_revenue for clear business terminology
-- Usage:
--   • Feed into finance.fct_expected_revenue for aggregated revenue analysis
--   • Support calculation of "Expected Revenue / Day" KPI metric
-- Grain: One row per contract/claim revenue event
-- =================================================================================

SELECT 
    claim_date AS revenue_date,       -- Date when revenue is expected (for date dimension)
    claim_id AS contract_id,          -- Unique identifier for revenue source
    location_id,                      -- Facility identifier for location dimension joining
    total_amount AS contracted_revenue -- Amount expected from this contract/claim
FROM stg_billing_claim;               -- Source staging table-- =================================================================================
-- Intermediate Fact Table: New Patient Starts
-- Name: int_fct_new_starts
-- Source Tables: stg_encounter_patient_encounter
-- Purpose: Track new patient start events for patient acquisition analysis
-- Key Transformations:
--   • Map encounter_date to start_date for consistent naming
--   • Include patient_id for patient-level analysis and deduplication
--   • Include location_id for facility-level patient acquisition metrics
-- Usage:
--   • Feed into finance.fct_new_starts for aggregated patient start metrics
--   • Support calculation of "New Starts" KPI (unique MRNs with Active status, 365-day lookback)
-- Grain: One row per new patient start event
-- Business Rules:
--   • A patient is counted as a new start on their first encounter date
--   • Only active patients are considered new starts in downstream calculations
-- =================================================================================

SELECT 
    encounter_date AS start_date,  -- Date of the patient's first encounter
    patient_id,                    -- Patient identifier for deduplication and dimension joining
    location_id                    -- Facility identifier for location-based analysis
FROM stg_encounter_patient_encounter; -- Source staging table-- =================================================================================
-- Intermediate Fact Table: Referrals
-- Name: int_fct_referrals
-- Source Tables: stg_encounter_patient_order
-- Purpose: Transform patient orders into referral metrics for downstream analysis
-- Key Transformations:
--   • Map order_date to referral_date for consistent date-based joining
--   • Map order_id to referral_id for entity identification
--   • Include location_id for proper location-based analysis
--   • Map order_type to referral_status to identify pending/active referrals
-- Usage:
--   • Feed into finance.fct_referrals for aggregated referral analysis 
--   • Support calculation of "Referrals" KPI metric, particularly pending referrals
-- Grain: One row per patient referral event
-- =================================================================================

SELECT 
    order_date AS referral_date,     -- Map date field for consistent date dimension joining
    order_id AS referral_id,         -- Map ID field for entity tracking
    location_id,                     -- Facility identifier for location dimension joining
    order_type AS referral_status    -- Map type field for referral status analysis
FROM stg_encounter_patient_order;    -- Source staging table-- =================================================================================
-- Intermediate Patient Dimension View
-- Name: int_patient_dimension
-- Source Tables: OLTP_DB.Patient.Patient, OLTP_DB.Common.Party, OLTP_DB.Patient.PatientPolicy
-- Purpose: Flatten patient demographic and primary policy lookup.
-- Key Transformations:
--   	• Rename primary keys to `patient_id` and `party_id`.
--   	• Cast `BirthDate` to DATE for consistency.
--   	• Join patient policies to expose primary insurance policy.
-- Usage:
--   	• Join to claims, invoices, and encounters for patient-level KPIs.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.patient_dimension AS
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
 AND pol.IsPrimary = 1;-- =================================================================================
-- Intermediate Payer Dimension View
-- Name: int_payer_dimension
-- Source Tables: OLTP_DB.Insurance.Carrier
-- Purpose: Normalize payer lookup for revenue and claims analysis.
-- Key Transformations:
--   	• Rename primary key to `payer_id`.
--   	• Add boolean flag for active status.
--   	• Include effective and termination dates for coverage tracking.
-- Usage:
--   	• Join to claims and invoices for payer-level revenue analysis.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.payer_dimension AS
SELECT
  c.CarrierKey        AS payer_id,
  c.CarrierName       AS payer_name,
  c.CarrierTypeCode   AS payer_type,
  CASE WHEN c.IsActive = 'Y' THEN TRUE ELSE FALSE END AS is_active,
  c.EffectiveDate     AS effective_date,
  c.TerminationDate   AS termination_date
FROM OLTP_DB.Insurance.Carrier c;-- =================================================================================
-- Intermediate Provider Dimension View
-- Name: int_provider_dimension
-- Source Tables: OLTP_DB.Provider.Provider, OLTP_DB.Common.Party
-- Purpose: Flatten provider demographic and associated information.
-- Key Transformations:
--   	• Rename primary keys to `provider_id` and `party_id`.
--   	• Cast relevant dates to DATE for consistency.
--   	• Include provider specialty and status information.
-- Usage:
--   	• Join to claims, invoices, and encounters for provider-level KPIs.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.int.provider_dimension AS
SELECT
  p.ProviderKey          AS provider_id,
  pr.PartyKey            AS party_id,
  pr.FirstName           AS first_name,
  pr.LastName            AS last_name,
  p.NPI                  AS npi_number,
  p.SpecialtyCode        AS specialty,
  CASE WHEN p.IsActive = 'Y' THEN TRUE ELSE FALSE END AS is_active
FROM OLTP_DB.Provider.Provider p
JOIN OLTP_DB.Common.Party pr
  ON p.PartyKey = pr.PartyKey;