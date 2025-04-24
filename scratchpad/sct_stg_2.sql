-- models/staging/stg_utilities_date.sql
-- ================================================================
-- Model: stg_utilities_date
-- Location: models/staging/
-- Materialization: view
-- Source: CareTend_OC.Utilities.Date
-- Description:
--   Provides a clean calendar dimension spanning 1900-01-01 to 2099-12-31.
--   Exposes key date attributes for time-series analyses and joins.
-- Conventions:
--   Prefix: stg_
--   All column names in snake_case.
-- Dependencies: None; uses raw Snowflake table directly.
-- --------------------------------------------------------------------------------
CREATE OR REPLACE VIEW stg_utilities_date AS
SELECT
  CalendarDate        AS calendar_date,        -- full DATE
  CalendarYear        AS calendar_year,        -- numeric year (e.g., 2025)
  CalendarMonth       AS calendar_month,       -- numeric month (1-12)
  DayOfWeek           AS day_of_week,          -- 1–7 representing Sunday–Saturday
  FiscalYear          AS fiscal_year,          -- organization-specific fiscal year
  IsMonthEnd          AS is_month_end,         -- TRUE if last day of calendar month
  IsQuarterEnd        AS is_quarter_end,       -- TRUE if last day of calendar quarter
  IsFiscalPeriodEnd   AS is_fiscal_period_end  -- TRUE if end of defined fiscal period
FROM CareTend_OC.Utilities.Date;


-- models/staging/stg_common_party_address.sql
-- ================================================================
-- Model: stg_common_party_address
-- Location: models/staging/
-- Materialization: view
-- Source Tables:
--   CareTend_OC.Common.PartyAddress (relationship link table)
--   CareTend_OC.Common.Address (address master)
-- Description:
--   Consolidates party address details into a single view.
--   Normalizes field names, filters only active addresses.
-- Conventions:
--   Use LEFT JOIN if address is optional.
--   Drop system metadata fields (audit columns).
-- Dependencies:
--   Raw OLTP tables; no other staging dependencies.
-- --------------------------------------------------------------------------------
CREATE OR REPLACE VIEW stg_common_party_address AS
SELECT
  pa.PartyAddressID      AS party_address_id,  -- surrogate key for party-address link
  pa.PartyID             AS party_id,          -- foreign key to Party
  ad.AddressLine1        AS address_line1,     -- primary address line
  ad.AddressLine2        AS address_line2,     -- secondary address line (if any)
  ad.City                AS city,
  ad.State               AS state,
  ad.ZipCode             AS zip_code,
  pa.IsActive            AS is_active          -- indicates whether address is current
FROM CareTend_OC.Common.PartyAddress AS pa
JOIN CareTend_OC.Common.Address      AS ad
  ON pa.AddressID = ad.AddressID
WHERE pa.IsActive = TRUE;  -- filter out inactive addresses


-- models/staging/stg_common_facility.sql
-- ================================================================
-- Model: stg_common_facility
-- Location: models/staging/
-- Materialization: view
-- Source Tables:
--   CareTend_OC.Common.Facility
--   CareTend_OC.Common.PartyAddress + Address (for location/contact)
-- Description:
--   Standardizes facility (site) master data for reporting.
--   Includes location metadata and geographic attributes.
-- Conventions:
--   facility_id is the business key for location.
-- Dependencies:
--   stg_common_party_address (indirect via address join)
-- --------------------------------------------------------------------------------
CREATE OR REPLACE VIEW stg_common_facility AS
SELECT
  f.FacilityID            AS location_id,      -- primary key for location
  f.FacilityName          AS location_name,    -- human-readable name
  f.FacilityType          AS location_type,    -- e.g., "Home Care", "Clinic"
  f.AddressID             AS address_id,
  pa.city,
  pa.state,
  pa.zip_code,
  f.IsActive              AS is_active         -- indicates if location is currently active
