-- Intermediate Location Dimension
-- Enriches raw location data with additional attributes for reporting
-- Each row represents a unique location

SELECT 
    location_id, -- Facility or branch identifier
    location_name -- Facility or branch name
FROM stg_facility_dimension;