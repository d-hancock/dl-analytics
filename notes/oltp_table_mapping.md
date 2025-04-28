# OLTP Table Descriptive Mapping

This document provides a descriptive mapping of key OLTP tables identified in the `oltp_schema_subset.json` file. It outlines their purpose, key columns, and relevance to building analytical dimensions and KPIs.

## Insurance Schema

### `Insurance.Carrier`
- **Description:** Stores detailed information about insurance carriers or payers, including their type, contact information, and billing rules.
- **Key Columns:**
    - `Id` (Primary Key): Unique identifier for the carrier.
    - `BillingOrganizationName`: Name used for billing.
    - `CarrierType_Id`: Foreign key to identify the type of carrier (e.g., Commercial, Medicare).
    - `PayorType_Id`: Foreign key for the payer type.
    - `UseMedicareRules`: Flag indicating if Medicare billing rules apply.
    - `ClaimInsuranceType_Id`: Foreign key for the type of insurance claim.
- **Relevance to Dimensions:**
    - **Payer Dimension:** Primary source for creating a consolidated Payer dimension. Attributes like `BillingOrganizationName`, `CarrierType_Id`, and `PayorType_Id` are crucial.
- **Relevance to KPIs:**
    - **Revenue Cycle:** Payer mix analysis, days sales outstanding (DSO) by payer type, denial rates by payer.
    - **Financial:** Gross/Net revenue analysis by payer.

## Prescription Schema

### `Prescription.PatientOrder`
- **Description:** Contains records of patient orders for therapies, medications, or services. Tracks order status, dates, and associated providers.
- **Key Columns:**
    - `Id` (Primary Key): Unique identifier for the patient order.
    - `Patient_Id`: Foreign key linking to the patient.
    - `TherapyType_Id`: Foreign key identifying the type of therapy ordered.
    - `PatientOrderStatus_Id`: Foreign key indicating the current status of the order (e.g., Pending, Active, Discontinued).
    - `OrderedDate`, `StartDate`, `StopDate`, `DiscontinuedDate`: Key dates tracking the order lifecycle.
    - `InventoryItem_Id`: Foreign key linking to the specific product/service ordered.
    - `Provider_Id`: Foreign key linking to the ordering provider.
- **Relevance to Dimensions:**
    - **Product Dimension:** Can link to product details via `InventoryItem_Id`.
    - **Patient Dimension:** Links orders to patients via `Patient_Id`.
    - **Provider Dimension:** Links orders to providers via `Provider_Id`.
    - **Date Dimension:** Uses various date fields (`OrderedDate`, `StartDate`, etc.).
- **Relevance to KPIs:**
    - **Clinical:** Therapy adherence, time-to-start therapy, order completion rates, discontinuation reasons (if linked).
    - **Operational:** Order processing time, order volume by therapy type/provider.
    - **Financial:** Can be linked to billing/claims to analyze revenue per order/therapy.

## Common Schema

### `Common.CompanyLocation`
- **Description:** Establishes the relationship between a company entity and a physical location.
- **Key Columns:**
    - `ID` (Primary Key): Unique identifier for the company-location link.
    - `Company_Id`: Foreign key to the `Common.Company` table.
    - `Location_Id`: Foreign key to the `Common.Location` table.
- **Relevance to Dimensions:**
    - **Facility/Location Dimension:** Core table for building a dimension representing operational locations or facilities, likely requiring joins to `Common.Company` and `Common.Location` for descriptive names and addresses.
- **Relevance to KPIs:**
    - **Operational:** Patient volume per location, inventory levels per location (when joined with inventory tables).
    - **Financial:** Revenue or costs associated with specific locations.

## Patient Schema

### `Patient.Patient`
- **Description:** Central table holding demographic, status, and key identifying information about patients.
- **Key Columns:**
    - `Id` (Primary Key): Unique identifier for the patient record (distinct from `Person_Id`).
    - `Person_Id`: Foreign key linking to the `Common.Person` table (likely contains name, contact info).
    - `MedicalRecordNo`: Medical Record Number (MRN).
    - `DateOfBirth`, `Gender_Id`: Core demographic attributes.
    - `ReferralDate`: Date the patient was referred.
    - `PatientStatus_Id`: Foreign key indicating the patient's current status (e.g., Active, Discharged).
    - `PatientDateOfDeath`: Date of death, if applicable.
- **Relevance to Dimensions:**
    - **Patient Dimension:** Primary source table for the Patient dimension. Requires joining with `Common.Person` for full details.
- **Relevance to KPIs:**
    - **Clinical:** Patient outcomes based on demographics, mortality rates.
    - **Operational:** Patient census, active patient counts, referral trends.
    - **Financial:** Revenue per patient demographic group.

### `Patient.PatientPolicy`
- **Description:** Links patients to their specific insurance policies, detailing coverage sequence, effective dates, and policy identifiers.
- **Key Columns:**
    - `Id` (Primary Key): Unique identifier for the patient-policy link.
    - `Patient_Id`: Foreign key linking to the patient.
    - `Carrier_Id`: Foreign key linking to the insurance carrier (`Insurance.Carrier`).
    - `PolicyNumber`, `GroupNumber`, `InsuredIDNumber`: Identifiers for the specific policy.
    - `Sequence`: Indicates the order of insurance coverage (Primary, Secondary, etc.).
    - `EffectiveDate`, `ExpirationDate`: Validity dates for the policy coverage.
    - `PatientRelationToInsured_Id`: Foreign key describing the patient's relationship to the policyholder.
