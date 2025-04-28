-- =================================================================================
-- Intermediate Layer: Expected Revenue
-- Name: int_expected_revenue
-- Source Tables: 
--   • stg.invoice
--   • stg.invoice_item
--   • stg.invoice_aggregate
-- Purpose: 
--   Provides a consolidated view of expected revenue data by joining invoice header,
--   line items, and financial aggregates. This model serves as the source of truth
--   for expected revenue analysis across the organization.
-- Key Transformations:
--   • Joins invoice headers with line items and aggregates
--   • Preserves granular revenue data at line item level
--   • Includes contextual fields for multi-dimensional analysis
-- Usage:
--   • Source for revenue fact tables and KPIs
--   • Enables time-based, service-based, and entity-based revenue analysis
--   • Powers expected revenue dashboards and financial reporting
-- =================================================================================

WITH invoice_with_aggregates AS (
    -- Join invoice header with pre-calculated aggregates
    SELECT
        inv.invoice_id,
        inv.invoice_number,
        inv.patient_id,
        inv.billing_provider_id,
        inv.company_id,
        inv.carrier_id,
        inv.claim_type_id,
        inv.therapy_id,
        inv.service_from_date,
        inv.service_to_date,
        inv.is_point_of_sale,
        inv.is_revenue,
        inv.closed_date,
        inv.accounting_period_id,
        -- Aggregate fields (if available)
        agg.total_billed_price,
        agg.total_expected_price,
        agg.expected_price        AS invoice_expected_price,
        agg.expected_tax          AS invoice_expected_tax,
        agg.total_paid,
        agg.total_adjusted,
        agg.balance
    FROM 
        DEV_DB.stg.invoice inv
    LEFT JOIN 
        DEV_DB.stg.invoice_aggregate agg
        ON inv.invoice_id = agg.invoice_agg_id
)

SELECT
    -- Invoice header information
    inv.invoice_id,
    inv.invoice_number,
    inv.patient_id,
    inv.billing_provider_id,
    inv.company_id,
    inv.carrier_id,
    inv.claim_type_id,
    inv.therapy_id,
    inv.service_from_date,
    inv.service_to_date,
    inv.is_revenue,
    inv.is_point_of_sale,
    inv.closed_date,
    inv.accounting_period_id,
    
    -- Invoice item details
    item.invoice_item_id,
    item.inventory_item_id,
    item.inventory_item_type_id,
    item.item_name,
    item.quantity,
    
    -- Line item financial fields
    item.billed_price,
    item.expected_price,
    item.billed_tax,
    item.expected_tax,
    item.total_billed_price    AS item_total_billed_price,
    item.total_expected_price  AS item_total_expected_price,
    
    -- Invoice level financials
    inv.total_billed_price     AS invoice_total_billed_price,
    inv.total_expected_price   AS invoice_total_expected_price,
    inv.invoice_expected_price,
    inv.invoice_expected_tax,
    inv.total_paid,
    inv.total_adjusted,
    inv.balance,
    
    -- Derived fields
    CASE 
        WHEN inv.closed_date IS NULL THEN 'Open'
        ELSE 'Closed'
    END AS invoice_status,
    
    -- Date dimensions for time-based analysis
    EXTRACT(YEAR FROM inv.service_from_date) AS service_year,
    EXTRACT(MONTH FROM inv.service_from_date) AS service_month,
    DATE_TRUNC('month', inv.service_from_date) AS service_month_start,
    
    -- Calculate revenue gap (expected vs actual)
    CASE
        WHEN inv.total_expected_price IS NULL OR inv.total_paid IS NULL THEN NULL
        ELSE inv.total_expected_price - inv.total_paid 
    END AS revenue_gap
    
FROM 
    invoice_with_aggregates inv
LEFT JOIN 
    DEV_DB.stg.invoice_item item
    ON inv.invoice_id = item.invoice_id
WHERE 
    inv.is_revenue = 1  -- Only include revenue-generating invoices
;