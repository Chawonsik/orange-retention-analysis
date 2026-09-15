-- 시즌별 구매자를 신규(new)/유지(retained)/복귀(resurrected)로 분해 (growth accounting)
-- new: 그 시즌이 첫 구매 시즌
-- retained: 직전 시즌에도 구매함 (season - prev_season = 1)
-- resurrected: 이전에 구매한 적 있지만 직전 시즌은 건너뜀
WITH first_purchase_season AS (
  SELECT
    MIN(season) AS first_season,
    customer_id
  FROM gyul.orders
  GROUP BY
    customer_id
), prev_season_table AS (
  SELECT
    customer_id,
    season,
    LAG(season, 1) OVER (PARTITION BY customer_id ORDER BY season) AS prev_season
  FROM gyul.orders
  GROUP BY
    season,
    customer_id
)
SELECT
  p_t.season,
  CASE
    WHEN p_t.season = f_p.first_season THEN "new_buyer"
    WHEN (p_t.season - 1) = p_t.prev_season THEN "retain_buyer"
    WHEN (p_t.season - 1) != p_t.prev_season THEN "resurrect_buyer"
    ELSE "unclassified"
  END AS customer_segment,
  COUNT(*) AS customer_cnt
FROM prev_season_table AS p_t
LEFT JOIN first_purchase_season AS f_p
ON p_t.customer_id = f_p.customer_id
GROUP BY
  p_t.season,
  customer_segment
ORDER BY
  p_t.season,
  customer_segment

-- 결과: 2023년은 데이터 시작 시즌이라 구조적으로 resurrect_buyer가 0 (관측 불가, 실제로 없는 게 아님)
-- 2024(풍년) 복귀 비중 10.9% vs 2025(흉년) 8.5% -- 해거리 가설과 방향 일치 (표본 2개 시즌뿐이라 약한 증거)
-- 검증: 모든 시즌의 new_buyer 합 = 전체 고객 수 (2,117). 각 고객은 평생 한 번만 new가 되므로 성립해야 함
