-- 세그먼트(첫 시즌, 첫 구매 규모) 통제 후 판매자별 재구매율
-- 통제 후 판매자 간 차이가 사라지면 판매자 자체 요인이 아니라 고객군 특성이 원인 (H2 지지)
-- 2025년 첫 구매자는 재구매 기회 없어 분모에서 제외
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
    END) AS first_boxes,
    LOGICAL_OR(o.season > f_p.first_season) AS repurchased
  FROM first_purchase_season AS f_p
  LEFT JOIN gyul.orders AS o
  ON f_p.customer_id = o.customer_id
  WHERE
    f_p.first_season != 2025
  GROUP BY
    f_p.customer_id,
    f_p.first_season
), segmented AS (
  SELECT
    first_season,
    CASE
      WHEN first_boxes = 1 THEN "single"
      WHEN first_boxes >= 2 THEN "multi"
    END AS purchase_size,
    first_seller,
    repurchased
  FROM first_purchase_info
)
SELECT
  first_season,
  purchase_size,
  first_seller,
  COUNT(*) AS customers,
  COUNTIF(repurchased) AS repurchased_cnt,
  ROUND(SAFE_DIVIDE(COUNTIF(repurchased), COUNT(*)) * 100, 1) AS repurchase_rate
FROM segmented
GROUP BY
  first_season,
  purchase_size,
  first_seller
ORDER BY
  first_season,
  purchase_size,
  first_seller

-- 결과 (2022-2024 첫 구매자 1,755명 대상):
--   원본(통제 없음): A 30.2% / B 35.5% / C 24.7%
--   2022 multi     : A 48.1 / B 66.7 / C 45.5  (B > A, 18.6%p 차)
--   2022 single    : A 26.6 / B 38.0 / C 32.0  (B > A, 11.4%p 차)
--   2023 multi     : A 46.9 / B 37.5 / C 0.0   (A > B, 9.4%p 차, C 표본 3명)
--   2023 single    : A 28.5 / B 33.6 / C 20.0  (B > A, 5.1%p 차)
--   2024 multi     : A 53.7 / B 30.8 / C 20.0  (A > B, 22.9%p 차)
--   2024 single    : A 17.1 / B 18.6 / C 10.5  (거의 같음)
-- 관찰: 통제 후에도 판매자 간 차이가 남음. 방향은 세그먼트마다 다르고 2024 코호트에서는 A가 B보다 우세로 뒤집힘
-- 관찰: seller_B의 원본 우세는 2022 코호트 비중이 큰 것과 겹침(11번 참고). 통제 후 남는 판매자 차이는 코호트 시즌·구매 규모에 따라 방향이 갈림
-- 검증: 세그먼트별 판매자 customers 합 = 해당 세그먼트 전체 고객 수. 전체 합 = 1,755(2022-2024 첫 구매자)
