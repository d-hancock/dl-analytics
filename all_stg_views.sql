-- Staging Table: Billing Claim
-- Cleans and casts raw billing claim data for downstream use
-- One-to-one mapping with the source table

SELECT 
    claim_id, -- Unique identifier for the claim
    patient_id, -- Unique identifier for the patient
    provider_id, -- Unique identifier for the provider
    claim_date, -- Date of the claim
    total_amount -- Total amount billed
FROM raw_billing_claim;
-- Staging Table: Billing Claim Item
-- Cleans and casts raw billing claim item data for downstream use
-- One-to-one mapping with the source table

SELECT 
    claim_item_id, -- Unique identifier for the claim item
    claim_id, -- Associated claim identifier
    item_code, -- Code for the billed item
    item_description, -- Description of the billed item
    quantity, -- Quantity of the item billed
    unit_price -- Price per unit of the item
FROM raw_billing_claim_item;-- Staging Table: Date Dimension
-- Cleans and casts raw date data for downstream use
-- One-to-one mapping with the source table

SELECT 
    calendar_date, -- Day-level date
    day_of_week, -- Day of the week
    month, -- Month of the year
    year -- Year
FROM raw_date_dimension;-- Staging Table: Encounter Discharge Summary
-- Cleans and casts raw discharge summary data for downstream use
-- One-to-one mapping with the source table

SELECT 
    discharge_id, -- Unique identifier for the discharge event
    patient_id, -- Unique identifier for the patient
    discharge_date, -- Date of discharge
    discharge_status -- Status of the discharge
FROM raw_encounter_discharge_summary;-- Staging Table: Patient Encounter
-- Cleans and casts raw patient encounter data for downstream use
-- One-to-one mapping with the source table

SELECT 
    encounter_id, -- Unique identifier for the encounter
    patient_id, -- Unique identifier for the patient
    encounter_date, -- Date of the encounter
    encounter_type -- Type of the encounter
FROM raw_patient_encounter;-- =================================================================================
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
FROM CareTend_OC.Encounter.PatientOrder;-- =================================================================================
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
  ON cl.AddressKey = a.AddressKey;-- =================================================================================
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
FROM OLTP_DB.Inventory.InventoryItemLocationQuantity;-- =================================================================================
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
FROM OLTP_DB.Billing.InvoiceClaimItemLink;-- =================================================================================
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
FROM OLTP_DB.Common.Party;-- =================================================================================
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
 AND pol.IsPrimary = 1;-- =================================================================================
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
FROM OLTP_DB.Patient.PatientPolicy;-- =================================================================================
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
FROM OLTP_DB.Insurance.Carrier c;-- =================================================================================
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