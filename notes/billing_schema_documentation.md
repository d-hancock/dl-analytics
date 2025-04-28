# Billing Schema Documentation

## Overview

The Billing schema contains approximately 65 tables that handle various aspects of the medical billing process in the CareTend OLTP database. These tables support different billing workflows, payment processing, claim management, and financial tracking. This document provides detailed descriptions of key tables and outlines their potential use for KPI development.

## Core Table Categories

The Billing schema can be organized into several functional categories:

1. **Claim Management** - Tables for handling healthcare claims
2. **Invoice Processing** - Tables for managing patient invoices
3. **Payment Processing** - Tables for tracking payments and adjustments
4. **Financial Aggregation** - Tables that summarize financial data
5. **Electronic Remittance** - Tables for processing electronic payments
6. **Specialized Billing** - Tables for specific billing types (pharmacy, UB04, etc.)

## Key Tables and KPI Relevance

### Claim Management

#### `Billing.Claim`
**Description:** The central table for claims with links to invoices, policies, and carriers.

**Key Columns:**
- `Id` (PK): Unique identifier for the claim
- `Invoice_Id`: Link to the invoice this claim is associated with
- `PatientPolicy_Id`: Link to the patient's insurance policy
- `Carrier_Id`: Insurance carrier/payer
- `ClaimType_Id`: Type of claim (CMS-1500, UB04, etc.)
- `BilledDate`: Date the claim was submitted
- `IsBilledForDenial`: Flag indicating if billed intentionally for denial
- `IsCrossOverClaim`: Flag indicating if claim was crossed over from another payer

**KPI Relevance:**
- **Revenue Cycle KPIs:**
  - Claim submission volumes by type, carrier, provider
  - Time from service to claim (with join to Invoice)
  - Percentage of claims billed for denial
- **Financial KPIs:**
  - Gross claim values by payer/claim type
  - Cross-over claim percentage and value

#### `Billing.ClaimItem`
**Description:** Items/services within claims, representing individual line items billed.

**Key Columns:**
- `Id` (PK): Unique identifier for the claim item
- `Claim_Id`: Link to the parent claim
- `Invoice_Id`: Link to the invoice (may be redundant with claim)
- `Hcpc_Id`: Healthcare Common Procedure Coding System code
- `ServiceFromDate`, `ServiceToDate`: Service date range
- `Quantity`: Number of units billed
- `BilledPrice`, `ExpectedPrice`: Price amounts
- `BilledTax`, `ExpectedTax`: Tax amounts
- `IsTaxable`: Flag indicating taxable status
- `PatientOrder_Id`: Link to the patient's order (if applicable)

**KPI Relevance:**
- **Revenue Cycle KPIs:**
  - Average units billed per claim
  - Revenue by procedure code/service
- **Financial KPIs:**
  - Expected vs. billed amount variance
  - Average claim line value
- **Operational KPIs:**
  - Service mix analysis
  - Rental vs. purchase analysis (based on IsRental)

#### `Billing.ClaimStatusHistory`
**Description:** Tracks changes in claim status over time.

**Key Columns:**
- `Id` (PK): Unique identifier
- `Claim_Id`: Link to the claim
- `ClaimStatus_Id`: Claim status
- `StatusDate`: Date of status change
- `IsActive`: Whether this is the current status

**KPI Relevance:**
- **Revenue Cycle KPIs:**
  - Claim lifecycle analysis
  - Claim aging by status
- **Operational KPIs:**
  - Claim status transition patterns
  - Average time spent in each claim status

### Invoice Processing

#### `Billing.Invoice`
**Description:** Contains patient invoice records, serving as the basis for claims.

**Key Columns:**
- `Id` (PK): Unique identifier
- `InvoiceNumber`: Business-facing invoice number
- `Patient_Id`: Link to the patient
- `Carrier_Id`: Link to the primary carrier/payer
- `ServiceFromDate`, `ServiceToDate`: Service period
- `IsPointOfSale`: Flag indicating point-of-sale transaction
- `IsRevenue`: Flag indicating if the invoice should be counted as revenue
- `ClosedDate`: Date the invoice was closed/finalized

**KPI Relevance:**
- **Financial KPIs:**
  - Gross/net revenue
  - Revenue by service date periods
  - Point-of-sale vs. traditional billing comparison
