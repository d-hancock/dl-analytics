# Analytics Requirements to Data Model Mapping

This document outlines how our analytical requirements map to specific components of our data model. It provides a clear traceability from business requirements to the technical implementation.

## Overview

Our analytics data model has been designed to satisfy the core analytical requirements related to:
- Revenue & Margin metrics
- Patient Demographics metrics

The model follows a multi-layer approach where each layer serves a specific purpose in the data transformation pipeline:
1. **Staging Layer** → Raw data from source systems
2. **Intermediate Layer** → Business logic and transformations
3. **Marts Layer** → Domain-specific consolidated facts and KPIs
4. **Presentation Layer** → Dashboard-ready views

## Requirements Mapping

### Revenue & Margin Requirements

| KPI Requirement | Data Model Component | SQL Implementation |
|-----------------|----------------------|-------------------|
| **Total Expected Revenue (Gross)** | `finance.fct_revenue.total_revenue` and `finance.kpi_revenue_metrics.total_expected_revenue` | Sum of expected revenue from claims after contractual adjustments |
| **Drug Revenue** | `finance.fct_revenue.drug_revenue` and `finance.kpi_revenue_metrics.drug_revenue` | Sum of drug-specific revenue from claims |
| **Total Expected Revenue/Day** | `finance.fct_revenue.total_revenue_per_day` and `finance.kpi_revenue_metrics.total_expected_revenue_per_day` | Total expected revenue divided by days in period |

### Patient Demographics Requirements

| KPI Requirement | Data Model Component | SQL Implementation |
|-----------------|----------------------|-------------------|
| **Referrals** | `finance.fct_patient_activity.referrals` and `finance.kpi_patient_metrics.total_referrals` | Count of referrals with status = 'pending' |
| **New Starts** | `finance.fct_patient_activity.new_starts` and `finance.kpi_patient_metrics.total_new_starts` | Unique MRNs looking back 365 days with Status = Active |
| **Discharged Patients** | `finance.fct_patient_activity.discharged_patients` and `finance.kpi_patient_metrics.total_discharged_patients` | Count of patients with discharged status |

## Dimensional Support

All KPIs support analysis across the following dimensions:

| Dimension | Table Support | 
|-----------|---------------|
| **Time Frame** | All fact tables join to `int_dim_date` for time-based analysis |
| **Therapy** | Therapy dimension through `int_dim_therapy` and therapy type columns |
| **Product (Drug)** | Product dimension through `int_dim_product` tables |
| **Nursing Type** | Available in patient activity metrics |
| **Location** | Location dimension through `int_dim_location` |
| **AE (Account Executive)** | Provider dimension available for attribution |
| **Patient Census Status** | Patient status available in patient dimension |

## Dashboard Support

The `dashboard_financial_executive` presentation model brings together all required KPIs and dimensions to support the financial executive dashboard:

- It combines metrics from revenue and patient activity
- Supports all dimensional filtering required by the business
- Provides both detailed and pre-aggregated metrics for flexible reporting
- Includes period comparison metrics for trend analysis

## Data Flow Diagram

The flow from analytical requirements to dashboard delivery follows this pattern:

```
Analytical Requirements → Intermediate Facts → Mart Layer → Presentation Layer → Dashboards
```

Each step adds value:
1. **Intermediate Facts**: Applies core business logic to source data
2. **Mart Layer**: Consolidates metrics and introduces aggregations
3. **Presentation Layer**: Finalizes the dataset with dashboard-specific optimizations

## Validation Strategy

To ensure our data model correctly implements the analytical requirements:

1. **KPI Validation**: Each KPI calculation is validated against source systems
2. **Dimensional Completeness**: Verify all dimensions are available for slicing and dicing
3. **Performance Testing**: Ensure the model supports interactive dashboard performance
4. **Business Review**: Regular review of KPI definitions with business stakeholders
5. **Version Control**: Document changes to KPI definitions over time

## Future Requirements

The current data model is designed to be extensible. New KPIs and dimensions can be added by:

1. Adding new intermediate fact tables for new data sources
2. Extending existing mart layer tables with additional metrics
3. Creating new mart domains for additional business areas
4. Adding new dimensional attributes to support additional filtering