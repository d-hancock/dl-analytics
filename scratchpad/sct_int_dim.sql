-- ==============================================================
-- Intermediate SQL Templates for Financial Exec Dashboard
-- These views form the core analytics layer for Tableau consumption.
-- Each view is documented with purpose, source table mappings, join logic, and key transformations.
-- Assumes a DEV_DB schema for development, staging schemas (`staging.*`),
-- and CareTend OLTP source schemas (`caretend_oltp.*`).
-- ==============================================================

-- ==============================================================
-- 1) Date Dimension: int_dim_date
-- Grain: one row per day, supplemented by fiscal period metadata
-- Purpose: Provide a canonical time axis that normalizes all date references,
--          drives time-series analyses, and enables easy period calculations (MoM/QoQ).
-- Source: staging.utilities_date (pre-populated date scaffold covering full range)
-- Key fields:
--    calendar_date: DATE (each calendar day)
--    fiscal_period_key: VARCHAR (surrogate period, e.g. '202501')
--    period_start_date, period_end_date: DATE bounds for each fiscal period
--    calendar_month, calendar_year, day_of_week: breakdowns for grouping and labeling
--    is_month_end, is_quarter_end, is_fiscal_period_end: BOOLEAN flags for period boundaries
CREATE OR REPLACE VIEW dev_db.int_dim_date AS
SELECT
  d.calendar_date,
  -- Derive a surrogate key for fiscal period in YYYYMM format
  TO_CHAR(d.calendar_date, 'YYYYMM') AS fiscal_period_key,
  -- Period boundaries come directly from the date scaffold (assumed pre-calculated)
  d.period_start_date,
  d.period_end_date,
  -- Numeric month and year for grouping
  EXTRACT(MONTH FROM d.calendar_date) AS calendar_month,
  EXTRACT(YEAR  FROM d.calendar_date) AS calendar_year,
  -- Day name (Monday, Tuesday, etc.) for labeling
  TRIM(TO_CHAR(d.calendar_date, 'Day')) AS day_of_week,
  -- Flag if this date is the last day of the calendar month
  CASE WHEN d.calendar_date = d.period_end_date THEN TRUE ELSE FALSE END AS is_month_end,
  -- Flag if end of calendar quarter (Mar/Jun/Sep/Dec)
  CASE
    WHEN EXTRACT(MONTH FROM d.calendar_date) IN (3,6,9,12)
     AND d.calendar_date = d.period_end_date
    THEN TRUE ELSE FALSE
  END AS is_quarter_end,
  -- Flag if end of fiscal period (same as month_end if fiscal period = calendar month)
  CASE WHEN d.calendar_date = d.period_end_date THEN TRUE ELSE FALSE END AS is_fiscal_period_end
FROM staging.utilities_date d;

-- ==============================================================
-- 2) Location Dimension: int_dim_location
-- Grain: one row per facility/location
-- Purpose: Centralized site lookup for "where" KPIs occur. Simplifies joins
--          for patient encounters, discharges, referrals, etc.
-- Source: caretend_oltp.common.facility + caretend_oltp.common.partyaddress
-- Key fields:
--    location_id: surrogate from facility.facility_id
--    location_name: facility name
--    location_type: e.g., "Home Care", "Clinic"
--    address_id, city, state, zip_code: geo info for mapping/filtering
--    is_active: facility operational status
CREATE OR REPLACE VIEW dev_db.int_dim_location AS
SELECT
  f.facility_id         AS location_id,
  f.facility_name       AS location_name,
  f.facility_type       AS location_type,
  f.address_id,
  -- Join to address dimension for city/state/zip
  a.city,
  a.state,
  a.zip_code,
  f.is_active
FROM caretend_oltp.common.facility f
LEFT JOIN caretend_oltp.common.partyaddress a
  ON f.address_id = a.address_id;

