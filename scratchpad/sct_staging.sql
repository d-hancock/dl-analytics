/*===============================================================================
  Staging Views SQL Templates
  Schema: DEV_DB.stg
  --------------------------------------------------------------------------------
  PURPOSE:
    • Serve as first layer in ELT pipeline, ingest raw OLTP tables with minimal
      transformation.
    • Standardize naming conventions (lower_snake_case), data types, and column aliases.
    • Remove system metadata, obsolete columns, and apply basic cleaning (e.g., casting).
  GUIDELINES:
    • Model naming: `stg_<schema>_<table>`
    • Materialization: As SQL views for lightweight performance.
    • Folder: `models/staging/`
    • Keep only business-relevant fields; drop audit and system columns.
    • Document source, purpose, and key transformations for each view.
================================================================================*/

-- ---------------------------------------------------------------------------------
-- 1. stg_patient
-- Source: OLTP_DB.Patient.Patient
-- Purpose: Core patient dimension containing basic demographics
-- Key Transformations:
--   • Rename primary key to `patient_id`.
--   • Cast `BirthDate` to DATE for consistency.
--   • Standardize gender codes and status flags.
-- Usage:
--   • Join to claims, invoices, encounters for patient-level KPIs.
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE VIEW DEV_DB.stg.stg_patient AS
SELECT
  PatientKey            AS patient_id,
  FirstName             AS first_name,
  LastName              AS last_name,
  CAST(BirthDate AS DATE) AS birth_date,
  GenderCode            AS gender,
  Status                AS status_flag
FROM OLTP_DB.Patient.Patient;

-- ---------------------------------------------------------------------------------
-- 2. stg_provider
-- Source: OLTP_DB.Provider.Provider
-- Purpose: Provider master list for attribution of services
-- Key Transformations:
--   • Map `ProviderKey` to `provider_id`.
--   • Expose `npi_number` and clinical specialty codes.
-- Usage:
--   • Link to invoice and claim views to analyze provider performance.
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE VIEW DEV_DB.stg.stg_provider AS
SELECT
  ProviderKey           AS provider_id,
  NPI                   AS npi_number,
  ProviderName          AS provider_name,
  SpecialtyCode         AS specialty,
  PECOSFlag             AS pecos_flag
FROM OLTP_DB.Provider.Provider;

-- ---------------------------------------------------------------------------------
-- 3. stg_inventory_transfer
-- Source: OLTP_DB.Inventory.InventoryTransfer
-- Purpose: Inventory movement events for on-hand quantity tracking
-- Key Transformations:
--   • Normalize column names to `snake_case`.
--   • Expose source/target location keys for stock flows.
-- Usage:
--   • Feed into inventory consumption and COGS calculations.
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE VIEW DEV_DB.stg.stg_inventory_transfer AS
SELECT
  InventoryTransferKey  AS transfer_event_id,
  CAST(TransferDate AS DATE) AS transfer_date,
  ItemSKU               AS item_sku,
  Quantity              AS quantity_moved,
  FromLocationKey       AS from_location_id,
  ToLocationKey         AS to_location_id
FROM OLTP_DB.Inventory.InventoryTransfer;

-- ---------------------------------------------------------------------------------
-- 4. stg_invoice_claim_item_link
-- Source: OLTP_DB.Billing.InvoiceClaimItemLink
-- Purpose: Bridge invoice headers to claim line items
-- Usage:
--   • Enable combined revenue and AR analysis by linking invoices to claims.
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE VIEW DEV_DB.stg.stg_invoice_claim_item_link AS
SELECT
  InvoiceClaimItemLinkKey   AS link_id,
  InvoiceKey                AS invoice_id,
  ClaimItemKey              AS claim_item_id
FROM OLTP_DB.Billing.InvoiceClaimItemLink;

-- ---------------------------------------------------------------------------------
-- 5. stg_patient_policy
-- Source: OLTP_DB.Patient.PatientPolicy
-- Purpose: Patient insurance coverage over time
-- Key Transformations:
--   • Capture coverage windows via `effective_date` and `termination_date`.
--   • Normalize insurance program and coverage type.
-- Usage:
--   • Determine payer mix and patient liability for revenue recognition.
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE VIEW DEV_DB.stg.stg_patient_policy AS
SELECT
  PatientPolicyKey       AS patient_policy_id,
  PatientKey             AS patient_id,
  InsuranceProgramKey    AS insurance_program_id,
  CAST(EffectiveDate AS DATE)  AS effective_date,
  CAST(TerminationDate AS DATE) AS termination_date,
  CoverageTypeCode       AS coverage_type
FROM OLTP_DB.Patient.PatientPolicy;

-- ---------------------------------------------------------------------------------
-- 6. stg_party
-- Source: OLTP_DB.Common.Party
-- Purpose: Core party entity for customers, payers, vendors
-- Usage:
--   • Join to invoices, payments, and carrier tables for master data.
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE VIEW DEV_DB.stg.stg_party AS
SELECT
  PartyKey              AS party_id,
  PartyName             AS party_name,
  PartyTypeCode         AS party_type,
  Status                AS status_flag
FROM OLTP_DB.Common.Party;

-- ---------------------------------------------------------------------------------
-- 7. stg_date
-- Source: OLTP_DB.Utilities.Date
-- Purpose: Canonical date dimension scaffold
-- Usage:
--   • Drive time-series joins, fill missing dates, custom fiscal logic.
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE VIEW DEV_DB.stg.stg_date AS
SELECT
  CalendarDate          AS calendar_date,
  CalendarYear          AS calendar_year,
  CalendarMonth         AS calendar_month,
  DayOfWeek             AS day_of_week,
  FiscalYear            AS fiscal_year,
  AccountingPeriodKey   AS fiscal_period_id
