# Finance Marts Layer

## Purpose
The finance marts layer provides finalized facts, aggregated KPIs, and optionally wide marts for reporting. It is tailored for the finance department's needs.

## Conventions
- Prefix: `fct_` for summable numeric grain.
- Prefix: `dim_` for descriptive categorical data.
- Prefix: `kpi_` for pre-aggregated metrics.
- Prefix: `mart_` for denormalized wide reporting tables.

## Schema Alignment Update
The finance marts have been updated to align with the refactored intermediate layer views, which now correctly reflect the actual CareTend OLTP database schema. Key changes include:

- All dimension and fact tables now use the correct primary and foreign keys
- KPI calculations have been updated to use the proper source columns
- Aggregations and metrics now reflect the true data schema

## Key Dimensions
- `dim_date`: Calendar and fiscal time periods for analysis
- `dim_location`: Facilities and locations with regional grouping
- `dim_payer`: Payer information with categorization for revenue analysis
- `dim_product`: Product catalog for revenue and inventory analysis
- `dim_therapy`: Therapy types for clinical and revenue analysis

## Core Facts
- `fct_referrals`: Referral activity for patient acquisition analysis
- `fct_new_starts`: New patient start metrics for growth analysis
- `fct_discharges`: Patient discharge data for patient activity tracking
- `fct_drug_revenue`: Drug revenue data for financial analysis
- `fct_expected_revenue`: Expected revenue projections for forecasting

## Key KPIs
- `kpi_referrals`: Referral count trends and metrics
- `kpi_new_starts`: New patient acquisition performance
- `kpi_discharged_patients`: Patient discharge trends
- `kpi_drug_revenue`: Drug revenue performance metrics
- `kpi_expected_revenue_per_day`: Daily revenue expectations

## Consolidated Marts
- `mart_patient_activity`: Combined view of patient referrals, starts, and discharges
- `mart_revenue_analysis`: Consolidated revenue metrics across products and payers

## Example
- `fct_discharges.sql`: Summable grain-level fact table for discharges.
- `kpi_drug_revenue.sql`: Pre-aggregated metric for drug revenue.