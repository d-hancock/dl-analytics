## ✅ Your Structure (Annotated)

```
models/
├── staging/                      # Raw table cleanup (1-to-1 source mapping)
│   └── stg_*.sql                 # Good naming: clean + cast only, no joins
│
├── intermediate/                # Row-level business logic & joins
│   └── int_dim_*.sql            # Derive attributes or enrich dimensions
│   └── int_fct_*.sql            # Join stg tables & derive metrics
│
├── marts/                       # Functional output marts per department
│   ├── finance/
│   │   └── fct_*.sql            # Summable grain-level facts (daily, monthly, etc.)
│   │   └── mart_*.sql           # Optional wide models for reporting
│   │   └── kpi_*.sql            # Metric- and dashboard-ready models
│   └── sales/
│       └── ...
│
├── presentation/                # Final models feeding dashboards/tools
│   └── dashboard_*.sql          # Possibly combines fct_ & dim_ for one viz
```

---

## 💡 Layer Role Clarifications

| Layer            | Purpose                                                                                                                                       |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `staging/`       | Mirror raw sources, clean up column names, cast types.                                                                                        |
| `intermediate/`  | Apply joins, derive row-level metrics, enrich logic.                                                                                          |
| `marts/finance/` | Finalized facts (`fct_`), aggregated KPIs (`kpi_`), and optionally wide marts (`mart_`).                                                      |
| `presentation/`  | Materializations for dashboards (e.g. tailored for Tableau, Looker, PowerBI) — often filtered, labeled, or structured for direct consumption. |

---

## 📛 Naming Guidelines (Suggestion)

| Prefix       | Use when…                                                                    |
| ------------ | ---------------------------------------------------------------------------- |
| `stg_`       | One-to-one table from source, no joins, no logic.                            |
| `int_`       | Derived logic at row-level, joins, enriching, not yet fully aggregable.      |
| `fct_`       | Summable numeric grain — ready for aggregation/slicing.                      |
| `dim_`       | Descriptive categorical data, uniquely keyed (e.g., patients, providers).    |
| `kpi_`       | Pre-aggregated metrics with specific use cases (e.g., KPI cards).            |
| `mart_`      | Denormalized wide reporting tables — possibly mixed-grain or multi-metric.   |
| `dashboard_` | Final tailored models for BI tooling (e.g., filters hardcoded, PII removed). |

---

## 🧠 A Few Refinement Suggestions

1. **Use `fct_` and `dim_` prefixes inside `marts/finance/` and other domain folders.**  
   This helps clarify structure, especially if other teams reuse these.

2. **Stick with `kpi_` in `marts/` if you're delivering business metric datasets** rather than final dashboard tables — they should be reusable and grain-specific.

3. **Keep `presentation/` for dashboard-specific views**, especially if those dashboards require:

   - Hardcoded filters (e.g. only 90-day lookbacks)
   - Label formatting
   - Reshaped tables for visualization tooling (like one-row-per-metric-type for bar charts)

4. **Add `dim_` models in `intermediate/` or `marts/` if you need clean dimensions.**  
   e.g., `int_dim_payer.sql` is fine in `intermediate/`, but once it's final, consider also placing a `dim_payer.sql` in `marts/finance/` if finance owns that context.

---

- Clear team ownership (`marts/finance`, `marts/sales`)
- Clean logic separation (`staging` → `intermediate` → `marts`)
- Dashboard-readiness (`presentation`)

Generate a `README.md` structure for each subfolder to clarify intent and usage, and create a sample view docstring template to enforce this structure as you go?
