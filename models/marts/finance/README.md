# Finance Marts Layer

## Purpose
The finance marts layer provides finalized facts, aggregated KPIs, and optionally wide marts for reporting. It is tailored for the finance department's needs.

## Conventions
- Prefix: `fct_` for summable numeric grain.
- Prefix: `dim_` for descriptive categorical data.
- Prefix: `kpi_` for pre-aggregated metrics.
- Prefix: `mart_` for denormalized wide reporting tables.

## Example
- `fct_discharges.sql`: Summable grain-level fact table for discharges.
- `kpi_drug_revenue.sql`: Pre-aggregated metric for drug revenue.