- **Operational KPIs:**
  - Invoice volume trends
  - Average invoice value
  - Time to invoice closure

#### `Billing.InvoiceItem`
**Description:** Line items on invoices, representing individual services or products.

**Key Columns:**
- `Id` (PK): Unique identifier
- `Invoice_Id`: Link to parent invoice
- `InventoryItem_Id`: Link to inventory item
- `Quantity`: Number of units
- `BilledPrice`, `ExpectedPrice`: Price amounts
- `BilledTax`, `ExpectedTax`: Tax amounts
- `TotalBilledPrice`, `TotalExpectedPrice`: Calculated totals

**KPI Relevance:**
- **Financial KPIs:**
  - Revenue by product/service
  - Average price per unit
  - Pricing variance analysis
- **Inventory KPIs:**
  - Units sold by item
  - Revenue contribution by product category

#### `Billing.InvoiceCOB`
**Description:** Coordination of Benefits information for invoices, tracking secondary payer details.

**Key Columns:**
- `Id` (PK): Unique identifier
- `Invoice_Id`: Link to invoice
- `PatientPolicy_Id`: Link to policy
- `Carrier_Id`: Link to carrier
- `PayorPaidAmount`, `AllowedAmount`, `PatientResponsibilityAmount`: Various payment components

**KPI Relevance:**
- **Financial KPIs:**
  - Secondary payer contribution
  - Patient responsibility analysis
  - Write-off analysis (comparing allowed vs. billed)
- **Revenue Cycle KPIs:**
  - COB utilization rate
  - Average secondary payer reimbursement

### Payment Processing

#### `Billing.ClaimItemTransaction`
**Description:** Tracks financial transactions at the claim line item level.

**Key Columns:**
- `Id` (PK): Unique identifier
- `Claim_Id`, `ClaimItem_Id`: Links to claim and line item
- `TransactionType_Id`: Type of transaction (payment, adjustment, etc.)
- `Amount`: Transaction amount
- `PostedDate`, `DepositedDate`: Key transaction dates
- `WasExpected`: Flag indicating if payment matched expectation
- `AccountingPeriod_Id`: Accounting period for financial reporting

**KPI Relevance:**
- **Revenue Cycle KPIs:**
  - Payment velocity (time from claim to payment)
  - Payment variance from expected
  - Transaction type distribution
- **Financial KPIs:**
  - Cash flow analysis
  - Payment timing patterns
  - Period-based financial reporting

#### `Billing.UnappliedCash`
**Description:** Tracks payments received but not yet applied to claims.

**Key Columns:**
- `Id` (PK): Unique identifier
- `Patient_Id`, `Carrier_Id`: Source of payment
- `Amount`: Payment amount
- `DepositDate`: When payment was received
- `UnappliedPaymentType_Id`: Type of payment
- `CreditCardTransaction_Id`: Link to credit card transaction (if applicable)

**KPI Relevance:**
- **Revenue Cycle KPIs:**
  - Unapplied cash aging
  - Cash application efficiency
- **Financial KPIs:**
  - Cash holdings in suspense
  - Payment source analysis

#### `Billing.CreditCardTransaction`
**Description:** Records credit card payment transactions.

**Key Columns:**
- `Id` (PK): Unique identifier
- `CreditCardTransactionType_Id`: Type of transaction (charge, refund, etc.)
- `Patient_Id`: Link to patient
- `TransactionDate`: Date of transaction
- `TotalAmount`: Amount processed
- `IsVoided`: Whether transaction was voided
- `RefundedAmount`: Amount refunded

**KPI Relevance:**
- **Financial KPIs:**
  - Payment method distribution
  - Credit card transaction volume
  - Refund rate analysis
- **Operational KPIs:**
  - Void/refund frequency

### Financial Aggregation

#### `Billing.PatientAggregate`
**Description:** Financial summaries by patient, providing rolled-up financial metrics.

**Key Columns:**
- `Id` (PK): Unique identifier (likely matches Patient_Id)
- `BilledPrice`, `ExpectedPrice`: Total prices
- `BilledTax`, `ExpectedTax`: Total tax
- `TotalBilledPrice`, `TotalExpectedPrice`: Total with tax
- `TotalAdjusted`, `TotalCredits`, `TotalPaid`, `TotalTransfers`: Payment components
- `Balance`: Current balance
- `TotalRevenue`: Total recognized revenue
- `PatientBalance`, `InsuranceBalance`: Split of responsibility
- `LastPaymentDate`, `LastBilledDate`: Key dates

