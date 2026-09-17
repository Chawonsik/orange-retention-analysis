-- 판매자별 첫 구매 고객 프로필 (첫 시즌, 첫 구매 규모 분포)
-- 판매자마다 확보한 고객군이 어떻게 다른지 확인 (H2 검증의 기술 통계 재료)
WITH first_purchase_season AS (
  SELECT
    customer_id,
    MIN(season) AS first_season
  FROM gyul.orders
  GROUP BY
    customer_id
), first_purchase_info AS (
  SELECT
    f_p.customer_id,
    f_p.first_season,
    MAX(CASE
      WHEN o.season = f_p.first_season THEN o.seller
    END) AS first_seller,
    SUM(CASE
      WHEN o.season = f_p.first_season THEN o.qty_10kg + o.qty_5kg
      ELSE 0
    END) AS first_boxes
  FROM first_purchase_season AS f_p
  LEFT JOIN gyul.orders AS o
  ON f_p.customer_id = o.customer_id
  GROUP BY
    f_p.customer_id,
    f_p.first_season
), profile AS (
  SELECT
    first_seller,
    first_season,
    CASE
      WHEN first_boxes = 1 THEN "single"
      WHEN first_boxes >= 2 THEN "multi"
    END AS purchase_size,
    COUNT(*) AS customers
  FROM first_purchase_info
  GROUP BY
    first_seller,
    first_season,
    purchase_size
)
SELECT
  first_seller,
  first_season,
  purchase_size,
  customers,
  ROUND(SAFE_DIVIDE(customers, SUM(customers) OVER (PARTITION BY first_seller)) * 100, 1) AS pct_within_seller
FROM profile
ORDER BY
  first_seller,
  first_season,
  purchase_size

-- 결과: 판매자별 규모 A 1,284 / B 758 / C 75(표본 작음)
--       multi(2박스+) 비율 A 21.8% / B 16.9% / C 25.3%
--       2022 코호트 비중 A 41.4% / B 44.3% / C 48.0%
--       2025 코호트 비중 A 21.8% / B 10.7% / C 2.7%
--       seller_B는 신규 유입이 최근으로 갈수록 감소, 세 판매자 중 multi 비율은 가장 낮음
-- 검증: 각 first_seller의 pct_within_seller 합 = 100%. 전체 customers 합 = 2,117