- **Relevance to Dimensions:**
    - **Patient Dimension:** Adds insurance details to the patient profile.
    - **Payer Dimension:** Links specific policies back to carriers.
- **Relevance to KPIs:**
    - **Revenue Cycle:** Payer mix, coordination of benefits accuracy, claim submission accuracy based on policy details, patient liability estimation.
    - **Operational:** Insurance verification workload/status.

### `Patient.PatientReferrals`
- **Description:** Tracks incoming patient referrals, including the source, date, requested service/diagnosis, and status.
- **Key Columns:**
    - `Id` (Primary Key): Unique identifier for the referral record.
    - `Patient_Id`: Foreign key linking to the patient being referred.
    - `ReferralSource_Id`: Foreign key identifying the source of the referral (e.g., Physician, Hospital).
    - `ReferralDate`: Date the referral was made.
    - `ResponseStatus_Id`: Foreign key indicating the status of the referral (e.g., Accepted, Rejected, Pending).
    - `Provider_Id`: Foreign key linking to the referring provider (if applicable).
    - `DiagnosisCode_Id`: Foreign key linking to the primary diagnosis associated with the referral.
- **Relevance to Dimensions:**
    - **Referral Source Dimension:** Can be used to build a dimension analyzing referral patterns.
    - **Provider Dimension:** Links referrals to referring providers.
    - **Diagnosis Dimension:** Links referrals to diagnoses.
- **Relevance to KPIs:**
    - **Operational:** Referral volume, referral conversion rate (referrals leading to active patients), referral processing time, top referral sources.
    - **Marketing/Sales:** Effectiveness of outreach efforts based on referral sources.

## Encounter Schema

### `Encounter.DischargeSummary`
- **Description:** Contains details related to the conclusion of a patient encounter or episode of care, including discharge date, status, and reason.
- **Key Columns:**
    - `Id` (Primary Key): Unique identifier for the discharge summary record.
    - `PatientEncounter_Id`: Foreign key linking to the specific patient encounter (`Encounter.PatientEncounter`).
    - `DischargeDate`: Date the patient was discharged from the encounter/service.
    - `DischargeStatus_Id`: Foreign key indicating the patient's status upon discharge (e.g., Discharged Home, Transferred).
    - `PatientStatus_Id`: Foreign key indicating the overall patient status after discharge (may differ from encounter status).
    - `DischargeReason_Id`: Foreign key explaining the reason for discharge.
- **Relevance to Dimensions:**
    - **Encounter Dimension:** Provides end-state information for encounters.
    - **Discharge Disposition Dimension:** Can source a dimension describing discharge outcomes.
- **Relevance to KPIs:**
    - **Clinical:** Readmission rates (requires linking encounters), discharge outcomes, length of stay (calculated with `PatientEncounter.StartDate`).
    - **Operational:** Patient throughput, bed turnover (if applicable).

### `Encounter.PatientEncounter`
- **Description:** Records individual patient encounters, visits, or episodes of care, tracking start and end dates. This is often a central table for clinical activity.
- **Key Columns:**
    - `Id` (Primary Key): Unique identifier for the encounter.
    - `Patient_Id`: Foreign key linking to the patient.
    - `StartDate`, `EndDate`: Start and end timestamps for the encounter.
- **Relevance to Dimensions:**
    - **Encounter Dimension:** Can serve as the base for an encounter dimension.
    - **Patient Dimension:** Links encounters to patients.
    - **Date Dimension:** Uses `StartDate` and `EndDate`.
- **Relevance to KPIs:**
    - **Operational:** Encounter volume, patient visit frequency, average length of stay/service duration.
    - **Clinical:** Tracking patient progress across encounters, linking clinical events within an encounter timeframe.
    - **Financial:** Basis for encounter-based billing or cost analysis.

## Inventory Schema

### `Inventory.InventoryTransfer`
- **Description:** Tracks the movement of inventory items between different locations within the organization.
- **Key Columns:**
    - `Id` (Primary Key): Unique identifier for the transfer event.
    - `InventoryTransferStatus_Id`: Foreign key indicating the status of the transfer (e.g., Requested, Shipped, Completed).
    - `Source_Id`: Foreign key linking to the source location (`Common.Location`).
    - `Destination_Id`: Foreign key linking to the destination location (`Common.Location`).
    - `DateRequested`, `DateCompleted`, `DateShipped`: Key dates tracking the transfer process.
    - *(Note: This table likely needs to be joined with another table like `InventoryTransferItem` or similar to know *what* items were transferred and in *what quantity*.)*
- **Relevance to Dimensions:**
    - **Location Dimension:** Uses `Source_Id` and `Destination_Id`.
    - **Date Dimension:** Uses various date fields.
- **Relevance to KPIs:**
    - **Inventory Management:** Transfer frequency, transfer lead times, inventory velocity between locations.
    - **Operational:** Efficiency of internal logistics.
    - **Financial:** Can contribute to calculating the cost of goods sold (COGS) if item costs are associated.

