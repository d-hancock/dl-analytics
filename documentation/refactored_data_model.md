# Refactored CareTend Analytics Data Model

## Overview

This document provides a comprehensive overview of the refactored CareTend analytics data model. The refactoring was performed to ensure our analytics views correctly reflect the actual CareTend OLTP database schema, improving data consistency and reliability.

## Data Model Architecture

Our analytics data model follows a multi-layered approach:

1. **Staging Layer** (`stg_*`): Direct 1:1 representation of source tables with minimal transformations
2. **Intermediate Layer** (`int_*`): Business logic transformations and dimensional modeling
3. **Marts Layer** (`finance.*`): Purpose-built views for specific business domains
4. **Presentation Layer** (`dashboard_*`): Final views used for dashboards and reporting

## Core Source Tables

The following OLTP DB tables serve as the foundation for our analytics model:

### Patient Data
- `OLTP_DB.Patient.Patient`: Core patient demographic information
- `OLTP_DB.Patient.PatientPolicy`: Patient insurance coverage details
- `OLTP_DB.Patient.PatientReferrals`: Patient referral information

### Billing Data
- `OLTP_DB.Billing.Claim`: Claim header information
- `OLTP_DB.Billing.ClaimItem`: Claim line item details
- `OLTP_DB.Billing.Invoice`: Invoice header information
- `OLTP_DB.Billing.InvoiceItem`: Invoice line item details

### Reference Data
- `OLTP_DB.Provider.Provider`: Healthcare provider information
- `OLTP_DB.Insurance.Carrier`: Insurance carrier/payer information
- `OLTP_DB.Common.CompanyLocation`: Facility/location information
- `OLTP_DB.Common.Party`: Entity relationship data
- `OLTP_DB.Utilities.Date`: Date dimension reference

### Clinical Data
- `OLTP_DB.Prescription.PatientOrder`: Patient therapy orders
- `OLTP_DB.Encounter.DischargeSummary`: Patient discharge information

## Key Dimensions

### Patient Dimension
- Source: `OLTP_DB.Patient.Patient`
- Key fields: `patient_id`, `medical_record_number`, `birth_date`, `gender_id`
- Used for: Patient demographics and attributes for analysis

### Provider Dimension
- Source: `OLTP_DB.Provider.Provider`
- Key fields: `provider_id`, `provider_name`, `provider_npi`, `provider_type_id`
- Used for: Provider-based analysis and filtering

### Payer Dimension
- Source: `OLTP_DB.Insurance.Carrier`
- Key fields: `payer_id`, `payer_name`, `carrier_type_id`, `payor_type_id`
- Used for: Payer mix analysis and reimbursement tracking

### Location Dimension
- Source: `OLTP_DB.Common.CompanyLocation`
- Key fields: `facility_id`, `company_id`, `location_id`, `facility_name`
- Used for: Facility-based reporting and regional analysis

### Date Dimension
- Source: `OLTP_DB.Utilities.Date`
- Key fields: `date_id`, `calendar_date`, various date parts
- Used for: Time-based analysis across all facts

## Key Fact Tables

### Referrals Fact
- Source: `OLTP_DB.Patient.PatientReferrals`
- Grain: One row per patient referral
- Key metrics: Referral counts, referral-to-response time

### New Starts Fact
- Source: `OLTP_DB.Patient.Patient`, `OLTP_DB.Prescription.PatientOrder`
- Grain: One row per new patient start
- Key metrics: New patient counts by period and team

### Discharges Fact
- Source: `OLTP_DB.Encounter.DischargeSummary`
- Grain: One row per patient discharge event
- Key metrics: Discharge counts, length of stay

### Drug Revenue Fact
- Source: `OLTP_DB.Billing.ClaimItem`, `OLTP_DB.Billing.Claim`
- Grain: One row per claim line item
- Key metrics: Revenue amounts, quantities, prices

### Expected Revenue Fact
- Source: `OLTP_DB.Billing.ClaimItem`, `OLTP_DB.Billing.Claim`
- Grain: One row per claim line item with expected revenue
- Key metrics: Expected revenue by date, payer, product

## Marts Layer Tables

The marts layer consists of consolidated, domain-specific tables that bridge the gap between intermediate facts and presentation layer. The finance mart includes:

### Revenue Facts Table (`finance.fct_revenue`)
- Source: `int_fct_drug_revenue`, `int_fct_expected_revenue`
- Grain: One row per calendar_date × product × patient × payer
- Key metrics: Drug revenue, non-drug revenue, total revenue, revenue per day
- Dimensions: Time, product, therapy, location, payer

### Patient Activity Facts Table (`finance.fct_patient_activity`)
- Source: `int_fct_referrals`, `int_fct_new_starts`, `int_fct_discharges`
- Grain: One row per calendar_date × location × therapy type
- Key metrics: Referrals, new starts, discharges, net patient change
- Dimensions: Time, location, therapy type

### Revenue KPI Table (`finance.kpi_revenue_metrics`)
- Source: `finance.fct_revenue`
- Grain: One row per fiscal_period × location × product × therapy × payer
- Key metrics: Aggregated revenue metrics, period-over-period comparisons, growth rates
- Purpose: Pre-aggregated metrics for dashboard KPIs

### Patient KPI Table (`finance.kpi_patient_metrics`)
- Source: `finance.fct_patient_activity`
- Grain: One row per fiscal_period × location × therapy type
- Key metrics: Aggregated patient metrics, referral-to-start conversion rate, growth rates
- Purpose: Pre-aggregated metrics for dashboard KPIs

## Presentation Layer

### Financial Executive Dashboard View (`dashboard_financial_executive`)
- Source: Combines `finance.fct_revenue`, `finance.fct_patient_activity`, `finance.kpi_revenue_metrics`, and `finance.kpi_patient_metrics`
- Grain: One row per calendar_date × location × product × therapy × payer
- Key features: Time-filtered, dimension-complete, pre-aggregated KPIs
- Purpose: Primary source for financial executive Tableau dashboard

## Key Performance Indicators (KPIs)

Our data model supports these core business KPIs:

1. **Referrals**: Count of patient referrals by period
2. **New Starts**: Count of new patients starting therapy
3. **Discharged Patients**: Count of patient discharges by period
4. **Drug Revenue**: Revenue from drug-related claims
5. **Expected Revenue Per Day**: Daily expected revenue forecasts
6. **Total Expected Revenue**: Total revenue expected to be collected
7. **Net Patient Change**: New starts minus discharges by period
8. **Referral to Start Conversion Rate**: Percentage of referrals that convert to new starts

## Schema Naming Conventions

- Primary keys are named with the entity name + "_id" (e.g., `patient_id`, `claim_id`)
- Foreign keys maintain the same name as their referenced primary key
- Date fields end with "_date" (e.g., `referral_date`, `service_from_date`)
- Status fields end with "_status" or "_status_id"
- Record status flags are named `record_status`

## Best Practices for Using This Data Model

1. Always join to dimensions using the appropriate keys
2. Filter for active records (`record_status = 1`) in fact tables
3. Use appropriate date dimensions for time-based analysis
4. Refer to intermediate layer views for reusable business logic
5. Use mart layer views for domain-specific analysis
6. For dashboard creation, use the presentation layer views
7. For KPI metrics, leverage pre-aggregated KPI tables in the marts layer