# Staging Layer

## Purpose
The staging layer mirrors raw sources, cleans up column names, and casts types. It provides a one-to-one mapping with the source tables.

## Conventions
- Prefix: `stg_`
- No joins or logic.
- Focus on cleaning and casting raw data.

## Example
- `stg_billing_claim.sql`: Cleans and casts raw billing claim data.
- `stg_date_dimension.sql`: Cleans and casts raw date data.