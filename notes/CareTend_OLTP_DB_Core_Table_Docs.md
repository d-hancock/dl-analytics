# CareTend OLTP DB Table Documentation

## `Utilities.Date`

| Column Name | Notes |
|-------------|-------|
| Id |  |
| DayDate |  |
| DayOfCalendarWeek |  |
| DayOfCalendarMonth |  |
| DayOfCalendarQuarter |  |
| DayOfCalendarYear |  |
| DayNameShort |  |
| DayNameLong |  |
| CalendarWeekId |  |
| CalendarMonthId |  |
| CalendarQuarterId |  |
| CalendarYearId |  |

## `Insurance.Carrier`

| Column Name | Notes |
|-------------|-------|
| Id |  |
| CarrierType_Id |  |
| PayorType_Id |  |
| Identifier |  |
| OptionalOrganizationName |  |
| BillingOrganizationName |  |
| UseMedicareRules |  |
| ClaimInsuranceType_Id |  |
| ElectronicClaimType_Id |  |
| UseICD9DiagnosisCodes |  |
| IsIncludedIn340BExport |  |
| IsSupplementary |  |
| IsAlwaysBilledForDenial |  |
| IsMedicareCBAProvider |  |
| IsOneClaimRecurringRental |  |
| CarrierPhoneNumber |  |
| CreatedDate |  |
| ModifiedDate |  |

## `Drug.Drug`

| Column Name | Notes |
|-------------|-------|
| Id |  |
| Description |  |
| Active |  |
| Taxable |  |
| ItemType_Id |  |
| DefaultOrderType_Id |  |
| ProductType_Id |  |
| SolutionVolume |  |
| Hcpc_Id |  |
| NDCUnitQualifier_Id |  |
| Category_Id |  |
| DefaultTherapyType_Id |  |
| PrescriptionFormat_Id |  |
| DosageForm_Id |  |
| DispensingUnit_Id |  |
| QuantityPerEach |  |
| CreatedDate |  |
| ModifiedDate |  |

## `Common.CompanyLocation`

| Column Name | Notes |
|-------------|-------|
| CompanyLocation_Id |  |
| Company_Id |  |
| Location_Id |  |
| Location_Name |  |

## `Patient.Patient`

| Column Name | Notes |
|-------------|-------|
| Id |  |
| MedicalRecordNo |  |
| ReferralDate |  |
| DateOfBirth |  |
| Gender_Id |  |
| PrimaryRN_Id |  |
| CodeStatus_Id |  |
| PatientDateOfDeath |  |
| Team_Id |  |
| InsuranceCoordinator_Id |  |
| AdvanceDirectives |  |
| InformationComplete |  |
| RecStatus |  |

## `Provider.Provider`

| Column Name | Notes |
|-------------|-------|
| Id |  |
| ProviderName |  |
| NPI |  |
| IsActive |  |
| ProviderType_Id |  |

## `Billing.InvoiceItem`

| Column Name | Notes |
|-------------|-------|
| Id |  |
| Invoice_Id |  |
| InventoryItem_Id |  |
| InventoryItemType_Id |  |
| ItemName |  |
| Quantity |  |
| BilledPrice |  |
| ExpectedPrice |  |
| BilledTax |  |
| ExpectedTax |  |
| TotalBilledPrice |  |
| TotalExpectedPrice |  |
| CreatedDate |  |
| ModifiedDate |  |
| RecStatus |  |

## `Billing.Invoice`

| Column Name | Notes |
|-------------|-------|
| Id |  |
| InvoiceNumber |  |
| Patient_Id |  |
| Carrier_Id |  |
| BillingProvider_Id |  |
| Company_Id |  |
| ServiceFromDate |  |
| ServiceToDate |  |
| ClosedDate |  |
| TaxCode_Id |  |
| ClaimType_Id |  |
| IsRevenue |  |
| AccountingPeriod_Id |  |
| Record_Status_Id |  |

## `Billing.ClaimItem`

| Column Name | Notes |
|-------------|-------|
| Id |  |
| Claim_Id |  |
| Invoice_Id |  |
| InventoryItem_Id |  |
| Quantity |  |
| BilledPrice |  |
| ExpectedPrice |  |
| BilledTax |  |
| ExpectedTax |  |
| TotalBilledPrice |  |
| TotalExpectedPrice |  |
| ServiceFromDate |  |
| ServiceToDate |  |
| CreatedDate |  |
| RecStatus |  |

## `Billing.Claim`

| Column Name | Notes |
|-------------|-------|
| Id |  |
| Invoice_Id |  |
| Carrier_Id |  |
| Patient_Id |  |
| ClaimType_Id |  |
| ServiceFromDate |  |
| Record_Status_Id |  |

## `Patient.PatientReferrals`

| Column Name | Notes |
|-------------|-------|
| Id |  |
| Patient_Id |  |
| ReferralSource_Id |  |
| ReferralRequest |  |
| ReferralDate |  |
| ReferralResponseDate |  |
| ResponseStatus_Id |  |
| CreatedDate |  |
| ModifiedDate |  |
| RecStatus |  |

## `Prescription.PatientOrder`

| Column Name | Notes |
|-------------|-------|
| Id |  |
| Patient_Id |  |
| TherapyType_Id |  |
| PatientOrderStatus_Id |  |
| OrderedDate |  |
| StartDate |  |
| StopDate |  |
| DiscontinuedDate |  |
| InventoryItem_Id |  |
| InventoryItemType_Id |  |
| Company_Id |  |
| Provider_Id |  |
| IsAuthorizationRequired |  |
| Record_Status_Id |  |

## `Encounter.DischargeSummary`

| Column Name | Notes |
|-------------|-------|
| Id |  |
| PatientEncounter_Id |  |
| DischargeDate |  |
| DischargeStatus_Id |  |
| PatientStatus_Id |  |
| DischargeReason_Id |  |
| DischargeAcuity_Id |  |
| CreatedDate |  |
| ModifiedDate |  |
| RecStatus |  |
