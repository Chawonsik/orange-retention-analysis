-- 고객별 첫 구매 시즌 구하기 (모든 후속 분석의 재료)
SELECT
  customer_id,
  MIN(season) AS first_season
FROM gyul.orders
GROUP BY
  customer_id
