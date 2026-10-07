-- 02_join.sql
-- Question: which borough files the most requests once you account for population?

CREATE OR REPLACE TABLE nyc311.requests_per_capita AS
SELECT
  r.borough,
  p.county,
  p.population,
  COUNT(*)                                                      AS requests,
  ROUND(1000 * COUNT(*) / p.population, 1)                      AS requests_per_1000_residents,
  ROUND(APPROX_QUANTILES(r.hours_to_close, 100)[OFFSET(50)], 1) AS median_hours_to_close
FROM nyc311.requests_clean AS r
INNER JOIN nyc311.borough_population AS p
  ON r.borough = p.borough
GROUP BY r.borough, p.county, p.population;


SELECT *
FROM nyc311.requests_per_capita
ORDER BY requests_per_1000_residents DESC;


-- Check the join did not drop or duplicate rows: these two numbers must match.
SELECT
  (SELECT COUNT(*)      FROM nyc311.requests_clean)      AS rows_before_join,
  (SELECT SUM(requests) FROM nyc311.requests_per_capita) AS rows_after_join;
