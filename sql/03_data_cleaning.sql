-- DATA CLEANING
-- Data type fixes, handling nulls, mapping region, duplicate checks
-- Run after staging tables are created

-- ------------------------------------------------------------
-- Events: convert event_date from TIMESTAMP to DATE
-- This is because Time-of-day is not relevant for this analysis
-- ------------------------------------------------------------
UPDATE events
SET event_date = event_date::DATE;

ALTER TABLE events ALTER COLUMN event_date TYPE DATE USING event_date::DATE;

-- ------------------------------------------------------------
-- Events: fix blank region values
-- US and Canada rows had no region label and were mapped to 'NA'
-- ------------------------------------------------------------

-- Check blanks to know which countries have blank region values
SELECT * FROM events WHERE region = '';

-- Confirmed if only US and Canada were affected
SELECT * FROM events WHERE region = '' AND country NOT IN ('United States', 'Canada');

-- Apply fix
UPDATE events
SET region = 'NA'
WHERE country IN ('United States', 'Canada');

-- Confirm
SELECT * FROM events WHERE country IN ('United States', 'Canada');

-- ------------------------------------------------------------
-- Events: fix 'N/A' placeholder in discount_code
-- Replace with NULL so the column can be filtered properly
-- ------------------------------------------------------------
SELECT * FROM events WHERE discount_code = 'N/A';

UPDATE events
SET discount_code = NULL
WHERE discount_code = 'N/A';

-- ------------------------------------------------------------
-- Events: duplicate check
-- Partitioning by event_id - any row_num > 1 is a duplicate
-- ------------------------------------------------------------
WITH dups AS (
    SELECT
        ctid,
        ROW_NUMBER() OVER(PARTITION BY event_id ORDER BY event_id) AS row_num
    FROM events
)
SELECT *
FROM dups
WHERE row_num <> 1;
-- Result: no duplicates found

-- ------------------------------------------------------------
-- Products table: drop unused columns and fix date type
-- ------------------------------------------------------------
ALTER TABLE products ALTER COLUMN first_release_date TYPE DATE USING first_release_date::DATE;
ALTER TABLE products DROP COLUMN product_version;

-- ------------------------------------------------------------
-- Customers table:  drop lat and long coordinates (not used in analysis)
-- Fix date type
-- ------------------------------------------------------------
ALTER TABLE customers DROP COLUMN country_latitude;
ALTER TABLE customers DROP COLUMN country_longitude;
ALTER TABLE customers ALTER COLUMN signup_date TYPE DATE USING signup_date::DATE;

UPDATE customers
SET region = 'NA'
WHERE country IN ('United States', 'Canada'); --fix region where country is US or Canada
