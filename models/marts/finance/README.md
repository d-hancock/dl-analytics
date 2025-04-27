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

## Current Mart Layer Tables

### Facts
- `fct_revenue`: Consolidated revenue facts from drug and expected revenue
  - Combines data from `int_fct_drug_revenue` and `int_fct_expected_revenue`
  - Daily grain with dimensional coverage for location, product, therapy, and payer
  - Core metrics: drug_revenue, non_drug_revenue, total_revenue, revenue_per_day

- `fct_patient_activity`: Consolidated patient activity metrics
  - Combines data from `int_fct_referrals`, `int_fct_new_starts`, and `int_fct_discharges`
  - Daily grain with consistent dimensional attributes
  - Core metrics: referrals, new_starts, discharged_patients, net_patient_change

### KPIs
- `kpi_revenue_metrics`: Pre-aggregated revenue KPIs for dashboard consumption
  - Period-level aggregations (daily, monthly, quarterly, yearly)
  - Period-over-period comparisons and growth calculations
  - Optimized for KPI card displays and trend charts

- `kpi_patient_metrics`: Pre-aggregated patient KPIs for dashboard consumption
  - Aggregated patient metrics with conversion rates and growth calculations
  - Period-level metrics for dashboard KPIs
  - Patient activity trends and comparisons

## Usage

These mart layer tables serve as the foundation for the presentation layer. The `dashboard_financial_executive` view in the presentation layer consumes these tables to create a consolidated dataset for the financial executive dashboard.

### How to Use

When building reports or dashboards:
1. For detailed analysis, use the fact tables (`fct_revenue`, `fct_patient_activity`)
2. For KPI reporting, use the pre-aggregated KPI tables (`kpi_revenue_metrics`, `kpi_patient_metrics`)
3. For dashboard creation, use the presentation layer views that consume these mart tables

### Dimensional Analysis

All facts and KPIs support analysis across these key dimensions:
- Time (calendar_date, fiscal_year, fiscal_quarter, fiscal_month)
- Location (location_id, location_name, region)
- Product (product_id, product_name, product_category)
- Therapy (therapy_type_id, therapy_class)
- Payer (payer_id, payer_name, payer_category)

## Analytical Requirements Coverage

These mart tables fulfill the analytical requirements specified in `/documentation/analytics_requirements_mapping.md`, providing all required metrics for:
- Revenue & Margin metrics (Total Expected Revenue, Drug Revenue, Revenue/Day)
- Patient Demographics (Referrals, New Starts, Discharged Patients)

## Maintenance

When updating these models:
1. Ensure all dimensional joins are maintained
2. Validate KPI calculations against source data
3. Update documentation when calculations change
4. Run tests to ensure data consistency