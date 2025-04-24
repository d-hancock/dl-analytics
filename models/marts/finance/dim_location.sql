-- Finalized location dimension for marts or presentation layers
-- Provides location-related attributes for reporting and analysis
-- Each row represents a unique location

SELECT 
    location_id, -- Facility or branch identifier
    location_name -- Facility or branch name
FROM int_dim_location;