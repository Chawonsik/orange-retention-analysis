-- "seller_B는 재구매율이 높은데, 혹시 한 번에 더 크게 사줘서인가?" 가설 검증
-- 05번(재구매율)은 고객 단위, 이건 주문 단위 -- 재구매 빈도와 독립적인 "거래 크기" 지표
SELECT
  seller,
  COUNT(*) AS order_cnt,
  SUM(qty_10kg + qty_5kg) AS total_box,
  ROUND(SAFE_DIVIDE(SUM(qty_10kg + qty_5kg), COUNT(*)), 2) AS boxes_per_order
FROM gyul.orders
GROUP BY
  seller

-- 결과: seller_A 1.11, seller_B 1.11, seller_C 1.13 -- 셋 다 동일. 가설 기각.
-- seller_B의 우위는 거래 크기가 아니라 재방문 빈도에서 온다
