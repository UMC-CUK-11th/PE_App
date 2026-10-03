-- 확장. 내 ERD 요구사항
-- "로그인한 회원(member_id = 1)의 진행 중 미션을 마감 임박순으로 10개 보여 준다."
-- 결과: 가게 이름, 음식 카테고리, 미션 조건(최소 금액), 적립 포인트, 마감일
-- 기준 테이블: member_mission / JOIN: mission → store → food_category
SELECT mm.member_mission_id,
       s.name          AS store_name,
       fc.name         AS food_category,
       m.min_price,
       m.reward_point,
       m.deadline
FROM member_mission mm
         JOIN mission m ON mm.mission_id = m.mission_id
         JOIN store s ON m.store_id = s.store_id
         JOIN food_category fc ON s.food_category_id = fc.food_category_id
WHERE mm.member_id = 1
  AND mm.status = 'CHALLENGING'
ORDER BY m.deadline ASC, mm.member_mission_id ASC
LIMIT 10 OFFSET 0;
