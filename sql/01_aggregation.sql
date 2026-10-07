-- 01_aggregation.sql
-- Question: which complaint types take longest to close, and does it differ by borough?

CREATE OR REPLACE TABLE nyc311.response_by_type_borough AS
SELECT
  complaint_type,
  borough,
  COUNT(*)                                                    AS requests,
  COUNTIF(hours_to_close IS NOT NULL)                         AS closed_requests,
  ROUND(APPROX_QUANTILES(hours_to_close, 100)[OFFSET(50)], 1) AS median_hours_to_close,
  ROUND(AVG(hours_to_close), 1)                               AS mean_hours_to_close,
  ROUND(100 * COUNTIF(hours_to_close <= 24) / COUNT(*), 1)    AS pct_closed_within_24h
FROM nyc311.requests_clean
GROUP BY complaint_type, borough
HAVING COUNT(*) >= 500;   -- skip tiny groups whose medians are not reliable


-- Slowest complaint types first.
SELECT *
FROM nyc311.response_by_type_borough
ORDER BY median_hours_to_close DESC
LIMIT 25;
