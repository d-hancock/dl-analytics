# CareTend OLTP Schema Refactoring Summary

## Overview
This document summarizes the schema refactoring performed based on the CareTend OLTP DB Data Dictionary. The refactoring was necessary to ensure our analytics views correctly reflect the actual database schema, improving data consistency and reliability.

## Key Issues Addressed

1. **Table Name Mismatches**
   - Changed references from `OLTP_DB.Encounter.PatientEncounter` to `OLTP_DB.Patient.PatientReferrals` for tracking referrals
   - Updated references from `OLTP_DB.Encounter.PatientOrder` to `OLTP_DB.Prescription.PatientOrder` for order data

2. **Column Name Mismatches**
   - Corrected column names across all tables to match the documented schema
   - Example: Changed `PatientKey` to `Id` in Patient tables, `CarrierKey` to `Id` in Carrier tables

3. **Table Relationships**
   - Corrected join conditions between tables to reflect actual foreign key relationships
   - Rebuilt intermediate views to use proper keys for joining tables

4. **Status Field References**
   - Standardized the use of `RecStatus` or `Record_Status_Id` for filtering active records
   - Ensured consistent filtering across all views

## Refactoring Strategy

1. **Staging Layer**
   - Rebuilt all staging views to correctly reference OLTP tables and columns
   - Added proper filters for active records
   - Added missing columns needed for analytics

2. **Intermediate Layer**
   - Updated all intermediate views to use corrected staging views
   - Rebuilt join logic to ensure data integrity
   - Ensured proper dimensional modeling principles were applied

## Affected Tables

This refactoring impacted references to the following OLTP DB tables:

1. OLTP_DB.Provider.Provider
2. OLTP_DB.Common.Party
3. OLTP_DB.Insurance.Carrier
4. OLTP_DB.Patient.Patient
5. OLTP_DB.Patient.PatientPolicy
6. OLTP_DB.Inventory.InventoryItemLocationQuantity
7. OLTP_DB.Inventory.InventoryTransfer
8. OLTP_DB.Common.CompanyLocation
9. OLTP_DB.Billing.InvoiceClaimItemLink
10. OLTP_DB.Utilities.Date
11. OLTP_DB.Patient.PatientReferrals
12. OLTP_DB.Prescription.PatientOrder
13. OLTP_DB.Billing.Claim
14. OLTP_DB.Billing.ClaimItem
15. OLTP_DB.Encounter.DischargeSummary

## Next Steps

1. Update mart layer views to use the corrected intermediate views
2. Validate all KPI calculations using the updated schema
3. Update documentation to reflect the correct schema references
4. Implement unit tests to verify data integrity across all layers