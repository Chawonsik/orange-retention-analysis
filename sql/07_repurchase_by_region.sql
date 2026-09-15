-- 시도(지역)별 재구매율. 05번의 판매자 축을 지역 축으로 반복
-- 주소는 배송지일 뿐 실거주지가 아닐 수 있어 해석에 한계가 있음(선물 발송 가능성)
WITH first_season AS (
  SELECT
    customer_id,
    MIN(season) AS first_season
  FROM gyul.orders
  GROUP BY
    customer_id
  HAVING
    MIN(season) != 2025
), first_season_sido AS (
  SELECT
    fs.customer_id,
    ANY_VALUE(o.sido) AS sido
  FROM first_season AS fs
  LEFT JOIN gyul.orders AS o
  ON fs.customer_id = o.customer_id
  WHERE
    fs.first_season = o.season
  GROUP BY
    fs.customer_id
), repurchase_customer AS (
  SELECT
    fs.customer_id,
    LOGICAL_OR(fs.first_season < o.season) AS repurchase
  FROM first_season AS fs
  LEFT JOIN gyul.orders AS o
  ON fs.customer_id = o.customer_id
  GROUP BY
    fs.customer_id
)
SELECT
  sido,
  ROUND(SAFE_DIVIDE(repurchase_cnt, customer_cnt) * 100, 2) AS repurchase_rate
FROM (
  SELECT
    fs.sido,
    COUNT(*) AS customer_cnt,
    SUM(CASE WHEN rc.repurchase = TRUE THEN 1 ELSE 0 END) AS repurchase_cnt
  FROM first_season_sido AS fs
  LEFT JOIN repurchase_customer AS rc
  ON fs.customer_id = rc.customer_id
  WHERE
    fs.sido IS NOT NULL
  GROUP BY
    fs.sido
)
ORDER BY
  repurchase_rate DESC

-- 결과: 서울(725명) 32.7%, 경기(546명) 34.1%로 이 둘이 전체의 72% 차지, 나머지 지역은 표본이 작아 참고용
-- 지역은 판매자 축만큼 뚜렷한 신호를 못 보여줌