**KPI Relevance:**
- **Financial KPIs:**
  - Average patient value
  - Collection rate by patient
  - Patient balance aging
- **Revenue Cycle KPIs:**
  - Patient vs. insurance payment ratio
  - Outstanding balance analysis
  - Revenue recognition metrics

#### `Billing.ClaimAggregate`, `Billing.ClaimItemAggregate`, `Billing.InvoiceAggregate`, `Billing.InvoiceItemAggregate`
**Description:** Financial summaries at different levels of the billing hierarchy.

**Key Columns (similar pattern across tables):**
- `Id` (PK): Unique identifier (linked to parent object)
- `BilledPrice`, `ExpectedPrice`: Total prices
- `TotalPaid`, `TotalAdjusted`: Payment components
- `Balance`: Current balance

**KPI Relevance:**
- **Financial KPIs:**
  - Collection rates at various levels
  - Adjustment patterns
  - Performance by billing entity
- **Revenue Cycle KPIs:**
  - Balance aging at various levels

#### `Billing.AccountingPeriod`
**Description:** Defines accounting periods for financial reporting.

**Key Columns:**
- `Id` (PK): Unique identifier
- `PeriodBeginDate`, `PeriodEndDate`: Period date range
- `FiscalYear_Id`: Link to fiscal year
- `AccountingPeriodStatus_Id`: Status of the period (open, closed, etc.)

**KPI Relevance:**
- **Financial KPIs:**
  - Period-over-period analysis
  - Fiscal year reporting
  - Seasonality analysis
- **Revenue Cycle KPIs:**
  - Period-based collection metrics

### Electronic Remittance

#### `Billing.ERNBatch`
**Description:** Batches of electronic remittance notices (ERNs) received from payers.

**Key Columns:**
- `Id` (PK): Unique identifier
- `DepositedDate`, `PostedDate`, `CheckDate`: Key dates
- `CheckNumber`, `CheckAmount`: Payment details
- `PayerName`, `PayerID`: Payer identification
- `IsCompleted`: Processing status

**KPI Relevance:**
- **Revenue Cycle KPIs:**
  - Electronic payment adoption rate
  - Average processing time
  - Payer performance metrics
- **Financial KPIs:**
  - Electronic payment volume trends

#### `Billing.ERNClaim` and `Billing.ERNClaimItem`
**Description:** Individual claims and line items within electronic remittance notices.

**Key Columns:**
- `ERNClaim.Id`, `ERNClaimItem.Id` (PKs): Unique identifiers
- `Claim_Id`, `ClaimItem_Id`: Links to original claims
- `BilledAmount`, `PaymentAmount`: Financial amounts
- `PatientResponsibleAmount`: Patient portion

**KPI Relevance:**
- **Revenue Cycle KPIs:**
  - Claim adjudication outcomes
  - Payment accuracy
  - Patient responsibility assessment
- **Financial KPIs:**
  - Reimbursement rate by payer/service

#### `Billing.ERNClaimAdjustment` and `Billing.ERNClaimItemAdjustment`
**Description:** Adjustment details from electronic remittances.

**Key Columns:**
- `Id` (PK): Unique identifier
- `GroupCode_Id`, `ReasonCode_Id`: Categorizes the adjustment
- `AdjustmentAmount`: Amount of adjustment

**KPI Relevance:**
- **Revenue Cycle KPIs:**
  - Denial rates by reason
  - Adjustment patterns by payer
  - Write-off analysis
- **Financial KPIs:**
  - Contractual allowance trends
  - Non-contractual adjustment impact

### Specialized Billing

#### `Billing.RecurringRental` and `Billing.RecurringRentalItem`
**Description:** Handles recurring rental billing for durable medical equipment.

**Key Columns:**
- `Id` (PK): Unique identifier
- `RecurringRental.Patient_Id`: Link to patient
- `BillingStartDate`, `NextBillDate`, `BillingEndDate`: Key dates
- `NumberOfBillingCycles`: Billing frequency
- `RecurringRentalItem.InventoryItem_Id`: Rented item

