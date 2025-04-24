-- Finalized date dimension for marts or presentation layers
-- Provides date-related attributes for reporting and analysis
-- Each row represents a unique calendar date

SELECT 
    calendar_date, -- Day-level date
    fiscal_period_key, -- Surrogate for fiscal period
    period_start_date, -- Start date of the fiscal period
    period_end_date -- End date of the fiscal period
FROM int_dim_date;