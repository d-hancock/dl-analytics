# Layering Model and Approach

This document outlines the layering model and approach used in the `dl-analytics` project. The structure is designed to ensure clean logic separation, team ownership, and dashboard-readiness.

## Layer Structure

### Staging (`staging/`)
- **Purpose**: Mirror raw sources, clean up column names, and cast types.
- **Conventions**: One-to-one mapping with the source table. No joins or logic.

### Intermediate (`intermediate/`)
- **Purpose**: Apply joins, derive row-level metrics, and enrich logic.
- **Conventions**: Use `int_dim_` for enriched dimensions and `int_fct_` for row-level metrics.

### Marts (`marts/`)
- **Purpose**: Provide finalized facts, aggregated KPIs, and optionally wide marts for reporting.
- **Conventions**:
  - `fct_`: Summable numeric grain, ready for aggregation/slicing.
  - `dim_`: Descriptive categorical data, uniquely keyed.
  - `kpi_`: Pre-aggregated metrics with specific use cases.
  - `mart_`: Denormalized wide reporting tables.

### Presentation (`presentation/`)
- **Purpose**: Materializations for dashboards, tailored for tools like Tableau, Looker, or PowerBI.
- **Conventions**: Use `dashboard_` prefix for final tailored models.

## Benefits
- **Clean Logic Separation**: Ensures each layer has a clear and distinct purpose.
- **Team Ownership**: Allows different teams to own specific marts.
- **Dashboard-Readiness**: Provides tailored views for visualization tools.

## Naming Guidelines
| Prefix       | Use when…                                                                    |
| ------------ | ---------------------------------------------------------------------------- |
| `stg_`       | One-to-one table from source, no joins, no logic.                            |
| `int_`       | Derived logic at row-level, joins, enriching, not yet fully aggregable.      |
| `fct_`       | Summable numeric grain — ready for aggregation/slicing.                      |
| `dim_`       | Descriptive categorical data, uniquely keyed (e.g., patients, providers).    |
| `kpi_`       | Pre-aggregated metrics with specific use cases (e.g., KPI cards).            |
| `mart_`      | Denormalized wide reporting tables — possibly mixed-grain or multi-metric.   |
| `dashboard_` | Final tailored models for BI tooling (e.g., filters hardcoded, PII removed). |