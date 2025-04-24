-- Consolidated Staging Views
-- Schema: DEV_DB.stg
-- Purpose: Streamline and consolidate overlapping staging views for consistency and maintainability.

-- =================================================================================
-- 1. Consolidated Date Dimension View
-- Name: date_dimension
-- Source Tables: OLTP_DB.Utilities.Date
-- Purpose: Canonical date dimension scaffold for time-series and fiscal calculations.
-- Key Transformations:
--   • Standardize column names to snake_case.
--   • Add boolean flags for month-end and fiscal period-end.
-- Usage:
--   • Drive time-series joins, fill missing dates, and implement custom fiscal logic.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.date_dimension AS
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

-- =================================================================================
-- 2. Consolidated Patient Dimension View
-- Name: patient_dimension
-- Source Tables: OLTP_DB.Patient.Patient, OLTP_DB.Common.Party, OLTP_DB.Patient.PatientPolicy
-- Purpose: Flatten patient demographic and primary policy lookup.
-- Key Transformations:
--   • Rename primary keys to `patient_id` and `party_id`.
--   • Cast `BirthDate` to DATE for consistency.
--   • Join patient policies to expose primary insurance policy.
-- Usage:
--   • Join to claims, invoices, and encounters for patient-level KPIs.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.patient_dimension AS
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

-- =================================================================================
-- 3. Consolidated Provider Dimension View
-- Name: provider_dimension
-- Source Tables: OLTP_DB.Provider.Provider, OLTP_DB.Common.Party
-- Purpose: Normalize provider lookup with name, NPI, specialty, and active flag.
-- Key Transformations:
--   • Rename primary keys to `provider_id` and `party_id`.
--   • Add boolean flag for active status.
-- Usage:
--   • Link to invoices and claims to analyze provider performance.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.provider_dimension AS
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

-- =================================================================================
-- 4. Consolidated Facility Dimension View
-- Name: facility_dimension
-- Source Tables: OLTP_DB.Common.CompanyLocation, OLTP_DB.Common.Address
-- Purpose: Flatten physical locations with address details.
-- Key Transformations:
--   • Rename primary keys to `facility_id` and `company_id`.
--   • Add boolean flag for active status.
-- Usage:
--   • Join to inventory and billing data for location-based reporting.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.facility_dimension AS
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

-- =================================================================================
-- 5. Consolidated Payer Dimension View
-- Name: payer_dimension
-- Source Tables: OLTP_DB.Insurance.Carrier
-- Purpose: Normalize payer lookup for revenue and claims analysis.
-- Key Transformations:
--   • Rename primary key to `payer_id`.
--   • Add boolean flag for active status.
--   • Include effective and termination dates for coverage tracking.
-- Usage:
--   • Join to claims and invoices for payer-level revenue analysis.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.payer_dimension AS
SELECT
  c.CarrierKey        AS payer_id,
  c.CarrierName       AS payer_name,
  c.CarrierTypeCode   AS payer_type,
  CASE WHEN c.IsActive = 'Y' THEN TRUE ELSE FALSE END AS is_active,
  c.EffectiveDate     AS effective_date,
  c.TerminationDate   AS termination_date
FROM OLTP_DB.Insurance.Carrier c;

-- =================================================================================
-- 6. Inventory Transfer View
-- Name: inventory_transfer
-- Source Tables: OLTP_DB.Inventory.InventoryTransfer
-- Purpose: Track inventory movement events for on-hand quantity tracking.
-- Key Transformations:
--   • Rename primary key to `transfer_event_id`.
-- Usage:
--   • Feed into inventory consumption and COGS calculations.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.inventory_transfer AS
SELECT
  InventoryTransferKey  AS transfer_event_id,
  ToLocationKey         AS to_location_id
FROM OLTP_DB.Inventory.InventoryTransfer;

-- =================================================================================
-- 7. Invoice Claim Item Link View
-- Name: invoice_claim_item_link
-- Source Tables: OLTP_DB.Billing.InvoiceClaimItemLink
-- Purpose: Bridge invoice headers to claim line items for combined revenue and AR analysis.
-- Key Transformations:
--   • Rename primary key to `link_id`.
-- Usage:
--   • Enable combined revenue and AR analysis by linking invoices to claims.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.invoice_claim_item_link AS
SELECT
  InvoiceClaimItemLinkKey   AS link_id,
  ClaimItemKey              AS claim_item_id
FROM OLTP_DB.Billing.InvoiceClaimItemLink;

