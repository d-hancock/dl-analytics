# CareTend Schema Mapping: Before vs. After Refactoring

This document provides a detailed mapping between the original schema assumptions and the corrected schema based on the CareTend OLTP DB documentation.

## Patient Tables

### Patient Table

| Before (Incorrect) | After (Corrected) | Notes |
|-------------------|-------------------|-------|
| `PatientKey` | `Id` | Primary key correction |
| `PartyKey` | *Removed* | Incorrect join relationship |
| `BirthDate` | `DateOfBirth` | Field name correction |
| `Status` | `RecStatus` | Standardized status field |
| *Missing* | `MedicalRecordNo` | Added from actual schema |
| *Missing* | `ReferralDate` | Added from actual schema |
| *Missing* | `Gender_Id` | Added from actual schema |
| *Missing* | `Team_Id` | Added from actual schema |

### Patient Policy Table

| Before (Incorrect) | After (Corrected) | Notes |
|-------------------|-------------------|-------|
| `PatientPolicyKey` | `Id` | Primary key correction |
| `PatientKey` | `Patient_Id` | Foreign key standardization |
| `CoverageTypeCode` | *Removed* | Field doesn't exist |
| `IsPrimary` | *Removed* | Field doesn't exist |
| `PolicyKey` | *Removed* | Field doesn't exist |
| *Missing* | `Carrier_Id` | Added from actual schema |

## Provider Table

| Before (Incorrect) | After (Corrected) | Notes |
|-------------------|-------------------|-------|
| `ProviderKey` | `Id` | Primary key correction |
| *Missing* | `ProviderName` | Added from actual schema |
| *Missing* | `NPI` | Added from actual schema |
| *Missing* | `IsActive` | Added from actual schema |
| *Missing* | `ProviderType_Id` | Added from actual schema |

## Payer/Carrier Table

| Before (Incorrect) | After (Corrected) | Notes |
|-------------------|-------------------|-------|
| `CarrierKey` | `Id` | Primary key correction |
| `CarrierName` | `BillingOrganizationName` | Field name correction |
| `CarrierTypeCode` | `CarrierType_Id` | Field name correction |
| `IsActive` | *Removed* | Incorrect field |
| `EffectiveDate` | *Removed* | Incorrect field |
| `TerminationDate` | *Removed* | Incorrect field |
| *Missing* | `PayorType_Id` | Added from actual schema |
| *Missing* | `UseMedicareRules` | Added from actual schema |
| *Missing* | `IsSupplementary` | Added from actual schema |

## Claim Tables

### Claim Table

| Before (Incorrect) | After (Corrected) | Notes |
|-------------------|-------------------|-------|
| *Not referenced* | `Id` | Added primary key |
| *Not referenced* | `Invoice_Id` | Added from actual schema |
| *Not referenced* | `Carrier_Id` | Added from actual schema |
| *Not referenced* | `Patient_Id` | Added from actual schema |
| *Not referenced* | `ClaimType_Id` | Added from actual schema |
| *Not referenced* | `ServiceFromDate` | Added from actual schema |
| *Not referenced* | `Record_Status_Id` | Added from actual schema |

### Claim Item Table

| Before (Incorrect) | After (Corrected) | Notes |
|-------------------|-------------------|-------|
| *Not referenced* | `Id` | Added primary key |
| *Not referenced* | `Claim_Id` | Added foreign key |
| *Not referenced* | `Invoice_Id` | Added from actual schema |
| *Not referenced* | `InventoryItem_Id` | Added from actual schema |
| *Not referenced* | `Quantity` | Added from actual schema |
| *Not referenced* | `ExpectedPrice` | Added from actual schema |
| *Not referenced* | `TotalExpectedPrice` | Added from actual schema |
| *Not referenced* | `ServiceFromDate` | Added from actual schema |
| *Not referenced* | `RecStatus` | Added from actual schema |

## Location/Facility Tables

| Before (Incorrect) | After (Corrected) | Notes |
|-------------------|-------------------|-------|
| `CompanyLocationKey` | `CompanyLocation_Id` | Primary key correction |
| `CompanyKey` | `Company_Id` | Foreign key standardization |
| `LocationCode` | *Removed* | Field doesn't exist |
| `LocationName` | `Location_Name` | Field name correction |
| `IsActive` | *Removed* | Field doesn't exist |
| `AddressKey` | *Removed* | Incorrect join relationship |

## Patient Orders / Referrals Tables

| Before (Incorrect) | After (Corrected) | Notes |
|-------------------|-------------------|-------|
| `OLTP_DB.Encounter.PatientOrder` | `OLTP_DB.Prescription.PatientOrder` | Corrected schema name |
| `OLTP_DB.Encounter.PatientEncounter` | `OLTP_DB.Patient.PatientReferrals` | Complete table correction |
| `order_date` | `OrderedDate` | Field name correction |
| `order_id` | `Id` | Field name standardization |
| `order_type` | `TherapyType_Id` | Field name correction |
| *Missing* | `PatientOrderStatus_Id` | Added from actual schema |
| *Missing* | `InventoryItem_Id` | Added from actual schema |

## Key Join Relationships Changed

1. **Patient to Party**: Removed incorrect join between Patient and Party tables
2. **Patient to PatientPolicy**: Updated join condition to use `Id`/`Patient_Id` instead of `PatientKey`
3. **Claim to ClaimItem**: Added proper join using `Id`/`Claim_Id` 
4. **Patient to PatientReferrals**: Added proper join using `Id`/`Patient_Id`
5. **Patient to PatientOrder**: Added proper join using `Id`/`Patient_Id`

## Status Field Standardization

Status fields have been standardized across all tables:
- `Record_Status_Id = 1` or `RecStatus = 1` used consistently for active records
- Removed incorrect status flags like `IsActive = 'Y'`