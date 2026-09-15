-- 첫 구매 시즌(코호트)별로, 이후 시즌마다 몇 %가 재구매했는지 삼각형 리텐션 표
-- 리텐션 정의: 코호트 C의 시즌 S 리텐션 = (첫 구매 시즌이 C인 고객 중 시즌 S에도 구매한 수) / (첫 구매 시즌이 C인 고객 수)
WITH first_purchase_season AS (
  SELECT
    MIN(season) AS first_season,
    customer_id
  FROM gyul.orders
  GROUP BY
    customer_id
), cohort_by_season AS (
  SELECT
    f_s.first_season,
    o.season,
    COUNT(DISTINCT o.customer_id) AS customers
  FROM first_purchase_season AS f_s
  LEFT JOIN gyul.orders AS o
  ON f_s.customer_id = o.customer_id
  GROUP BY
    f_s.first_season,
    o.season
), cohort_n AS (
  SELECT
    *,
    FIRST_VALUE(customers) OVER (PARTITION BY first_season ORDER BY season) AS cohort_customer
  FROM cohort_by_season
), retention AS (
  SELECT
    *,
    ROUND(SAFE_DIVIDE(customers, cohort_customer) * 100, 1) AS retention
  FROM cohort_n
)
SELECT
  first_season,
  MAX(IF(season = first_season, customers, NULL)) AS cohort_n,
  MAX(IF(season = 2023, retention, NULL)) AS r2023,
  MAX(IF(season = 2024, retention, NULL)) AS r2024,
  MAX(IF(season = 2025, retention, NULL)) AS r2025
FROM retention
GROUP BY
  first_season
ORDER BY
  first_season

-- 결과: 2022 코호트(904명) 2023(흉) 24.1% -> 2024(풍) 27.8% -> 2025(흉) 23.1%
-- 리텐션이 시간이 갈수록 단조 감소하는 게 아니라, 측정 시즌 자체의 흉작/풍작을 그대로 따라감