-- ==============================================================
-- 3) Product Dimension: int_dim_product
-- Grain: one row per billable item (drug/SKU)
-- Purpose: Normalize inventory master for revenue and cost joins
-- Source: caretend_oltp.inventory.inventory_item + lookups.category
-- Key fields:
--    product_id: inventory_item_id surrogate
--    item_sku: unique SKU code
--    product_name: human-friendly description
--    category_id, category_name: grouping for analysis
--    therapy_code: HCPC code for clinical mapping
CREATE OR REPLACE VIEW dev_db.int_dim_product AS
SELECT
  i.inventory_item_id   AS product_id,
  i.item_sku            AS item_sku,
  i.item_description    AS product_name,
  i.category_id,
  c.category_name,
  i.hcpc_code           AS therapy_code
FROM caretend_oltp.inventory.inventory_item i
LEFT JOIN caretend_oltp.lookups.category c
  ON i.category_id = c.category_id;

-- ==============================================================
-- 4) Payer Dimension: int_dim_payer
-- Grain: one row per unique insurance policy/program
-- Purpose: Central lookup for "who paid" slices in AR and revenue facts
-- Source: caretend_oltp.patient.patientpolicy + lookups.insuranceprogram
-- Key fields:
--    payer_id: policy_id surrogate
--    payer_name: program name from lookup
--    coverage_type: e.g., "Medicare", "Commercial"
--    effective_date, termination_date: policy time bounds
CREATE OR REPLACE VIEW dev_db.int_dim_payer AS
SELECT
  p.patient_policy_id    AS payer_id,
  ip.program_name        AS payer_name,
  ip.coverage_type,
  ip.effective_date,
  ip.termination_date
FROM caretend_oltp.patient.patientpolicy p
LEFT JOIN caretend_oltp.lookups.insuranceprogram ip
  ON p.program_code = ip.program_code;

-- ==============================================================
-- 5) Discharges Fact: int_fct_discharges
-- Grain: one row per (fiscal_period_key, location_id, therapy_code)
-- Purpose: Pre-aggregate discharged patient counts by slice for fast dashboard rendering
-- Source: caretend_oltp.encounter.discharge or summary table
-- Key logic:
--    - Join discharge_date to int_dim_date for period assignment
--    - Join facility to int_dim_location
--    - Join HCPC code to int_dim_product
--    - Count distinct patient_id to avoid duplicates
CREATE OR REPLACE VIEW dev_db.int_fct_discharges AS
SELECT
  d.fiscal_period_key,
  l.location_id,
  prod.therapy_code,
  COUNT(DISTINCT dis.patient_id) AS discharged_patients
FROM caretend_oltp.encounter.patientdischarge dis
-- period assignment
JOIN dev_db.int_dim_date d
  ON dis.discharge_date BETWEEN d.period_start_date AND d.period_end_date
-- location lookup
JOIN dev_db.int_dim_location l
  ON dis.facility_id = l.location_id
-- product/therapy lookup
JOIN dev_db.int_dim_product prod
  ON dis.hcpc_code = prod.therapy_code
GROUP BY 1,2,3;

-- ==============================================================
-- 6) New Starts Fact: int_fct_new_starts
-- Grain: one row per (fiscal_period_key, location_id, therapy_code)
-- Purpose: Count only first-ever patient encounters in each period for the "New Starts" KPI
-- Source: caretend_oltp.encounter.patientencounter
-- Key logic:
--    - Identify each patient's first visit via windowing or subquery
--    - Join that date to the date dimension
--    - Then join facility and HCPC for slicing
CREATE OR REPLACE VIEW dev_db.int_fct_new_starts AS
WITH first_visits AS (
  SELECT
    patient_id,
    MIN(visit_date) AS first_visit_date
  FROM caretend_oltp.encounter.patientencounter
  GROUP BY patient_id
)
SELECT
  d.fiscal_period_key,
  l.location_id,
  prod.therapy_code,
  COUNT(fv.patient_id) AS new_starts