FROM CareTend_OC.Common.Facility      AS f
LEFT JOIN stg_common_party_address    AS pa
  ON f.AddressID = pa.address_id;


-- models/staging/stg_inventory_item.sql
-- ================================================================
-- Model: stg_inventory_item
-- Location: models/staging/
-- Materialization: view
-- Source: CareTend_OC.Inventory.InventoryItem
-- Description:
--   Cleans and standardizes inventory master records.
--   Includes pricing base cost and categorization.
-- Conventions:
--   item_sku is unique business key per product.
-- Dependencies: None
-- --------------------------------------------------------------------------------
CREATE OR REPLACE VIEW stg_inventory_item AS
SELECT
  ii.InventoryItemID       AS inventory_item_id,  -- surrogate PK
  ii.ItemSKU               AS item_sku,           -- unique product code
  ii.ItemDescription       AS item_description,
  ii.CategoryID            AS category_id,        -- foreign key to category dimension
  ii.BaseUnitCost          AS unit_cost,          -- cost per unit
  ii.IsActive              AS is_active           -- active flag
FROM CareTend_OC.Inventory.InventoryItem AS ii
WHERE ii.IsActive = TRUE;


-- models/staging/stg_billing_invoice.sql
-- ================================================================
-- Model: stg_billing_invoice
-- Location: models/staging/
-- Materialization: view
-- Source: CareTend_OC.Billing.Invoice
-- Description:
--   Base invoice header info for linking to invoice items and payments.
--   Filters only finalized invoices for revenue reporting.
-- Conventions:
--   status 'Posted' indicates ready for revenue recognition.
-- Dependencies: None
-- --------------------------------------------------------------------------------
CREATE OR REPLACE VIEW stg_billing_invoice AS
SELECT
  inv.InvoiceID            AS invoice_id,
  inv.CompanyID            AS company_id,
  inv.InvoiceDate          AS invoice_date,
  inv.PatientID            AS patient_id,
  inv.TotalAmount          AS total_amount,
  inv.Status               AS status
FROM CareTend_OC.Billing.Invoice AS inv
WHERE inv.Status = 'Posted';  -- exclude drafts/cancelled


-- models/staging/stg_billing_invoice_item.sql
-- ================================================================
-- Model: stg_billing_invoice_item
-- Location: models/staging/
-- Materialization: view
-- Source: CareTend_OC.Billing.InvoiceItem
-- Description:
--   Invoice line items for detailed revenue, discount, and tax analyses.
-- Conventions:
--   Compute net_line_amount in downstream layers, not here.
-- Dependencies:
--   stg_billing_invoice (for invoice_date, patient)
-- --------------------------------------------------------------------------------
CREATE OR REPLACE VIEW stg_billing_invoice_item AS
SELECT
  ii.InvoiceItemID         AS invoice_item_id,
  ii.InvoiceID             AS invoice_id,
  ii.InventoryItemID       AS inventory_item_id,
  ii.Quantity              AS quantity,
  ii.UnitPrice             AS unit_price,
  ii.DiscountAmount        AS discount_amt,
  ii.TaxAmount             AS tax_amt
FROM CareTend_OC.Billing.InvoiceItem AS ii;


-- models/staging/stg_encounter_patient_encounter.sql
-- ================================================================
-- Model: stg_encounter_patient_encounter
-- Location: models/staging/
-- Materialization: view
-- Source: CareTend_OC.Encounter.PatientEncounter
-- Description:
--   Raw encounter events used for discharge and new-start metrics.
-- Conventions:
--   Discharge date null means ongoing encounter.
-- Dependencies: None
-- --------------------------------------------------------------------------------
CREATE OR REPLACE VIEW stg_encounter_patient_encounter AS
SELECT
  pe.EncounterID           AS encounter_id,
  pe.PatientID             AS patient_id,
  pe.FacilityID            AS location_id,
  pe.AdmissionDate         AS admission_date,
  pe.DischargeDate         AS discharge_date,
  pe.EncounterType         AS encounter_type
