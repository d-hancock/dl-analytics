# Staging Layer

## Purpose
The staging layer mirrors raw sources, cleans up column names, and casts types. It provides a one-to-one mapping with the source tables.

## Conventions
- Prefix: `stg_`
- No joins or logic.
- Focus on cleaning and casting raw data.
- Columns renamed to follow standardized naming conventions
- Record status filtering (WHERE RecStatus = 1 or Record_Status_Id = 1)

## Schema Alignment
The staging views have been refactored to align with the actual CareTend OLTP database schema as documented in `notes/CareTend_OLTP_DB_Core_Table_Docs.md`. Primary changes include:

- Corrected table names and schema references (e.g., `OLTP_DB.Prescription.PatientOrder` instead of `OLTP_DB.Encounter.PatientOrder`)
- Updated column names to match the actual schema
- Standardized primary key and foreign key naming
- Consistent record status filtering

## Key Source Tables
- Patient Data: `Patient.Patient`, `Patient.PatientPolicy`, `Patient.PatientReferrals` 
- Billing Data: `Billing.Claim`, `Billing.ClaimItem`
- Reference Data: `Provider.Provider`, `Insurance.Carrier`, `Common.CompanyLocation`
- Clinical Data: `Prescription.PatientOrder`, `Encounter.DischargeSummary`

## Examples
- `stg_billing_claim.sql`: Cleans and casts raw billing claim data.
- `stg_date_dimension.sql`: Cleans and casts raw date data.
- `stg_patient_referrals.sql`: Extracts patient referral information.