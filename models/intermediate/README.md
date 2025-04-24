# Intermediate Layer

## Purpose
The intermediate layer applies joins, derives row-level metrics, and enriches logic. It bridges the gap between raw staging data and finalized marts.

## Conventions
- Prefix: `int_`
- Use `int_dim_` for enriched dimensions.
- Use `int_fct_` for row-level metrics.

## Example
- `int_dim_date.sql`: Enriches raw date data with fiscal period attributes.
- `int_fct_discharges.sql`: Joins and derives metrics related to patient discharges.