-- 판매자(채널)별 재구매율: 첫 구매 이후 어느 시즌이든 한 번이라도 다시 구매했는가
-- 2025년 첫 구매자는 재구매할 기회 자체가 없으므로 분모에서 제외 (censoring)
WITH first_purchase_season AS (
  SELECT
    MIN(season) AS first_season,
    customer_id
  FROM gyul.orders
  GROUP BY
    customer_id
), repurchase_cnt AS (
  SELECT
    seller_type,
    repurchase,
    COUNT(repurchase) AS repur_t_f
  FROM (
    SELECT
      f_p.customer_id,
      MAX(CASE
        WHEN f_p.first_season = o.season THEN o.seller
      END) AS seller_type,
      LOGICAL_OR(f_p.first_season < o.season) AS repurchase
    FROM first_purchase_season AS f_p
    LEFT JOIN gyul.orders AS o
    ON f_p.customer_id = o.customer_id
    WHERE
      f_p.first_season != 2025
    GROUP BY
      f_p.customer_id
  )
  GROUP BY
    seller_type,
    repurchase
)
SELECT
  seller_type,
  repurchase,
  repur_t_f,
  ROUND(SAFE_DIVIDE(repur_t_f, repur_sum) * 100, 2) AS repurchase_rate
FROM (
  SELECT
    *,
    SUM(repur_t_f) OVER (PARTITION BY seller_type) AS repur_sum
  FROM repurchase_cnt
)
WHERE
  repurchase = TRUE
ORDER BY
  seller_type

-- 결과: seller_A 29.7%, seller_B 36.1%, seller_C 25.6%