-- =================================================================================
-- =================================================================================
-- 8. Patient Policy View
-- Name: patient_policy
-- Source Tables: OLTP_DB.Patient.PatientPolicy
-- Purpose: Capture patient insurance coverage over time.
-- Key Transformations:
--   • Rename primary key to `patient_policy_id`.
--   • Expose coverage type for downstream payer mix analysis.
-- Usage:
--   • Determine payer mix and patient liability for revenue recognition.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.patient_policy AS
SELECT
  PatientPolicyKey       AS patient_policy_id,
  CoverageTypeCode       AS coverage_type
FROM OLTP_DB.Patient.PatientPolicy;

-- =================================================================================
-- 9. Party View
-- Name: party
-- Source Tables: OLTP_DB.Common.Party
-- Purpose: Core party entity for customers, payers, and vendors.
-- Key Transformations:
--   • Rename primary key to `party_id`.
--   • Expose status flag for active/inactive parties.
-- Usage:
--   • Join to invoices, payments, and carrier tables for master data.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.party AS
SELECT
  PartyKey              AS party_id,
  Status                AS status_flag
FROM OLTP_DB.Common.Party;

-- =================================================================================
-- 10. Billing Claim View
-- Name: billing_claim
-- Source Tables: OLTP_DB.Billing.Claim
-- Purpose: Represent raw claim headers for AR analysis.
-- Key Transformations:
--   • Rename primary key to `claim_id`.
--   • Expose claim status for downstream reporting.
-- Usage:
--   • Analyze claim-level revenue and AR performance.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.billing_claim AS
SELECT
  ClaimKey              AS claim_id,
  ClaimStatusCode       AS claim_status
FROM OLTP_DB.Billing.Claim;

-- =================================================================================
-- 11. Billing Claim Item View
-- Name: billing_claim_item
-- Source Tables: OLTP_DB.Billing.ClaimItem
-- Purpose: Provide claim line item details for service-level AR.
-- Key Transformations:
--   • Rename primary key to `claim_item_id`.
--   • Expose billed amount for revenue calculations.
-- Usage:
--   • Analyze service-level revenue and AR performance.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.billing_claim_item AS
SELECT
  ClaimItemKey          AS claim_item_id,
  BilledAmount          AS billed_amount
FROM OLTP_DB.Billing.ClaimItem;

-- =================================================================================
-- 12. Inventory Item Location Quantity View
-- Name: inventory_item_location_quantity
-- Source Tables: OLTP_DB.Inventory.InventoryItemLocationQuantity
-- Purpose: Track on-hand inventory quantity by location.
-- Key Transformations:
--   • Rename primary key to `item_location_quantity_id`.
--   • Expose on-hand quantity for inventory tracking.
-- Usage:
--   • Feed into inventory availability and stock-level reporting.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.inventory_item_location_quantity AS
SELECT
  InventoryItemLocationQuantityKey AS item_location_quantity_id,
  OnHandQuantity                  AS on_hand_quantity
FROM OLTP_DB.Inventory.InventoryItemLocationQuantity;

-- =================================================================================
-- 13. Encounter Patient Encounter View
-- Name: encounter_patient_encounter
-- Source Tables: CareTend_OC.Encounter.PatientEncounter
-- Purpose: Represent raw encounter events for discharge and new-start metrics.
-- Key Transformations:
--   • Rename primary key to `encounter_id`.
--   • Expose encounter type for downstream reporting.
-- Usage:
--   • Analyze patient encounters for operational metrics.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.encounter_patient_encounter AS
SELECT
  EncounterID           AS encounter_id,
  EncounterType         AS encounter_type
FROM CareTend_OC.Encounter.PatientEncounter;

-- =================================================================================
-- 14. Encounter Discharge Summary View
-- Name: encounter_discharge_summary
-- Source Tables: CareTend_OC.Encounter.DischargeSummary
-- Purpose: Summarize discharge records, capturing final outcomes by encounter.
-- Key Transformations:
--   • Rename primary key to `discharge_summary_id`.
--   • Expose discharge reason for downstream reporting.
-- Usage:
--   • Analyze discharge outcomes for operational and clinical metrics.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.encounter_discharge_summary AS
SELECT
  SummaryID             AS discharge_summary_id,
  DischargeReason       AS discharge_reason
FROM CareTend_OC.Encounter.DischargeSummary;

-- =================================================================================
-- 15. Encounter Patient Order View
-- Name: encounter_patient_order
-- Source Tables: CareTend_OC.Encounter.PatientOrder
-- Purpose: Represent raw patient orders used to identify referrals and first starts.
-- Key Transformations:
--   • Rename primary key to `order_id`.
--   • Expose order type for downstream reporting.
-- Usage:
--   • Analyze patient orders for referral and new-start metrics.
-- =================================================================================
CREATE OR REPLACE VIEW DEV_DB.stg.encounter_patient_order AS
SELECT
  OrderID               AS order_id,
  OrderType             AS order_type
FROM CareTend_OC.Encounter.PatientOrder;