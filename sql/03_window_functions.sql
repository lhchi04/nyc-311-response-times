-- 03_window_functions.sql
-- Question: what are the top complaint types in each borough, and how does volume change month to month?

-- PART 1. Top 10 complaint types inside each borough.
-- RANK() restarts at 1 for every borough because of PARTITION BY.
-- SUM() OVER gives each borough's total without collapsing the rows.
CREATE OR REPLACE TABLE nyc311.top_types_by_borough AS
WITH counts AS (
  SELECT
    borough,
    complaint_type,
    COUNT(*) AS requests
  FROM nyc311.requests_clean
  GROUP BY borough, complaint_type
),
ranked AS (
  SELECT
    borough,
    complaint_type,
    requests,
    RANK() OVER (PARTITION BY borough ORDER BY requests DESC)        AS rank_in_borough,
    ROUND(100 * requests / SUM(requests) OVER (PARTITION BY borough), 1) AS pct_of_borough_requests
  FROM counts
)
SELECT *
FROM ranked
WHERE rank_in_borough <= 10;


SELECT *
FROM nyc311.top_types_by_borough
ORDER BY borough, rank_in_borough;


-- PART 2. Month-over-month change in request volume for each borough.
-- LAG() reads the previous month's value from the row above, within the same borough.
CREATE OR REPLACE TABLE nyc311.monthly_trend AS
WITH monthly AS (
  SELECT
    borough,
    DATE_TRUNC(DATE(created_date), MONTH)                       AS month,
    COUNT(*)                                                    AS requests,
    ROUND(APPROX_QUANTILES(hours_to_close, 100)[OFFSET(50)], 1) AS median_hours_to_close
  FROM nyc311.requests_clean
  GROUP BY borough, month
)
SELECT
  borough,
  month,
  requests,
  median_hours_to_close,
  LAG(requests) OVER w AS requests_previous_month,
  ROUND(100 * SAFE_DIVIDE(requests - LAG(requests) OVER w, LAG(requests) OVER w), 1) AS pct_change_vs_previous_month
FROM monthly
WINDOW w AS (PARTITION BY borough ORDER BY month);


SELECT *
FROM nyc311.monthly_trend
ORDER BY borough, month;
