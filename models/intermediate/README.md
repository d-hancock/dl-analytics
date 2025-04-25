# Intermediate Layer

## Purpose
The intermediate layer applies joins, derives row-level metrics, and enriches logic. It bridges the gap between raw staging data and finalized marts.

## Conventions
- Prefix: `int_`
- Use `int_dim_` for enriched dimensions.
- Use `int_fct_` for row-level metrics.

## Refactored Schema Alignment
The intermediate views have been rebuilt to correctly reference the refactored staging views. Key changes include:

- Updated all dimensional views to use the correct primary and foreign keys
- Fixed join logic between tables to reflect actual relationships
- Standardized naming convention across all views
- Implemented proper filtering of active records using `record_status = 1`
- Added derived fields and metrics based on the correct source data

## Key Dimensions
- `int_dim_date`: Time dimension with calendar and fiscal date attributes
- `int_dim_location`: Location dimension with facility information
- `int_dim_payer`: Payer dimension with carrier/payer categorization
- `int_dim_product`: Product dimension for inventory items
- `int_dim_therapy`: Therapy type dimension

## Key Facts
- `int_fct_referrals`: Patient referrals with source and timing metrics
- `int_fct_new_starts`: New patient starts tracking
- `int_fct_discharges`: Patient discharge events
- `int_fct_drug_revenue`: Drug-related revenue from claims
- `int_fct_expected_revenue`: Expected revenue for forecasting

## Business Entities
- `int_patient_dimension`: Consolidated patient information
- `int_provider_dimension`: Healthcare provider details
- `int_payer_dimension`: Insurance carrier/payer information

## Example
- `int_dim_date.sql`: Enriches raw date data with fiscal period attributes.
- `int_fct_discharges.sql`: Joins and derives metrics related to patient discharges.