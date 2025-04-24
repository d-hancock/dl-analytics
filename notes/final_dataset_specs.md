Here’s the shape of the **final presentational dataset** your Tableau dashboard needs, driven by the KPIs you just loaded. It’s **one row per combination** of the key dimensions (e.g. date × location × product/therapy × payer), with each KPI as its own column:

| Column Name                | Type    | From / Calculation                                                                                   | Notes / Purpose              |
| -------------------------- | ------- | ---------------------------------------------------------------------------------------------------- | ---------------------------- |
| **Date & Period**          |         |                                                                                                      |                              |
| `calendar_date`            | DATE    | from `stg_date.calendar_date`                                                                        | Day‐level date               |
| `fiscal_period_key`        | VARCHAR | from `int_dim_date.fiscal_period_key`                                                                | Surrogate for fiscal period  |
| `period_start_date`        | DATE    | from `int_dim_date.period_start_date`                                                                |                              |
| `period_end_date`          | DATE    | from `int_dim_date.period_end_date`                                                                  |                              |
| **Location**               |         |                                                                                                      |                              |
| `location_id`              | VARCHAR | from `stg_party` / maybe via `stg_patient` or separate location view                                 | Facility or branch           |
| `location_name`            | VARCHAR | joined lookup                                                                                        |                              |
| **Product / Therapy**      |         |                                                                                                      |                              |
| `product_id`               | VARCHAR | from `stg_inventory_item.item_sku`                                                                   | Drug or supply item          |
| `product_name`             | VARCHAR | from `stg_inventory_item`                                                                            |                              |
| **Payer**                  |         |                                                                                                      |                              |
| `payer_id`                 | VARCHAR | from `stg_patient_policy.insurance_program_id` → `int_dim_payer`                                     |                              |
| `payer_name`               | VARCHAR | lookup                                                                                               |                              |
| **Therapy Type**           |         |                                                                                                      |                              |
| `therapy_code`             | VARCHAR | from a therapy lookup (e.g. HcPc)                                                                    |                              |
| `therapy_name`             | VARCHAR | lookup                                                                                               |                              |
| **KPI Metrics**            |         |                                                                                                      |                              |
| `discharged_patients`      | INTEGER | COUNT( DISTINCT patient_id WHERE discharge_date BETWEEN period_start_date AND period_end_date)       | “Discharged Patients” KPI    |
| `new_starts`               | INTEGER | COUNT( DISTINCT patient_id WHERE status = ‘Active’ AND first_visit_date BETWEEN period_start_date …) | “New Starts” KPI             |
| `referrals`                | INTEGER | COUNT( referral_id WHERE referral_status = ‘pending’ AND referral_date BETWEEN period_start_date …)  | “Referrals” KPI              |
| `expected_revenue_per_day` | DECIMAL | SUM(contracted_revenue) / COUNT(DISTINCT calendar_date)                                              | “Expected Revenue / Day” KPI |
| `drug_revenue`             | DECIMAL | SUM(quantity \* unit_price) - SUM(discount_amt) + SUM(tax_amt)                                       | “Drug Revenue” KPI           |

**Why this shape?**

- **One row per dimensional slice** lets Tableau pivot, filter, and drill down across any combination of Date × Location × Product × Payer × Therapy, without additional data blending.
- **Each KPI as its own column** makes it trivial to build individual worksheets and combined scorecards.
- **Surrogate period keys** (fiscal, calendar) support time‐series calculations (MoM, QoQ) via LODs or table calcs.

From here, you’d work **backwards** to define the intermediate views that populate each of these columns—e.g.:

- **`int_dim_date`** for all date fields & period keys
- **`int_dim_location`** / **`int_dim_product`** / **`int_dim_payer`** for lookup attributes
- **`int_fct_discharges`**, **`int_fct_new_starts`**, **`int_fct_referrals`**, **`int_fct_expected_revenue`**, **`int_fct_drug_revenue`** for each KPI’s raw aggregation

That fully modular structure makes your final view both performant and flexible for any future KPIs.
