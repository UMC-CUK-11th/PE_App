-- 4주차 선택 미션: 도서 제목 중복 방지
-- 실행 전 중복 제목이 있는지 먼저 확인 (있으면 ALTER가 실패함)
SELECT title, COUNT(*) AS cnt
FROM book
GROUP BY title
HAVING COUNT(*) > 1;

ALTER TABLE book
    ADD CONSTRAINT uk_book_title UNIQUE (title);
