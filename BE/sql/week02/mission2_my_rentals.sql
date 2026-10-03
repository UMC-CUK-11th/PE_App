-- 미션 2. 특정 사용자(user_id = 1)가 아직 반납하지 않은 책을 반납 예정일 순으로 조회
-- 기준 테이블: rental / JOIN: book (책 제목은 book 테이블에 있음)
SELECT b.title,
       r.rented_at,
       r.due_at
FROM rental r
         JOIN book b ON r.book_id = b.book_id
WHERE r.user_id = 1
  AND r.returned_at IS NULL
ORDER BY r.due_at ASC, r.rental_id ASC;