FROM first_visits fv
-- assign period
JOIN dev_db.int_dim_date d
  ON fv.first_visit_date BETWEEN d.period_start_date AND d.period_end_date
-- get full details for facility and therapy
JOIN caretend_oltp.encounter.patientencounter pe
  ON fv.patient_id = pe.patient_id
 AND pe.visit_date = fv.first_visit_date
JOIN dev_db.int_dim_location l
  ON pe.facility_id = l.location_id
JOIN dev_db.int_dim_product prod
  ON pe.hcpc_code = prod.therapy_code
GROUP BY 1,2,3;

-- ==============================================================
-- 7) Referrals Fact: int_fct_referrals
-- Grain: one row per (fiscal_period_key, location_id, referral_type)
-- Purpose: Pre-aggregate referral counts by type for dashboard filtering
-- Source: caretend_oltp.encounter.patientreferral
CREATE OR REPLACE VIEW dev_db.int_fct_referrals AS
SELECT
  d.fiscal_period_key,
  r.facility_id   AS location_id,
  r.referral_type,
  COUNT(*)        AS referral_count
FROM caretend_oltp.encounter.patientreferral r
JOIN dev_db.int_dim_date d
  ON r.referral_date BETWEEN d.period_start_date AND d.period_end_date
GROUP BY 1,2,3;

-- ==============================================================
-- 8) Expected Revenue Fact: int_fct_expected_revenue
-- Grain: one row per (fiscal_period_key, location_id)
-- Purpose: Calculate contracted revenue and per-day average for pacing KPIs
-- Source: caretend_oltp.billing.contract
-- Key logic:
--    - Join contract date range to each period
--    - Sum contract amounts for period
--    - Derive days_in_period from date dimension
CREATE OR REPLACE VIEW dev_db.int_fct_expected_revenue AS
SELECT
  d.fiscal_period_key,
  c.facility_id         AS location_id,
  SUM(c.contract_amount)   AS expected_revenue,
  -- total days in period
  (d.period_end_date - d.period_start_date + 1) AS days_in_period,
  -- simple pace metric
  SUM(c.contract_amount) / (d.period_end_date - d.period_start_date + 1) AS expected_rev_per_day
FROM caretend_oltp.billing.contract c
JOIN dev_db.int_dim_date d
  ON c.contract_start_date <= d.period_end_date
 AND c.contract_end_date   >= d.period_start_date
GROUP BY 1,2;

-- ==============================================================
-- 9) Drug Revenue Fact: int_fct_drug_revenue
-- Grain: one row per (fiscal_period_key, payer_id, product_id)
-- Purpose: Consolidate invoice item lines into a clean revenue fact, including MoM support
-- Source: caretend_oltp.billing.invoiceitem
-- Key logic:
--    - Join service_date to date dimension
--    - Sum quantity * unit_price minus discounts plus taxes
--    - Use window function to pull prior period revenue for MoM calcs
CREATE OR REPLACE VIEW dev_db.int_fct_drug_revenue AS
SELECT
  d.fiscal_period_key,
  inv.payer_id,
  inv.inventory_item_id AS product_id,
  -- core revenue formula
  SUM(inv.quantity * inv.unit_price)
    - SUM(inv.discount_amount)
    + SUM(inv.tax_amount) AS drug_revenue,
  -- prior period revenue via lag window
  LAG(
    SUM(inv.quantity * inv.unit_price)
      - SUM(inv.discount_amount)
      + SUM(inv.tax_amount)
  ) OVER (
    PARTITION BY inv.payer_id, inv.inventory_item_id
    ORDER BY d.fiscal_period_key
  ) AS prior_period_revenue
FROM caretend_oltp.billing.invoiceitem inv
JOIN dev_db.int_dim_date d
  ON inv.service_date BETWEEN d.period_start_date AND d.period_end_date
GROUP BY 1,2,3;