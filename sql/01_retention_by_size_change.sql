-- 첫 시즌 단일 구매(1박스)로 시작한 고객의 두 번째 구매 시즌 수량 변화
-- 두 그룹(keep_single, expand_to_multi) 각각의 이후 재구매율 비교
-- 첫 시즌이 2024/2025인 고객은 이후 관측 시즌이 부족해 제외
WITH first_purchase_season AS (
  SELECT
    customer_id,
    MIN(season) AS first_season
  FROM gyul.orders
  GROUP BY
    customer_id
), first_season_boxes AS (
  SELECT
    f_p.customer_id,
    f_p.first_season,
    SUM(o.qty_10kg + o.qty_5kg) AS first_boxes
  FROM first_purchase_season AS f_p
  LEFT JOIN gyul.orders AS o
  ON f_p.customer_id = o.customer_id
    AND o.season = f_p.first_season
  GROUP BY
    f_p.customer_id,
    f_p.first_season
), single_start_customers AS (
  SELECT
    customer_id,
    first_season
  FROM first_season_boxes
  WHERE
    first_boxes = 1
    AND first_season IN (2022, 2023)
), second_purchase_season AS (
  SELECT
    s_c.customer_id,
    s_c.first_season,
    MIN(o.season) AS second_season
  FROM single_start_customers AS s_c
  LEFT JOIN gyul.orders AS o
  ON s_c.customer_id = o.customer_id
    AND o.season > s_c.first_season
  GROUP BY
    s_c.customer_id,
    s_c.first_season
), second_season_boxes AS (
  SELECT
    s_p.customer_id,
    s_p.first_season,
    s_p.second_season,
    SUM(o.qty_10kg + o.qty_5kg) AS second_boxes
  FROM second_purchase_season AS s_p
  LEFT JOIN gyul.orders AS o
  ON s_p.customer_id = o.customer_id
    AND o.season = s_p.second_season
  WHERE
    s_p.second_season IS NOT NULL
  GROUP BY
    s_p.customer_id,
    s_p.first_season,
    s_p.second_season
), quantity_change_group AS (
  SELECT
    customer_id,
    first_season,
    second_season,
    CASE
      WHEN second_boxes = 1 THEN "keep_single"
      WHEN second_boxes >= 2 THEN "expand_to_multi"
    END AS change_group
  FROM second_season_boxes
), later_retention AS (
  SELECT
    q_c.customer_id,
    q_c.change_group,
    MAX(CASE
      WHEN o.season > q_c.second_season THEN 1
      ELSE 0
    END) AS retained_later
  FROM quantity_change_group AS q_c
  LEFT JOIN gyul.orders AS o
  ON q_c.customer_id = o.customer_id
  GROUP BY
    q_c.customer_id,
    q_c.change_group
)
SELECT
  change_group,
  COUNT(*) AS customers,
  SUM(retained_later) AS retained_later_cnt,
  ROUND(SAFE_DIVIDE(SUM(retained_later), COUNT(*)) * 100, 1) AS later_retention_rate
FROM later_retention
GROUP BY
  change_group
ORDER BY
  change_group

-- 결과: keep_single 247명(이후 재구매 53.0%), expand_to_multi 54명(이후 재구매 59.3%)
-- 검증: keep_single 247 + expand_to_multi 54 = 301 = 2022/2023 코호트 중 1박스 시작 후 재구매한 고객 수 (모집단 971명 중 31%)
