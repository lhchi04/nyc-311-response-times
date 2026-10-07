-- 00_setup.sql
-- Source: bigquery-public-data.new_york_311.311_service_requests

-- STEP A. Check which dates the public table covers.
SELECT
  MIN(created_date) AS earliest_request,
  MAX(created_date) AS latest_request,
  COUNT(*)          AS total_rows
FROM `bigquery-public-data.new_york_311.311_service_requests`;


-- STEP B. Create dataset to hold the project tables.
CREATE SCHEMA IF NOT EXISTS nyc311 OPTIONS (location = 'US');


-- STEP C. Copy one year of requests, keeping only the columns the project needs.
-- This is the RAW table: nothing is cleaned or filtered out yet except the year.
CREATE OR REPLACE TABLE nyc311.requests_raw AS
SELECT
  unique_key,
  created_date,
  closed_date,
  agency,
  complaint_type,
  borough,
  incident_zip,
  status
FROM `bigquery-public-data.new_york_311.311_service_requests`
WHERE created_date >= TIMESTAMP('2020-01-01')
  AND created_date <  TIMESTAMP('2021-01-01');


-- STEP D. A small lookup table to join against (2020 Census counts).
CREATE OR REPLACE TABLE nyc311.borough_population AS
SELECT 'BRONX'         AS borough, 'Bronx County'    AS county, 1472654 AS population UNION ALL
SELECT 'BROOKLYN',                 'Kings County',              2736074 UNION ALL
SELECT 'MANHATTAN',                'New York County',           1694251 UNION ALL
SELECT 'QUEENS',                   'Queens County',             2405464 UNION ALL
SELECT 'STATEN ISLAND',            'Richmond County',            495747;


-- STEP E. A view holding the cleaning rules, so every later query applies them the same way.
-- Rules (the notebook counts how many rows each rule affects):
--   1. keep only the five real boroughs (drops NULL and 'Unspecified')
--   2. standardise complaint_type spelling (trim spaces, consistent capitalisation)
--   3. hours_to_close is NULL when the request is still open
--      or when closed_date is earlier than created_date (a data error)
CREATE OR REPLACE VIEW nyc311.requests_clean AS
SELECT
  unique_key,
  created_date,
  closed_date,
  agency,
  INITCAP(TRIM(REGEXP_REPLACE(complaint_type, r'\s+', ' '))) AS complaint_type,
  UPPER(TRIM(borough)) AS borough,
  incident_zip,
  status,
  CASE
    WHEN closed_date IS NULL          THEN NULL
    WHEN closed_date < created_date   THEN NULL
    ELSE TIMESTAMP_DIFF(closed_date, created_date, MINUTE) / 60.0
  END AS hours_to_close
FROM nyc311.requests_raw
WHERE UPPER(TRIM(borough)) IN ('BRONX', 'BROOKLYN', 'MANHATTAN', 'QUEENS', 'STATEN ISLAND');
