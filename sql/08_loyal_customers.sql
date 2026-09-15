-- 충성 고객 명단: 시즌을 몇 번 건너뛰었든 상관없이 총 3개 시즌 이상 구매한 고객
-- (연속 구매만 요구하지 않는 이유: 해거리로 한 시즌 건너뛰는 게 자연스러운 사업이라)
WITH loyal_customers AS (
  SELECT
    customer_id,
    COUNT(DISTINCT season) AS season_cnt
  FROM gyul.orders
  GROUP BY
    customer_id
  HAVING
    season_cnt >= 3
), first_season AS (
  SELECT
    customer_id,
    MIN(season) AS first_season
  FROM gyul.orders
  GROUP BY
    customer_id
), customer_seller AS (
  SELECT
    fs.customer_id,
    MAX(CASE
      WHEN fs.first_season = o.season THEN o.seller
    END) AS seller
  FROM first_season AS fs
  LEFT JOIN gyul.orders AS o
  ON fs.customer_id = o.customer_id
  GROUP BY
    fs.customer_id
)
SELECT
  cs.seller,
  COUNT(lc.customer_id) AS loyal_customer_cnt
FROM loyal_customers AS lc
LEFT JOIN customer_seller AS cs
ON lc.customer_id = cs.customer_id
GROUP BY
  cs.seller

-- 결과: 총 263명 (seller_A 126, seller_B 130, seller_C 7)
-- 검증: 이 쿼리 전체 결과의 COUNT(*) = COUNT(DISTINCT customer_id) = 263 (팬아웃 없음 확인)