FROM CareTend_OC.Encounter.PatientEncounter AS pe;


-- models/staging/stg_encounter_discharge_summary.sql
-- ================================================================
-- Model: stg_encounter_discharge_summary
-- Location: models/staging/
-- Materialization: view
-- Source: CareTend_OC.Encounter.DischargeSummary
-- Description:
--   Summarized discharge records, capturing final outcome by encounter.
-- Conventions:
--   Use discharge_date for period assignment in fact tables.
-- Dependencies:
--   stg_encounter_patient_encounter (to link back to encounter)
-- --------------------------------------------------------------------------------
CREATE OR REPLACE VIEW stg_encounter_discharge_summary AS
SELECT
  ds.SummaryID             AS discharge_summary_id,
  ds.EncounterID           AS encounter_id,
  ds.DischargeDate         AS discharge_date,
  ds.DischargeReason       AS discharge_reason
FROM CareTend_OC.Encounter.DischargeSummary AS ds;


-- models/staging/stg_encounter_patient_order.sql
-- ================================================================
-- Model: stg_encounter_patient_order
-- Location: models/staging/
-- Materialization: view
-- Source: CareTend_OC.Encounter.PatientOrder
-- Description:
--   Raw patient orders used to identify referrals and first starts.
-- Conventions:
--   OrderDate drives the "new start" logic in fact layers.
-- Dependencies:
--   stg_encounter_patient_encounter (optional for filtering by active encounter)
-- --------------------------------------------------------------------------------
CREATE OR REPLACE VIEW stg_encounter_patient_order AS
SELECT
  po.OrderID               AS order_id,
  po.PatientID             AS patient_id,
  po.FacilityID            AS location_id,
  po.OrderDate             AS order_date,
  po.OrderType             AS referral_type
FROM CareTend_OC.Encounter.PatientOrder AS po;


-- models/staging/stg_billing_carrier.sql
-- ================================================================
-- Model: stg_billing_carrier
-- Location: models/staging/
-- Materialization: view
-- Source: CareTend_OC.Billing.Carrier
-- Description:
--   Payer master list for AR & revenue slicing.
-- Conventions:
--   Only include carriers with active coverage periods covering invoice dates.
-- Dependencies: None
-- --------------------------------------------------------------------------------
CREATE OR REPLACE VIEW stg_billing_carrier AS
SELECT
  c.CarrierID              AS payer_id,
  c.CarrierName            AS payer_name,
  c.CoverageType           AS coverage_type,
  c.EffectiveDate          AS effective_date,
  c.TerminationDate        AS termination_date
FROM CareTend_OC.Billing.Carrier AS c
WHERE current_date BETWEEN c.EffectiveDate AND COALESCE(c.TerminationDate, current_date);


-- models/staging/stg_billing_patient_policy.sql
-- ================================================================
-- Model: stg_billing_patient_policy
-- Location: models/staging/
-- Materialization: view
-- Source: CareTend_OC.Billing.PatientPolicy
-- Description:
--   Links patients to payer policies over time for precise revenue segmentation.
-- Conventions:
--   Policy effective/termination dates used to assign revenue to the appropriate payer.
-- Dependencies:
--   stg_billing_carrier (to filter to valid payer entries)
-- --------------------------------------------------------------------------------
CREATE OR REPLACE VIEW stg_billing_patient_policy AS
SELECT
  pp.PolicyID             AS policy_id,
  pp.PatientID            AS patient_id,
  pp.PayerID              AS payer_id,
  pp.EffectiveDate        AS effective_date,
  pp.TerminationDate      AS termination_date
FROM CareTend_OC.Billing.PatientPolicy AS pp
JOIN stg_billing_carrier      AS c
  ON pp.PayerID = c.payer_id
;
