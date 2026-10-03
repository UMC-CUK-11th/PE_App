INSERT INTO region (name) VALUES ('안양동'), ('안암동');
INSERT INTO food_category (name) VALUES ('중식'), ('한식'), ('분식');
INSERT INTO member (nickname, point) VALUES ('현', 2500), ('민서', 0);

INSERT INTO store (region_id, food_category_id, name, address)
VALUES (1, 1, '반이학생마라탕', '경기 안양시 만안구 안양동 1'),
       (1, 2, '안양 할매국밥', '경기 안양시 만안구 안양동 2'),
       (2, 3, '고대 떡볶이', '서울 성북구 안암동5가 102-80');

INSERT INTO mission (store_id, min_price, reward_point, deadline)
VALUES (1, 10000, 500, '2026-10-10 23:59:59'),
       (2, 12000, 600, '2026-10-20 23:59:59'),
       (3, 8000, 300, '2026-10-05 23:59:59'),
       (1, 15000, 800, '2026-10-31 23:59:59');

INSERT INTO member_mission (member_id, mission_id, status, created_at)
VALUES (1, 1, 'CHALLENGING', '2026-09-28 12:00:00'),
       (1, 2, 'CHALLENGING', '2026-09-30 18:00:00'),
       (1, 3, 'COMPLETE', '2026-09-20 13:00:00'),
       (2, 4, 'CHALLENGING', '2026-09-29 19:00:00');
