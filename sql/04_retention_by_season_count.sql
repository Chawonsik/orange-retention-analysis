-- 누적 구매 시즌 수별 다음 시즌 재구매율
-- 이미 2시즌 이상 구매한 고객의 다음 시즌 재구매율이 신규 고객보다 높다면 가설 지지
-- 2025는 다음 시즌 관측 불가라 대상에서 제외 (2022, 2023, 2024 시즌 기준 다음 시즌 재구매 확인)
WITH customer_seasons AS (
  SELECT DISTINCT
    customer_id,
    season
  FROM gyul.orders
), cumulative AS (
  SELECT
    customer_id,
    season,
    COUNT(*) OVER (PARTITION BY customer_id ORDER BY season) AS cum_seasons
  FROM customer_seasons
), next_season_flag AS (
  SELECT
    c.customer_id,
    c.season,
    c.cum_seasons,
    MAX(CASE
      WHEN o.season = c.season + 1 THEN 1
      ELSE 0
    END) AS next_repurchased
  FROM cumulative AS c
  LEFT JOIN gyul.orders AS o
  ON c.customer_id = o.customer_id
  WHERE
    c.season != 2025
  GROUP BY
    c.customer_id,
    c.season,
    c.cum_seasons
)
SELECT
  cum_seasons,
  COUNT(*) AS observations,
  SUM(next_repurchased) AS repurchased_cnt,
  ROUND(SAFE_DIVIDE(SUM(next_repurchased), COUNT(*)) * 100, 1) AS next_season_retention_rate
FROM next_season_flag
GROUP BY
  cum_seasons
ORDER BY
  cum_seasons

-- 결과 (2022-2024 시즌에 구매한 (customer, season) 조합 2,315건):
--   cum=1(신규 1회) : 1,755건 중 418건 재구매 → 23.8%
--   cum=2         :   400건 중 252건 재구매 → 63.0%
--   cum=3         :   160건 중 126건 재구매 → 78.8%
-- 관찰: 누적 구매 시즌이 늘어날수록 다음 시즌 재구매율이 계단식으로 상승. 신규 대비 2시즌 구매자는 약 2.6배, 3시즌 구매자는 약 3.3배
-- 검증: 각 cum_seasons 값별 observations 합 1755+400+160 = 2,315 = 2022-2024 시즌에 구매한 (customer, season) 조합 수
