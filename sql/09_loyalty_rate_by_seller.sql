-- 판매자별 충성 고객 "전환율" (08번은 인원수만, 이건 후보군 대비 비율)
-- 후보군: 3시즌을 채울 기회가 있으려면 첫 구매가 2022년 또는 2023년이어야 함
-- (2024/2025년 첫 구매자는 남은 시즌이 2개/1개뿐이라 애초에 3시즌을 채울 수 없음 -> 분모에서 제외)
WITH first_season AS (
  SELECT
    customer_id,
    MIN(season) AS first_season
  FROM gyul.orders
  GROUP BY
    customer_id
), customer_seller AS (
  SELECT
    fs.customer_id,
    fs.first_season,
    MAX(CASE
      WHEN fs.first_season = o.season THEN o.seller
    END) AS seller
  FROM first_season AS fs
  LEFT JOIN gyul.orders AS o
  ON fs.customer_id = o.customer_id
  GROUP BY
    fs.customer_id,
    fs.first_season
), loyal_customers AS (
  SELECT
    customer_id,
    COUNT(DISTINCT season) AS season_cnt
  FROM gyul.orders
  GROUP BY
    customer_id
  HAVING
    season_cnt >= 3
), candidate_seller AS (
  SELECT
    seller,
    COUNT(*) AS candidate_cnt
  FROM customer_seller
  WHERE
    first_season IN (2022, 2023)
  GROUP BY
    seller
), loyal_seller AS (
  SELECT
    cs.seller,
    COUNT(lc.customer_id) AS loyal_cnt
  FROM loyal_customers AS lc
  LEFT JOIN customer_seller AS cs
  ON lc.customer_id = cs.customer_id
  GROUP BY
    cs.seller
)
SELECT
  cp.seller,
  cp.candidate_cnt,
  ls.loyal_cnt,
  ROUND(SAFE_DIVIDE(ls.loyal_cnt, cp.candidate_cnt) * 100, 2) AS loyalty_rate
FROM candidate_seller AS cp
LEFT JOIN loyal_seller AS ls
ON cp.seller = ls.seller
ORDER BY
  loyalty_rate DESC

-- 결과: seller_B 26.26%(495명 중 130명), seller_A 17.55%(718명 중 126명), seller_C 14.29%(49명 중 7명)
-- 검증: candidate_cnt 합(495+718+49=1,262) = 2022/2023년 신규 고객 수 합(904+358)과 일치
