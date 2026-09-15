-- 시즌별 구매자 수, 총 판매 박스 수, 1인당 평균 구매량
WITH season_customers AS (
  SELECT
    season,
    COUNT(DISTINCT customer_id) AS season_buyer,
    SUM(qty_10kg + qty_5kg) AS total_boxes
  FROM gyul.orders
  GROUP BY
    season
)
SELECT
  *,
  ROUND(SAFE_DIVIDE(total_boxes, season_buyer), 2) AS boxes_per_buyer
FROM season_customers

-- 결과: 1인당 평균 구매량이 4개 시즌 내내 1.4~1.5로 거의 고정
-- 이 사업의 매출은 물량(1인당 구매량)이 아니라 고객 머릿수가 결정한다 -> 리텐션 분석이 핵심인 이유
