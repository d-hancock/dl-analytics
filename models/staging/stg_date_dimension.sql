-- Staging Table: Date Dimension
-- Cleans and casts raw date data for downstream use
-- One-to-one mapping with the source table

SELECT 
    calendar_date, -- Day-level date
    day_of_week, -- Day of the week
    month, -- Month of the year
    year -- Year
FROM raw_date_dimension;