FROM OLTP_DB.Utilities.Date;

-- ---------------------------------------------------------------------------------
-- 8. stg_billing_invoice
-- Source: OLTP_DB.Billing.Invoice
-- Purpose: Invoice header for revenue and payment analysis
-- Key Transformations:
--   • Expose `invoice_date`, status codes, and total amount.
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE VIEW DEV_DB.stg.stg_billing_invoice AS
SELECT
  InvoiceKey            AS invoice_id,
  CAST(InvoiceDate AS DATE)   AS invoice_date,
  PatientKey            AS patient_id,
  ProviderKey           AS provider_id,
  InvoiceStatusCode     AS invoice_status,
  InvoiceTotalAmount    AS invoice_total
FROM OLTP_DB.Billing.Invoice;

-- ---------------------------------------------------------------------------------
-- 9. stg_billing_invoice_item
-- Source: OLTP_DB.Billing.InvoiceItem
-- Purpose: Invoice line details for granular revenue and tax
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE VIEW DEV_DB.stg.stg_billing_invoice_item AS
SELECT
  InvoiceItemKey        AS invoice_item_id,
  InvoiceKey            AS invoice_id,
  Quantity              AS quantity,
  UnitPrice             AS unit_price,
  TaxAmount             AS tax_amount
FROM OLTP_DB.Billing.InvoiceItem;

-- ---------------------------------------------------------------------------------
-- 10. stg_billing_claim
-- Source: OLTP_DB.Billing.Claim
-- Purpose: Raw claim headers for AR analysis
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE VIEW DEV_DB.stg.stg_billing_claim AS
SELECT
  ClaimKey              AS claim_id,
  CAST(ClaimDate AS DATE)      AS claim_date,
  PatientKey            AS patient_id,
  CarrierKey            AS payer_id,
  ClaimStatusCode       AS claim_status
FROM OLTP_DB.Billing.Claim;

-- ---------------------------------------------------------------------------------
-- 11. stg_billing_claim_item
-- Source: OLTP_DB.Billing.ClaimItem
-- Purpose: Claim line item details for service-level AR
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE VIEW DEV_DB.stg.stg_billing_claim_item AS
SELECT
  ClaimItemKey          AS claim_item_id,
  ClaimKey              AS claim_id,
  CAST(ServiceDate AS DATE)    AS service_date,
  BilledAmount          AS billed_amount
FROM OLTP_DB.Billing.ClaimItem;

-- ---------------------------------------------------------------------------------
-- 12. stg_inventory_item
-- Source: OLTP_DB.Inventory.InventoryItem
-- Purpose: Product master catalog for revenue/cost mapping
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE VIEW DEV_DB.stg.stg_inventory_item AS
SELECT
  InventoryItemKey      AS item_id,
  ItemSKU               AS item_sku,
  Description           AS item_description,
  UnitCost              AS unit_cost
FROM OLTP_DB.Inventory.InventoryItem;

-- ---------------------------------------------------------------------------------
-- 13. stg_inventory_item_location_quantity
-- Source: OLTP_DB.Inventory.InventoryItemLocationQuantity
-- Purpose: On-hand quantity snapshot by location
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE VIEW DEV_DB.stg.stg_inventory_item_location_quantity AS
SELECT
  InventoryItemLocationQuantityKey AS record_id,
  InventoryItemKey                  AS item_id,
  LocationKey                       AS location_id,
  QuantityOnHand                    AS on_hand_quantity
FROM OLTP_DB.Inventory.InventoryItemLocationQuantity;

-- ---------------------------------------------------------------------------------
-- 14. stg_carrier
-- Source: OLTP_DB.Insurance.Carrier
-- Purpose: Payer master list for claims/invoices
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE VIEW DEV_DB.stg.stg_carrier AS
SELECT
  CarrierKey           AS carrier_id,
  CarrierName          AS carrier_name,
  CarrierTypeCode      AS carrier_type,
  CASE WHEN IsActive = 'Y' THEN TRUE ELSE FALSE END AS active_flag
FROM OLTP_DB.Insurance.Carrier;

-- ---------------------------------------------------------------------------------
-- 15. stg_address
-- Source: OLTP_DB.Common.Address
-- Purpose: Standardized address lookup for parties and locations
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE VIEW DEV_DB.stg.stg_address AS
SELECT
  AddressKey           AS address_id,
  AddressLine1         AS line1,
  AddressLine2         AS line2,
  City                 AS city,
  State                AS state,
  ZipCode              AS zip_code
FROM OLTP_DB.Common.Address;

-- ---------------------------------------------------------------------------------
-- 16. stg_company_location
-- Source: OLTP_DB.Common.CompanyLocation
-- Purpose: Map companies to physical addresses
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE VIEW DEV_DB.stg.stg_company_location AS
SELECT
  CompanyLocationKey   AS comp_loc_id,
  CompanyKey           AS company_id,
  AddressKey           AS address_id
FROM OLTP_DB.Common.CompanyLocation;

-- ---------------------------------------------------------------------------------
-- 17. stg_party_address
-- Source: OLTP_DB.Common.PartyAddress
-- Purpose: Link entity parties to their addresses
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE VIEW DEV_DB.stg.stg_party_address AS
SELECT
  PartyAddressKey      AS party_address_id,
  PartyKey             AS party_id,
  AddressKey           AS address_id,
  IsPrimary            AS is_primary_flag
FROM OLTP_DB.Common.PartyAddress;