**KPI Relevance:**
- **Financial KPIs:**
  - Recurring revenue streams
  - Rental vs. purchase revenue ratio
  - Average rental duration
- **Operational KPIs:**
  - Equipment utilization
  - Rental conversion rates

#### `Billing.ClaimPharmacyDetail`
**Description:** Specialized information for pharmacy claims.

**Key Columns:**
- `Id` (PK): Unique identifier
- `PrescriptionNumber`: Prescription identifier
- `DateRxWritten`, `DateFilled`: Key dates
- `QuantityPrescribed`, `DaysSupplied`: Supply metrics
- `DispensingFee`, `SalesTaxRate`: Additional costs

**KPI Relevance:**
- **Clinical KPIs:**
  - Prescription volume
  - Days supply metrics
  - Refill patterns
- **Financial KPIs:**
  - Pharmacy revenue streams
  - Dispensing fee impact
  - Average prescription value

#### `Billing.ClaimUB04Detail`
**Description:** Contains specialized fields for institutional UB-04 claims.

**Key Columns:**
- `Id` (PK): Unique identifier
- `TypeofBill`: UB-04 bill type code
- `AdmissionSource_Id`, `PatientDischargeStatus_Id`: Admission/discharge info
- Various UB-04 specific fields and codes

**KPI Relevance:**
- **Clinical KPIs:**
  - Admission source patterns
  - Discharge status outcomes
- **Financial KPIs:**
  - Institutional billing performance
  - Inpatient vs. outpatient revenue

## Business Intelligence and KPI Applications

The Billing schema provides rich data for various categories of KPIs:

### Revenue Cycle KPIs
- **Days Sales Outstanding (DSO)**: Using `BilledDate` from claims and payment dates from transactions
- **Clean Claim Rate**: Analyzing adjustment codes and denial patterns
- **Denial Rate by Reason**: Using ERN adjustment codes
- **First-Pass Resolution Rate**: Claims paid without additional work
- **Average Reimbursement Percentage**: Comparing expected to actual payments
- **Authorization Compliance**: Claims with valid authorizations

### Financial KPIs
- **Gross Revenue**: Total billed amounts
- **Net Revenue**: After adjustments
- **Average Payment**: By payer, service type
- **Cash Collections**: Total payments received
- **Contractual Allowance**: Negotiated write-offs
- **Patient Responsibility Collection Rate**: Patient payments vs. responsibility

### Operational KPIs
- **Billing Lag**: Time from service to claim submission
- **Payment Velocity**: Time from claim to payment
- **Billing Accuracy**: Claims requiring correction
- **Rental Equipment Utilization**: Through recurring rental data
- **Claim Submission Volume**: By type, carrier, day/week/month
- **Adjustment Reason Distribution**: Understanding payment issues

### Clinical-Financial KPIs
- **Revenue by Treatment Type**: Combining clinical and financial data
- **Profitability by Therapy Type**: Comparing costs to reimbursement
- **Pharmacy Fill Rate**: Through pharmacy-specific claims

## Database Design Observations

The Billing schema demonstrates several design patterns:

1. **Hierarchical Structure**: Invoice → Claim → ClaimItem hierarchy
2. **Aggregate Tables**: Financial summaries precalculated at multiple levels
3. **Specialized Sub-Tables**: Extended information for specific claim types
4. **Temporal Tracking**: History tables for status changes over time
5. **Transaction Tracking**: Detailed payment and adjustment tracking

## Data Warehouse Integration Considerations

When building analytics from this schema:

1. **Grain Alignment**: Ensure fact tables align with appropriate grain (claim, line item)
2. **Time Dimensions**: Create consistent date handling across service, billing, and payment dates
3. **Hierarchical Relationships**: Maintain the invoice → claim → line item hierarchy
4. **Status-Based Analysis**: Support point-in-time and historical status analysis
5. **Financial Reconciliation**: Ensure aggregate measures reconcile across levels

## Conclusion

The Billing schema offers comprehensive data to support financial, operational, and clinical analytics. By properly modeling this data in the data warehouse, we can create robust KPIs that provide insights into revenue cycle performance, financial health, and operational efficiency.